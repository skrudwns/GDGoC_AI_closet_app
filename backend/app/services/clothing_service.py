"""
의류 서비스 레이어

파이프라인 트리거 및 의류 CRUD 비즈니스 로직을 처리합니다.
파이프라인 작업 상태(task_store)를 메모리 딕셔너리로 관리합니다.
(MVP 단계 — 서버 재시작 시 상태 초기화됨)
"""
from __future__ import annotations

import uuid
import logging
from typing import Dict, Any, List, Optional

from sqlalchemy import select, delete
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.clothing import Clothing, ClothTag
from app.schemas.clothing import ClothingTagSchema, ClothingResponse, TagResponse

logger = logging.getLogger(__name__)

# ─────────────────────────────────────────────────────────────
# 인메모리 파이프라인 상태 저장소 (MVP)
# 추후 Redis 또는 DB 기반으로 교체 가능한 구조
# ─────────────────────────────────────────────────────────────
task_store: Dict[str, Dict[str, Any]] = {}


def create_task() -> str:
    """새 파이프라인 작업을 생성하고 task_id를 반환합니다."""
    task_id = uuid.uuid4().hex
    task_store[task_id] = {
        "status": "pending",
        "clothing_ids": [],
        "error": None,
    }
    return task_id


def update_task(task_id: str, status: str, clothing_ids: List[int] = None, error: str = None):
    """파이프라인 작업 상태를 업데이트합니다."""
    if task_id in task_store:
        task_store[task_id]["status"] = status
        if clothing_ids is not None:
            task_store[task_id]["clothing_ids"] = clothing_ids
        if error is not None:
            task_store[task_id]["error"] = error


def get_task(task_id: str) -> Optional[Dict[str, Any]]:
    """task_id로 작업 상태를 조회합니다."""
    return task_store.get(task_id)


class ClothingService:
    """
    의류 관련 DB 작업 서비스.
    오케스트레이터와 라우터 모두에서 사용됩니다.
    """

    def __init__(self, db: AsyncSession):
        self.db = db

    async def save_clothing(
        self,
        user_id: int,
        image_url: str,
        original_image_url: str,
        tag_schema: ClothingTagSchema,
    ) -> int:
        """
        파이프라인 결과를 DB에 저장합니다.

        1. clothes 테이블에 의류 기본 정보 INSERT
        2. cloth_tags 테이블에 다중 태그 INSERT

        Returns:
            저장된 cloth_id
        """
        # 의류 기본 정보 저장
        clothing = Clothing(
            user_id=user_id,
            image_url=image_url,
            original_image_url=original_image_url,
            category=tag_schema.category,
            sub_category=tag_schema.sub_category,
            pattern=tag_schema.pattern,
            pipeline_status="done",
        )
        self.db.add(clothing)
        await self.db.flush()  # cloth_id 확보 (commit 전)

        # 다중 값 태그 저장 (color, material, style, season)
        tag_entries: List[ClothTag] = []

        for color in tag_schema.color:
            tag_entries.append(ClothTag(cloth_id=clothing.cloth_id, tag_type="color", tag_value=color))
        for material in tag_schema.material:
            tag_entries.append(ClothTag(cloth_id=clothing.cloth_id, tag_type="material", tag_value=material))
        for style in tag_schema.style:
            tag_entries.append(ClothTag(cloth_id=clothing.cloth_id, tag_type="style", tag_value=style))
        for season in tag_schema.season:
            tag_entries.append(ClothTag(cloth_id=clothing.cloth_id, tag_type="season", tag_value=season))

        # extra 필드의 추가 태그도 저장 (모델별 확장 메타데이터)
        for key, value in tag_schema.extra.items():
            if isinstance(value, list):
                for v in value:
                    tag_entries.append(ClothTag(cloth_id=clothing.cloth_id, tag_type=key, tag_value=str(v)))
            else:
                tag_entries.append(ClothTag(cloth_id=clothing.cloth_id, tag_type=key, tag_value=str(value)))

        self.db.add_all(tag_entries)
        await self.db.commit()

        return clothing.cloth_id

    async def get_clothing_list(self, user_id: int) -> List[ClothingResponse]:
        """사용자의 전체 의류 목록을 조회합니다."""
        stmt = (
            select(Clothing)
            .where(Clothing.user_id == user_id)
            .order_by(Clothing.created_at.desc())
        )
        result = await self.db.execute(stmt)
        clothes = result.scalars().all()
        return [self._to_response(c) for c in clothes]

    async def get_clothing_detail(self, cloth_id: int, user_id: int) -> Optional[ClothingResponse]:
        """특정 의류 아이템의 상세 정보를 조회합니다."""
        stmt = select(Clothing).where(
            Clothing.cloth_id == cloth_id,
            Clothing.user_id == user_id,
        )
        result = await self.db.execute(stmt)
        clothing = result.scalar_one_or_none()
        if clothing is None:
            return None
        return self._to_response(clothing)

    async def delete_clothing(self, cloth_id: int, user_id: int) -> bool:
        """
        의류 아이템을 삭제합니다.

        Returns:
            True: 삭제 성공, False: 해당 아이템 없음
        """
        stmt = select(Clothing).where(
            Clothing.cloth_id == cloth_id,
            Clothing.user_id == user_id,
        )
        result = await self.db.execute(stmt)
        clothing = result.scalar_one_or_none()

        if clothing is None:
            return False

        await self.db.delete(clothing)
        await self.db.commit()
        return True

    @staticmethod
    def _to_response(clothing: Clothing) -> ClothingResponse:
        """ORM 모델을 응답 스키마로 변환합니다."""
        # cloth_tags에서 detection_confidence 값을 추출합니다.
        # YOLOS + CLIP 파이프라인에서 extra 필드로 저장됩니다.
        confidence: float | None = None
        for tag in clothing.tags:
            if tag.tag_type == "detection_confidence":
                try:
                    confidence = float(tag.tag_value)
                except ValueError:
                    pass
                break

        return ClothingResponse(
            cloth_id=clothing.cloth_id,
            user_id=clothing.user_id,
            image_url=clothing.image_url,
            original_image_url=clothing.original_image_url,
            category=clothing.category,
            sub_category=clothing.sub_category,
            pattern=clothing.pattern,
            pipeline_status=clothing.pipeline_status,
            confidence=confidence,
            tags=[
                TagResponse(tag_type=t.tag_type, tag_value=t.tag_value)
                for t in clothing.tags
            ],
            created_at=clothing.created_at,
        )
