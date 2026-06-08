"""
파이프라인 이미지 저장 모듈 (로컬 파일 시스템)

원본 이미지와 크롭 이미지를 로컬 스토리지에 저장하고
접근 가능한 경로(URL)를 반환합니다.
"""
from __future__ import annotations

import io
import uuid
from pathlib import Path

from PIL import Image

from app.config import settings


def _ensure_directories():
    """저장 디렉토리가 존재하지 않으면 생성"""
    settings.storage_originals_path.mkdir(parents=True, exist_ok=True)
    settings.storage_crops_path.mkdir(parents=True, exist_ok=True)


def save_original(image_bytes: bytes) -> str:
    """
    원본 이미지를 로컬 파일 시스템에 저장합니다.

    Args:
        image_bytes: 원본 이미지 바이트 (수신된 그대로)

    Returns:
        저장된 파일의 경로 문자열 (예: storage/originals/abc123.jpg)
    """
    _ensure_directories()
    file_id = uuid.uuid4().hex
    file_path = settings.storage_originals_path / f"{file_id}.jpg"

    # 원본 바이트를 그대로 저장 (전처리하지 않음)
    with open(file_path, "wb") as f:
        f.write(image_bytes)

    return str(file_path)


def save_crop(crop_image: Image.Image, cloth_index: int, parent_id: str) -> str:
    """
    크롭된 의류 이미지를 로컬 파일 시스템에 저장합니다.

    Args:
        crop_image: 탐지 결과로 크롭된 PIL Image
        cloth_index: 동일 원본 이미지에서 몇 번째 크롭인지 (0-based)
        parent_id: 원본 이미지 식별자 (파일명 구성에 활용)

    Returns:
        저장된 파일의 경로 문자열 (예: storage/crops/abc123_0.jpg)
    """
    _ensure_directories()
    file_path = settings.storage_crops_path / f"{parent_id}_{cloth_index}.jpg"

    # JPEG 저장 (품질 95, EXIF 제거)
    crop_image.save(str(file_path), format="JPEG", quality=95)

    return str(file_path)
