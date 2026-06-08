"""
파이프라인 오케스트레이터

4단계 파이프라인을 순서대로 실행하고 결과를 DB에 저장합니다.
FastAPI BackgroundTasks에서 호출됩니다.

단계:
  1. 이미지 전처리 (preprocessor)
  2. 객체 탐지 (detector) — 추상화, 교체 가능
  3. 크롭 + 태깅 (tagger) — 추상화, 교체 가능
  4. DB 저장 (clothing_service)

파이프라인 실행 중 발생하는 예외는 캐치하여 DB의 pipeline_status를 'failed'로
업데이트하고, 오류 메시지를 pipeline_error 컬럼에 기록합니다.
"""
from __future__ import annotations

import uuid
import logging
from typing import List

from sqlalchemy.ext.asyncio import AsyncSession

from app.pipeline import preprocessor, storage
from app.pipeline.detector import BaseDetector, MockDetector
from app.pipeline.tagger import BaseTagger, MockTagger
from app.pipeline.preprocessor import ImagePreprocessError
from app.config import settings
from app.schemas.clothing import BoundingBox

logger = logging.getLogger(__name__)


def _get_detector() -> BaseDetector:
    """
    config의 DETECTOR_TYPE에 따라 탐지기 구현체를 반환합니다.
    팀원이 모델 확정 후 여기에 분기를 추가합니다.
    """
    dtype = settings.detector_type.lower()
    if dtype == "mock":
        return MockDetector()
    elif dtype == "yolos":
        from app.pipeline.detector import YolosFashionpediaDetector
        return YolosFashionpediaDetector()
    else:
        logger.warning(f"알 수 없는 DETECTOR_TYPE: '{dtype}'. MockDetector를 사용합니다.")
        return MockDetector()


def _get_tagger() -> BaseTagger:
    """
    config의 TAGGER_TYPE에 따라 태거 구현체를 반환합니다.
    팀원이 모델 확정 후 여기에 분기를 추가합니다.
    """
    ttype = settings.tagger_type.lower()
    if ttype == "mock":
        return MockTagger()
    elif ttype == "clip":
        from app.pipeline.tagger import CLIPAttributeTagger
        return CLIPAttributeTagger()
    else:
        logger.warning(f"알 수 없는 TAGGER_TYPE: '{ttype}'. MockTagger를 사용합니다.")
        return MockTagger()


async def run_pipeline(
    image_bytes: bytes,
    user_id: int,
    task_id: str,
    db: AsyncSession,
) -> List[int]:
    """
    이미지 처리 파이프라인 전체를 실행합니다.
    FastAPI BackgroundTasks에서 호출됩니다.

    Args:
        image_bytes: 업로드된 이미지 바이트
        user_id: 업로드한 사용자 ID
        task_id: 파이프라인 작업 추적용 ID
        db: AsyncSession (BackgroundTask에서 별도 세션 사용)

    Returns:
        저장된 의류 아이템의 cloth_id 목록

    Raises:
        ImagePreprocessError: 전처리 실패 시
        Exception: 탐지/태깅/저장 단계 실패 시
    """
    # 순환 참조 방지를 위해 내부에서 import
    from app.services.clothing_service import ClothingService

    service = ClothingService(db)
    detector = _get_detector()
    tagger = _get_tagger()
    parent_id = uuid.uuid4().hex
    clothing_ids: List[int] = []

    logger.info(f"[{task_id}] 파이프라인 시작 — user_id={user_id}")

    # ─────────────────────────────────────────────
    # 1단계: 이미지 전처리
    # ─────────────────────────────────────────────
    logger.info(f"[{task_id}] 1단계: 이미지 전처리")
    image = preprocessor.preprocess(image_bytes)

    # 원본 이미지 저장 (전처리 전 원본 바이트 보존)
    original_path = storage.save_original(image_bytes)
    logger.info(f"[{task_id}] 원본 이미지 저장 완료: {original_path}")

    # ─────────────────────────────────────────────
    # 2단계: 객체 탐지
    # ─────────────────────────────────────────────
    logger.info(f"[{task_id}] 2단계: 객체 탐지 ({settings.detector_type})")
    raw_detection = await detector.detect(image)
    boxes = detector.parse_result(raw_detection)

    # 탐지 결과가 없으면 전체 이미지를 단일 아이템으로 fallback
    if not boxes:
        logger.warning(f"[{task_id}] 탐지 결과 없음 — 전체 이미지를 단일 아이템으로 처리")
        from app.schemas.clothing import BoundingBox
        w, h = image.size
        boxes = [BoundingBox(xmin=0, ymin=0, xmax=float(w), ymax=float(h), confidence=0.0, label="unknown")]

    logger.info(f"[{task_id}] 탐지된 의류 수: {len(boxes)}개")

    # ─────────────────────────────────────────────
    # 3단계: 크롭 + 태깅 + 저장 (박스별 반복)
    # ─────────────────────────────────────────────
    for i, box in enumerate(boxes):
        logger.info(f"[{task_id}] 3단계: 의류 #{i} 태깅 ({settings.tagger_type})")

        # 이미지 크롭 (Bounding Box 기준)
        crop = image.crop(box.as_tuple)

        # 크롭 이미지 저장
        crop_path = storage.save_crop(crop, i, parent_id)

        # 메타데이터 태깅
        raw_tags = await tagger.tag(crop)

        # YOLOS + CLIP 파이프라인의 경우:
        # BoundingBox에 담긴 label(의류 레이블)과 confidence(탐지 신뢰도)를
        # raw_tags에 주입하여 sub_category 세분화 로직이 동작하도록 합니다.
        if isinstance(raw_tags, dict) and "attrs" in raw_tags:
            raw_tags["label"] = box.label
            raw_tags["score"] = box.confidence

        tag_schema = tagger.parse_result(raw_tags)

        # ─────────────────────────────────────────────
        # 4단계: DB 저장
        # ─────────────────────────────────────────────
        cloth_id = await service.save_clothing(
            user_id=user_id,
            image_url=crop_path,
            original_image_url=original_path,
            tag_schema=tag_schema,
        )
        clothing_ids.append(cloth_id)
        logger.info(f"[{task_id}] 의류 #{i} DB 저장 완료 — cloth_id={cloth_id}")

    logger.info(f"[{task_id}] 파이프라인 완료 — cloth_ids={clothing_ids}")
    return clothing_ids
