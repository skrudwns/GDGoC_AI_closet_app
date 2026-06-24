"""
파이프라인 단위 테스트

MockDetector, MockTagger를 사용하여 파이프라인의 각 단계와
전체 흐름을 테스트합니다. 실제 DB 없이 실행 가능합니다.
"""
import io
import pytest
from PIL import Image
from unittest.mock import AsyncMock, MagicMock, patch

from app.pipeline.preprocessor import preprocess, ImagePreprocessError
from app.pipeline.detector import MockDetector
from app.pipeline.tagger import MockTagger
from app.pipeline import storage
from app.schemas.clothing import BoundingBox, ClothingTagSchema


# ─────────────────────────────────────────────
# 테스트용 더미 이미지 생성 헬퍼
# ─────────────────────────────────────────────

def make_jpeg_bytes(width: int = 200, height: int = 300) -> bytes:
    """테스트용 JPEG 이미지 바이트를 생성합니다."""
    img = Image.new("RGB", (width, height), color=(100, 150, 200))
    buf = io.BytesIO()
    img.save(buf, format="JPEG")
    return buf.getvalue()


def make_png_bytes(width: int = 200, height: int = 300) -> bytes:
    """테스트용 PNG 이미지 바이트를 생성합니다."""
    img = Image.new("RGB", (width, height), color=(200, 100, 50))
    buf = io.BytesIO()
    img.save(buf, format="PNG")
    return buf.getvalue()


# ─────────────────────────────────────────────
# 1단계: 전처리 테스트
# ─────────────────────────────────────────────

class TestPreprocessor:

    def test_jpeg_preprocessing_success(self):
        """JPEG 이미지를 정상적으로 전처리할 수 있어야 합니다."""
        image_bytes = make_jpeg_bytes()
        result = preprocess(image_bytes)
        assert result.mode == "RGB"

    def test_png_preprocessing_success(self):
        """PNG 이미지를 정상적으로 전처리할 수 있어야 합니다."""
        image_bytes = make_png_bytes()
        result = preprocess(image_bytes)
        assert result.mode == "RGB"

    def test_large_image_resized(self):
        """1024px를 초과하는 이미지는 리사이징되어야 합니다."""
        image_bytes = make_jpeg_bytes(width=2000, height=3000)
        result = preprocess(image_bytes)
        assert max(result.size) <= 1024

    def test_small_image_not_resized(self):
        """작은 이미지는 리사이징되지 않아야 합니다."""
        image_bytes = make_jpeg_bytes(width=200, height=300)
        result = preprocess(image_bytes)
        assert result.size == (200, 300)

    def test_invalid_bytes_raises_error(self):
        """유효하지 않은 바이트는 ImagePreprocessError를 발생시켜야 합니다."""
        with pytest.raises(ImagePreprocessError):
            preprocess(b"this is not an image")

    def test_rgba_converted_to_rgb(self):
        """RGBA 이미지는 RGB로 변환되어야 합니다."""
        img = Image.new("RGBA", (100, 100), color=(255, 0, 0, 128))
        buf = io.BytesIO()
        img.save(buf, format="PNG")
        result = preprocess(buf.getvalue())
        assert result.mode == "RGB"


# ─────────────────────────────────────────────
# 2단계: MockDetector 테스트
# ─────────────────────────────────────────────

class TestMockDetector:

    @pytest.mark.asyncio
    async def test_detect_returns_full_image_box(self):
        """MockDetector는 전체 이미지를 단일 BoundingBox로 반환해야 합니다."""
        detector = MockDetector()
        image = Image.new("RGB", (200, 300))
        raw = await detector.detect(image)
        boxes = detector.parse_result(raw)

        assert len(boxes) == 1
        assert boxes[0].xmin == 0.0
        assert boxes[0].ymin == 0.0
        assert boxes[0].xmax == 200.0
        assert boxes[0].ymax == 300.0
        assert boxes[0].confidence == 1.0

    def test_parse_result_returns_bounding_boxes(self):
        """parse_result는 BoundingBox 목록을 반환해야 합니다."""
        detector = MockDetector()
        raw = {
            "boxes": [
                {"xmin": 10.0, "ymin": 20.0, "xmax": 100.0, "ymax": 200.0,
                 "confidence": 0.9, "label": "upper_body"}
            ]
        }
        boxes = detector.parse_result(raw)
        assert len(boxes) == 1
        assert isinstance(boxes[0], BoundingBox)
        assert boxes[0].label == "upper_body"

    def test_bounding_box_as_tuple(self):
        """BoundingBox.as_tuple은 PIL crop()에 사용 가능한 튜플을 반환해야 합니다."""
        box = BoundingBox(xmin=10.0, ymin=20.0, xmax=100.0, ymax=200.0,
                          confidence=0.9, label="test")
        assert box.as_tuple == (10.0, 20.0, 100.0, 200.0)


# ─────────────────────────────────────────────
# 3단계: MockTagger 테스트
# ─────────────────────────────────────────────

class TestMockTagger:

    @pytest.mark.asyncio
    async def test_tag_returns_dict(self):
        """MockTagger.tag()는 dict를 반환해야 합니다."""
        tagger = MockTagger()
        image = Image.new("RGB", (100, 100))
        raw = await tagger.tag(image)
        assert isinstance(raw, dict)

    def test_parse_result_returns_schema(self):
        """parse_result()는 ClothingTagSchema를 반환해야 합니다."""
        tagger = MockTagger()
        raw = {
            "category": "상의",
            "sub_category": "티셔츠",
            "color": ["White"],
            "pattern": "무지",
            "material": ["Cotton"],
            "style": ["Casual"],
            "season": ["Summer"],
        }
        result = tagger.parse_result(raw)
        assert isinstance(result, ClothingTagSchema)
        assert result.category == "상의"
        assert "White" in result.color

    def test_parse_result_handles_missing_fields(self):
        """부분적인 태그 결과도 처리할 수 있어야 합니다."""
        tagger = MockTagger()
        raw = {"category": "하의"}  # 나머지 필드 없음
        result = tagger.parse_result(raw)
        assert result.category == "하의"
        assert result.color == []
        assert result.material == []


# ─────────────────────────────────────────────
# 스토리지 테스트
# ─────────────────────────────────────────────

class TestStorage:

    def test_save_original(self, tmp_path, monkeypatch):
        """원본 이미지를 올바른 경로에 저장해야 합니다."""
        from app import config
        monkeypatch.setattr(config.settings, "storage_base_path", str(tmp_path))

        image_bytes = make_jpeg_bytes()
        path = storage.save_original(image_bytes)

        assert path.endswith(".jpg")
        import os
        assert os.path.exists(path)

    def test_save_crop(self, tmp_path, monkeypatch):
        """크롭 이미지를 올바른 경로에 저장해야 합니다."""
        from app import config
        monkeypatch.setattr(config.settings, "storage_base_path", str(tmp_path))

        crop = Image.new("RGB", (100, 100), color=(255, 0, 0))
        path = storage.save_crop(crop, cloth_index=0, parent_id="testparent")

        assert "testparent_0" in path
        import os
        assert os.path.exists(path)
