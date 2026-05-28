"""
PostgreSQL 데이터베이스 연결 및 세션 관리 (SQLAlchemy Async)
"""
from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine, async_sessionmaker
from sqlalchemy.orm import DeclarativeBase

from app.config import settings


# --- Async Engine ---
engine = create_async_engine(
    settings.database_url,
    echo=(settings.app_env == "development"),  # 개발 환경에서 SQL 로그 출력
    pool_pre_ping=True,
)

# --- Session Factory ---
AsyncSessionLocal = async_sessionmaker(
    bind=engine,
    class_=AsyncSession,
    expire_on_commit=False,
    autocommit=False,
    autoflush=False,
)


# --- Base Model ---
class Base(DeclarativeBase):
    pass


# --- FastAPI Dependency ---
async def get_db() -> AsyncSession:
    """
    FastAPI 의존성 주입용 DB 세션 제공자.
    요청 처리 완료 후 자동으로 세션을 닫습니다.
    """
    async with AsyncSessionLocal() as session:
        try:
            yield session
            await session.commit()
        except Exception:
            await session.rollback()
            raise


async def create_tables():
    """
    애플리케이션 시작 시 DB 테이블 생성 (개발/MVP 용).
    운영 환경에서는 Alembic 마이그레이션으로 관리합니다.
    """
    # 모든 모델을 import하여 Base.metadata에 등록
    import app.models.clothing  # noqa: F401
    import app.models.outfit    # noqa: F401

    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
