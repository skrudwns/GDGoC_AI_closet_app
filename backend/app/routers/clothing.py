"""
API 라우터 — 의류 (/clothing)

엔드포인트:
  POST /clothing/upload    — 이미지 업로드 + 파이프라인 실행 (HTTP 202)
  GET  /clothing/          — 의류 목록 조회
  GET  /clothing/{id}      — 의류 상세 조회
  DELETE /clothing/{id}    — 의류 삭제
"""
from __future__ import annotations

import logging
from typing import Annotated

from fastapi import APIRouter, BackgroundTasks, Depends, File, Form, HTTPException, UploadFile, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.schemas.clothing import ClothingListResponse, ClothingResponse
from app.schemas.pipeline import UploadResponse
from app.services.clothing_service import ClothingService, create_task, update_task
from app.pipeline import orchestrator

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/clothing", tags=["clothing"])

# 허용 이미지 MIME 타입
ALLOWED_CONTENT_TYPES = {"image/jpeg", "image/png", "image/webp"}
# 최대 업로드 크기 (10MB)
MAX_FILE_SIZE = 10 * 1024 * 1024


@router.post(
    "/upload",
    status_code=status.HTTP_202_ACCEPTED,
    response_model=UploadResponse,
    summary="의류 이미지 업로드",
    description="이미지를 업로드하면 즉시 task_id를 반환하고, 백그라운드에서 파이프라인을 실행",
)
async def upload_clothing(
    background_tasks: BackgroundTasks,
    db: Annotated[AsyncSession, Depends(get_db)],
    file: UploadFile = File(..., description="업로드할 의류 이미지 (JPEG/PNG/WEBP)"),
    user_id: int = Form(..., description="사용자 ID"),
):
    # 파일 형식 검증
    if file.content_type not in ALLOWED_CONTENT_TYPES:
        raise HTTPException(
            status_code=status.HTTP_415_UNSUPPORTED_MEDIA_TYPE,
            detail=f"지원하지 않는 이미지 형식입니다: {file.content_type}",
        )

    # 파일 크기 검증
    image_bytes = await file.read()
    if len(image_bytes) > MAX_FILE_SIZE:
        raise HTTPException(
            status_code=status.HTTP_413_REQUEST_ENTITY_TOO_LARGE,
            detail=f"파일 크기가 제한을 초과합니다 (최대 10MB).",
        )

    # 파이프라인 작업 ID 생성
    task_id = create_task()

    # BackgroundTask 등록 (즉시 반환 후 백그라운드 실행)
    background_tasks.add_task(
        _run_pipeline_task,
        image_bytes=image_bytes,
        user_id=user_id,
        task_id=task_id,
    )

    logger.info(f"업로드 완료 — task_id={task_id}, user_id={user_id}, size={len(image_bytes)}bytes")

    return UploadResponse(task_id=task_id)


async def _run_pipeline_task(image_bytes: bytes, user_id: int, task_id: str):
    """
    BackgroundTask로 실행되는 파이프라인 래퍼.
    작업 상태를 task_store에 업데이트합니다.
    BackgroundTask는 request 종료 후 별도 실행되므로 독립 DB 세션을 생성합니다.
    """
    from app.database import AsyncSessionLocal

    update_task(task_id, "processing")

    try:
        async with AsyncSessionLocal() as db:
            clothing_ids = await orchestrator.run_pipeline(
                image_bytes=image_bytes,
                user_id=user_id,
                task_id=task_id,
                db=db,
            )
        update_task(task_id, "done", clothing_ids=clothing_ids)
        logger.info(f"[{task_id}] 파이프라인 완료 — clothing_ids={clothing_ids}")

    except Exception as e:
        error_msg = str(e)
        update_task(task_id, "failed", error=error_msg)
        logger.error(f"[{task_id}] 파이프라인 실패: {error_msg}", exc_info=True)


@router.get(
    "/",
    response_model=ClothingListResponse,
    summary="의류 목록 조회",
)
async def get_clothing_list(
    user_id: int,
    db: Annotated[AsyncSession, Depends(get_db)],
):
    service = ClothingService(db)
    items = await service.get_clothing_list(user_id=user_id)
    return ClothingListResponse(total=len(items), items=items)


@router.get(
    "/{cloth_id}",
    response_model=ClothingResponse,
    summary="의류 상세 조회",
)
async def get_clothing_detail(
    cloth_id: int,
    user_id: int,
    db: Annotated[AsyncSession, Depends(get_db)],
):
    service = ClothingService(db)
    item = await service.get_clothing_detail(cloth_id=cloth_id, user_id=user_id)
    if item is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="의류 아이템을 찾을 수 없습니다.")
    return item


@router.delete(
    "/{cloth_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="의류 삭제",
)
async def delete_clothing(
    cloth_id: int,
    user_id: int,
    db: Annotated[AsyncSession, Depends(get_db)],
):
    service = ClothingService(db)
    deleted = await service.delete_clothing(cloth_id=cloth_id, user_id=user_id)
    if not deleted:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="의류 아이템을 찾을 수 없습니다.")
