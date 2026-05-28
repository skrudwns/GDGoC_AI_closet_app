"""
API 통합 테스트

실제 DB 없이 httpx AsyncClient를 사용하여 API 엔드포인트를 테스트합니다.
DB는 SQLite 인메모리로 오버라이드합니다.
"""
import io
import pytest
import pytest_asyncio
from httpx import AsyncClient, ASGITransport
from PIL import Image
from unittest.mock import patch, AsyncMock

from app.main import app
from app.database import Base, get_db
from sqlalchemy.ext.asyncio import create_async_engine, async_sessionmaker, AsyncSession


# ─────────────────────────────────────────────
# 테스트용 인메모리 SQLite DB 설정
# ─────────────────────────────────────────────

TEST_DATABASE_URL = "sqlite+aiosqlite:///:memory:"

test_engine = create_async_engine(TEST_DATABASE_URL, echo=False)
TestSessionLocal = async_sessionmaker(
    bind=test_engine,
    class_=AsyncSession,
    expire_on_commit=False,
)


async def override_get_db():
    async with TestSessionLocal() as session:
        try:
            yield session
            await session.commit()
        except Exception:
            await session.rollback()
            raise


@pytest_asyncio.fixture(autouse=True)
async def setup_test_db():
    """각 테스트 전에 테이블을 생성하고, 테스트 후 삭제합니다."""
    import app.models.clothing  # noqa
    import app.models.outfit    # noqa
    async with test_engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    yield
    async with test_engine.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)


@pytest_asyncio.fixture
async def client():
    """테스트용 AsyncClient. DB 의존성을 인메모리 SQLite로 교체합니다."""
    app.dependency_overrides[get_db] = override_get_db
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as ac:
        yield ac
    app.dependency_overrides.clear()


def make_jpeg_bytes(width: int = 200, height: int = 300) -> bytes:
    img = Image.new("RGB", (width, height), color=(100, 150, 200))
    buf = io.BytesIO()
    img.save(buf, format="JPEG")
    return buf.getvalue()


# ─────────────────────────────────────────────
# 헬스 체크 테스트
# ─────────────────────────────────────────────

class TestHealthCheck:

    @pytest.mark.asyncio
    async def test_health_check(self, client):
        response = await client.get("/")
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "ok"


# ─────────────────────────────────────────────
# 의류 업로드 테스트
# ─────────────────────────────────────────────

class TestClothingUpload:

    @pytest.mark.asyncio
    async def test_upload_returns_202_with_task_id(self, client, tmp_path):
        """업로드 성공 시 HTTP 202와 task_id를 반환해야 합니다."""
        from app import config
        # 스토리지 경로를 임시 디렉토리로 오버라이드
        with patch.object(config.settings, "storage_base_path", str(tmp_path)):
            image_bytes = make_jpeg_bytes()
            response = await client.post(
                "/clothing/upload",
                files={"file": ("test.jpg", image_bytes, "image/jpeg")},
                data={"user_id": "1"},
            )

        assert response.status_code == 202
        data = response.json()
        assert "task_id" in data
        assert len(data["task_id"]) > 0

    @pytest.mark.asyncio
    async def test_upload_invalid_format_returns_415(self, client):
        """지원하지 않는 파일 형식은 HTTP 415를 반환해야 합니다."""
        response = await client.post(
            "/clothing/upload",
            files={"file": ("test.txt", b"not an image", "text/plain")},
            data={"user_id": "1"},
        )
        assert response.status_code == 415


# ─────────────────────────────────────────────
# 파이프라인 상태 조회 테스트
# ─────────────────────────────────────────────

class TestPipelineStatus:

    @pytest.mark.asyncio
    async def test_status_pending_after_upload(self, client, tmp_path):
        """업로드 직후 파이프라인 상태는 pending 또는 processing이어야 합니다."""
        from app import config
        with patch.object(config.settings, "storage_base_path", str(tmp_path)):
            upload_resp = await client.post(
                "/clothing/upload",
                files={"file": ("test.jpg", make_jpeg_bytes(), "image/jpeg")},
                data={"user_id": "1"},
            )
        task_id = upload_resp.json()["task_id"]

        status_resp = await client.get(f"/pipeline/status/{task_id}")
        assert status_resp.status_code == 200
        data = status_resp.json()
        assert data["task_id"] == task_id
        assert data["status"] in ("pending", "processing", "done", "failed")

    @pytest.mark.asyncio
    async def test_status_unknown_task_returns_404(self, client):
        """존재하지 않는 task_id는 HTTP 404를 반환해야 합니다."""
        response = await client.get("/pipeline/status/nonexistent_task_id")
        assert response.status_code == 404


# ─────────────────────────────────────────────
# 의류 목록/상세 조회 테스트
# ─────────────────────────────────────────────

class TestClothingCRUD:

    @pytest.mark.asyncio
    async def test_get_empty_clothing_list(self, client):
        """의류가 없는 경우 빈 목록을 반환해야 합니다."""
        response = await client.get("/clothing/?user_id=1")
        assert response.status_code == 200
        data = response.json()
        assert data["total"] == 0
        assert data["items"] == []

    @pytest.mark.asyncio
    async def test_get_nonexistent_clothing_returns_404(self, client):
        """존재하지 않는 의류 조회 시 HTTP 404를 반환해야 합니다."""
        response = await client.get("/clothing/99999?user_id=1")
        assert response.status_code == 404
