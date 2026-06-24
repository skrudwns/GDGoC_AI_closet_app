"""
파이프라인 1단계: 이미지 전처리 (최소화)

수행 작업:
  1. 이미지 형식 유효성 검증 (JPEG / PNG / WEBP)
  2. EXIF orientation 보정 (카메라 회전 정보 반영)
  3. RGB 변환 (RGBA, Grayscale 등 처리)
  4. 최대 크기 리사이징 (비율 유지, 기본 1024px)

배경 제거(rembg)는 미포함 — 객체 탐지 모델에 위임.
"""
import io
from PIL import Image, ImageOps, UnidentifiedImageError

from app.config import settings


# 허용 이미지 형식
ALLOWED_FORMATS = {"JPEG", "PNG", "WEBP"}
# 최대 픽셀 크기 (긴 변 기준)
MAX_IMAGE_SIZE = 1024


class ImagePreprocessError(Exception):
    """이미지 전처리 중 발생하는 예외"""
    pass


def preprocess(image_bytes: bytes) -> Image.Image:
    """
    원시 이미지 바이트를 수신하여 전처리된 PIL Image를 반환합니다.

    Args:
        image_bytes: Flutter 앱에서 수신한 원시 이미지 바이트

    Returns:
        전처리된 PIL Image (RGB 모드)

    Raises:
        ImagePreprocessError: 지원하지 않는 형식이거나 손상된 이미지
    """
    # 1. 이미지 로드 및 형식 검증
    try:
        image = Image.open(io.BytesIO(image_bytes))
    except UnidentifiedImageError:
        raise ImagePreprocessError("지원하지 않는 이미지 형식이거나 손상된 파일입니다.")

    if image.format not in ALLOWED_FORMATS:
        raise ImagePreprocessError(
            f"허용되지 않는 이미지 형식입니다: {image.format}. "
            f"허용 형식: {', '.join(ALLOWED_FORMATS)}"
        )

    # 2. EXIF orientation 보정 (스마트폰 촬영 이미지의 회전 문제 해결)
    image = ImageOps.exif_transpose(image)

    # 3. RGB 변환
    if image.mode != "RGB":
        image = image.convert("RGB")

    # 4. 최대 크기 리사이징 (긴 변이 MAX_IMAGE_SIZE를 초과하는 경우에만)
    if max(image.size) > MAX_IMAGE_SIZE:
        image.thumbnail((MAX_IMAGE_SIZE, MAX_IMAGE_SIZE), Image.LANCZOS)

    return image
