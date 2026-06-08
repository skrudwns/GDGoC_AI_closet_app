"""
Pydantic 스키마 — 파이프라인 작업 상태
"""
from __future__ import annotations

from typing import List, Optional
from pydantic import BaseModel


class UploadResponse(BaseModel):
    """
    이미지 업로드 즉시 응답 (HTTP 202).
    Flutter 앱은 task_id를 이용해 파이프라인 상태를 폴링합니다.
    """
    task_id: str
    message: str = "이미지가 업로드되었습니다. 파이프라인 처리 중입니다."
    status: str = "pending"


class PipelineStatusResponse(BaseModel):
    """
    파이프라인 작업 상태 조회 응답.
    status 값: pending | processing | done | failed
    """
    task_id: str
    status: str
    clothing_ids: List[int] = []
    error: Optional[str] = None
    message: str = ""
