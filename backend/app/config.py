"""
앱 환경 설정 (Pydantic Settings)
.env 파일 또는 환경 변수에서 설정값을 읽어옵니다.
"""
from pydantic_settings import BaseSettings, SettingsConfigDict
from pathlib import Path


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
    )

    # --- Database ---
    database_url: str = "postgresql+asyncpg://postgres:password@localhost:5432/aicloset"

    # --- Storage ---
    storage_base_path: str = "./storage"

    @property
    def storage_originals_path(self) -> Path:
        return Path(self.storage_base_path) / "originals"

    @property
    def storage_crops_path(self) -> Path:
        return Path(self.storage_base_path) / "crops"

    # --- Pipeline 모델 선택 ---
    # mock: 더미 데이터 반환 (빠른 개발/테스트용)
    # yolos: valentinafeve/yolos-fashionpedia 실모델 탐지
    # clip: openai/clip-vit-base-patch32 실모델 속성 분류
    detector_type: str = "yolos"   # mock | yolos
    tagger_type: str = "clip"      # mock | clip

    # --- App ---
    app_env: str = "development"
    app_host: str = "0.0.0.0"
    app_port: int = 8000

    # --- Weather ---
    openweathermap_api_key: str = ""


# 싱글턴 인스턴스
settings = Settings()
