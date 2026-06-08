"""
API 라우터 — 파이프라인 상태 (/pipeline)

Flutter 앱이 업로드 후 폴링하여 파이프라인 처리 완료 여부를 확인합니다.
"""
from fastapi import APIRouter, HTTPException, status

from app.schemas.pipeline import PipelineStatusResponse
from app.services.clothing_service import get_task

router = APIRouter(prefix="/pipeline", tags=["pipeline"])


@router.get(
    "/status/{task_id}",
    response_model=PipelineStatusResponse,
    summary="파이프라인 작업 상태 조회",
    description=(
        "task_id로 파이프라인 처리 상태를 조회합니다. "
        "status가 'done'이면 clothing_ids에 저장된 의류 ID 목록 반환"
    ),
)
async def get_pipeline_status(task_id: str):
    task = get_task(task_id)

    if task is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"task_id '{task_id}'에 해당하는 작업을 찾을 수 없습니다.",
        )

    status_messages = {
        "pending": "파이프라인 대기 중입니다.",
        "processing": "이미지를 처리 중입니다...",
        "done": "처리가 완료되었습니다.",
        "failed": f"처리 중 오류가 발생했습니다: {task.get('error', '')}",
    }

    return PipelineStatusResponse(
        task_id=task_id,
        status=task["status"],
        clothing_ids=task.get("clothing_ids", []),
        error=task.get("error"),
        message=status_messages.get(task["status"], ""),
    )
