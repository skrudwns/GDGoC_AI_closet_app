"""
Pydantic 스키마 — 의류 (Clothing)

요청/응답 스키마와 파이프라인 내부에서 사용하는 태깅 스키마를 정의합니다.
"""
from __future__ import annotations

from datetime import datetime
from typing import Any, List, Optional
from pydantic import BaseModel, Field


# ============================================================
# 내부 표준 스키마 (파이프라인 → DB 저장용)
# ============================================================

class BoundingBox(BaseModel):
    """
    객체 탐지 결과의 단일 Bounding Box.
    Detector.parse_result()가 반환하는 내부 표준 형식입니다.
    """
    xmin: float = Field(..., ge=0, description="좌측 x 좌표 (픽셀)")
    ymin: float = Field(..., ge=0, description="상단 y 좌표 (픽셀)")
    xmax: float = Field(..., ge=0, description="우측 x 좌표 (픽셀)")
    ymax: float = Field(..., ge=0, description="하단 y 좌표 (픽셀)")
    confidence: float = Field(..., ge=0.0, le=1.0, description="탐지 신뢰도 (0~1)")
    label: str = Field(..., description="탐지된 의류 레이블 (예: 'upper_body', 'lower_body')")

    @property
    def as_tuple(self) -> tuple[float, float, float, float]:
        """PIL Image.crop()에 사용 가능한 형식으로 반환"""
        return (self.xmin, self.ymin, self.xmax, self.ymax)


class ClothingTagSchema(BaseModel):
    """
    의류 메타데이터 태그 스키마.
    Tagger.parse_result()가 반환하는 내부 표준 형식이자 DB 저장 기준입니다.

    모델 미확정 단계에서 모든 필드는 Optional로 정의하며,
    모델이 확정되면 필수 필드를 조정할 수 있습니다.
    """
    category: Optional[str] = Field(None, description="대분류 (상의, 하의, 아우터, 원피스, 신발 등)")
    sub_category: Optional[str] = Field(None, description="소분류 (셔츠, 후드티, 슬랙스, 패딩 등)")
    color: List[str] = Field(default_factory=list, description="색상 목록 (예: ['Black', 'Navy'])")
    pattern: Optional[str] = Field(None, description="패턴 (무지, 스트라이프, 체크, 플로럴 등)")
    material: List[str] = Field(default_factory=list, description="소재 목록 (예: ['Cotton', 'Denim'])")
    style: List[str] = Field(default_factory=list, description="스타일 목록 (예: ['Casual', 'Street'])")
    season: List[str] = Field(default_factory=list, description="계절 목록 (예: ['Spring', 'Autumn'])")

    # 모델이 추가 정보를 반환할 경우를 대비한 확장 필드
    extra: dict[str, Any] = Field(
        default_factory=dict,
        description="모델별 추가 메타데이터 (표준 필드에 포함되지 않는 정보)"
    )


# ============================================================
# API 응답 스키마
# ============================================================

class TagResponse(BaseModel):
    """단일 태그 항목 응답"""
    tag_type: str
    tag_value: str


class ClothingResponse(BaseModel):
    """의류 상세 조회 응답"""
    cloth_id: int
    user_id: int
    image_url: str
    original_image_url: Optional[str] = None
    category: Optional[str] = None
    sub_category: Optional[str] = None
    pattern: Optional[str] = None
    pipeline_status: str
    confidence: Optional[float] = None   # YOLOS 탐지 신뢰도 (0~1), Flutter UI 'AI xx%' 배지용
    tags: List[TagResponse] = []
    created_at: datetime

    model_config = {"from_attributes": True}


class ClothingUpdate(BaseModel):
    """의류 정보 수정 요청 스키마 (PATCH — 모든 필드 선택)"""
    category: Optional[str] = None
    sub_category: Optional[str] = None
    pattern: Optional[str] = None


class ClothingListResponse(BaseModel):
    """의류 목록 조회 응답"""
    total: int
    items: List[ClothingResponse]
