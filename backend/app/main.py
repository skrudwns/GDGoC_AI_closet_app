"""
FastAPI 애플리케이션 진입점

서버 시작 시 DB 테이블을 생성하고, 라우터를 등록합니다.
"""
import logging

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from contextlib import asynccontextmanager

from app.config import settings
from app.database import create_tables
from app.routers import clothing, pipeline, weather

# 로깅 설정
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
)
logger = logging.getLogger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI):
    """앱 시작/종료 시 실행되는 라이프사이클 핸들러"""
    # 시작 시: 스토리지 디렉토리 및 DB 테이블 생성
    logger.info("서버 시작 — 스토리지 디렉토리 및 DB 테이블 초기화 중...")
    settings.storage_originals_path.mkdir(parents=True, exist_ok=True)
    settings.storage_crops_path.mkdir(parents=True, exist_ok=True)
    await create_tables()
    logger.info("초기화 완료.")
    yield
    # 종료 시: 필요한 정리 작업 (현재는 없음)
    logger.info("서버 종료.")


app = FastAPI(
    title="AI 옷장 백엔드 API",
    description=(
        "Flutter 앱에서 의류 이미지를 수신하여 객체 탐지, 메타데이터 태깅, "
        "DB 저장까지 처리하는 파이프라인 API"
    ),
    version="0.1.0",
    lifespan=lifespan,
)

# CORS 설정 (Flutter 앱 연동)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],   # 개발 중 전체 허용, 운영 시 도메인 지정
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# 로컬 이미지 파일을 정적 파일로 서빙 (Flutter 앱에서 이미지 URL 접근)
app.mount(
    "/storage",
    StaticFiles(directory=settings.storage_base_path),
    name="storage",
)

# 라우터 등록
app.include_router(clothing.router)
app.include_router(pipeline.router)
app.include_router(weather.router)


@app.get("/", tags=["health"])
async def health_check():
    """서버 상태 확인"""
    return {
        "status": "ok",
        "app": "AI 옷장 백엔드",
        "version": "0.1.0",
        "detector": settings.detector_type,
        "tagger": settings.tagger_type,
    }
