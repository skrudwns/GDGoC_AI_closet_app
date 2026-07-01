import logging
import httpx
from fastapi import APIRouter, HTTPException, status
from pydantic import BaseModel

from app.config import settings

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/weather", tags=["weather"])


class WeatherResponse(BaseModel):
    """날씨 정보 응답 스키마"""
    temp: float
    feels_like: float
    description: str
    main: str
    humidity: int
    is_mock: bool


@router.get("", response_model=WeatherResponse, summary="현재 날씨 정보 조회")
async def get_current_weather(lat: float = 37.5665, lon: float = 126.9780):
    """
    위도와 경도를 기반으로 현재 날씨 정보를 조회합니다.
    API 키가 등록되어 있지 않은 경우 더미 날씨 데이터를 반환합니다 (테스트용).
    """
    # API 키 검증 (등록되지 않은 경우 Mock 데이터 반환)
    api_key = settings.openweathermap_api_key.strip()
    if not api_key or api_key == "your_openweathermap_api_key":
        logger.warning("OpenWeatherMap API Key가 설정되지 않았습니다. 테스트용 Mock 데이터를 반환합니다.")
        return WeatherResponse(
            temp=22.5,
            feels_like=23.0,
            description="맑음 (Mock)",
            main="Clear",
            humidity=55,
            is_mock=True,
        )

    url = "https://api.openweathermap.org/data/2.5/weather"
    params = {
        "lat": lat,
        "lon": lon,
        "appid": api_key,
        "units": "metric",  # 섭씨 온도
        "lang": "kr",       # 한국어 설명
    }

    async with httpx.AsyncClient() as client:
        try:
            response = await client.get(url, params=params, timeout=5.0)
            if response.status_code != 200:
                logger.error(f"OpenWeatherMap API 오류 ({response.status_code}): {response.text}")
                # API 호출 오류 시 테스트가 중단되지 않도록 Mock 데이터를 반환하는 Fallback 수행
                return WeatherResponse(
                    temp=22.5,
                    feels_like=23.0,
                    description="맑음 (Fallback)",
                    main="Clear",
                    humidity=55,
                    is_mock=True,
                )

            data = response.json()
            return WeatherResponse(
                temp=data["main"]["temp"],
                feels_like=data["main"]["feels_like"],
                description=data["weather"][0]["description"],
                main=data["weather"][0]["main"],
                humidity=data["main"]["humidity"],
                is_mock=False,
            )
        except Exception as e:
            logger.error(f"Weather API 연동 중 오류 발생: {str(e)}", exc_info=True)
            return WeatherResponse(
                temp=22.5,
                feels_like=23.0,
                description="맑음 (Error Fallback)",
                main="Clear",
                humidity=55,
                is_mock=True,
            )
