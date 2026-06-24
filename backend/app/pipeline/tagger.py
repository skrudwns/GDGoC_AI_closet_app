"""
파이프라인 3단계: 메타데이터 태깅 (추상화 + Mock 구현체)

설계 원칙:
  - BaseTagger: 추상 인터페이스. tag()와 parse_result()를 분리하여
    VLM, 전용 모델 등 다양한 모델의 출력 형태 차이를 수용합니다.
  - tag(): 크롭 이미지를 받아 모델의 원시 결과를 반환 (형태 자유)
  - parse_result(): 원시 결과를 내부 표준 ClothingTagSchema로 변환

ClothingTagSchema의 extra 필드를 통해 모델별 추가 정보도 보존할 수 있습니다.
"""
from __future__ import annotations

from abc import ABC, abstractmethod
from typing import Any

from PIL import Image

from app.schemas.clothing import ClothingTagSchema


class BaseTagger(ABC):
    """
    의류 메타데이터 태깅 추상 인터페이스.

    구현 시 주의:
      - tag()는 모델의 원시 출력을 그대로 반환합니다.
        (VLM JSON 응답, 분류 모델 확률 벡터 등 모델마다 형태가 다름)
      - parse_result()에서 원시 출력을 ClothingTagSchema로 변환합니다.
      - ClothingTagSchema의 필드가 일부만 채워져도 허용됩니다 (모두 Optional).
      - 모델이 인식하지 못한 추가 정보는 extra 필드에 저장하세요.
    """

    @abstractmethod
    async def tag(self, image: Image.Image) -> Any:
        """
        크롭된 의류 이미지에서 메타데이터를 추출하고 모델의 원시 결과를 반환합니다.

        Args:
            image: 탐지 단계에서 크롭된 단일 의류 PIL Image

        Returns:
            모델별 원시 결과 (형태 자유 — JSON dict, tensor, str 등)
        """
        ...

    @abstractmethod
    def parse_result(self, raw: Any) -> ClothingTagSchema:
        """
        모델의 원시 결과를 내부 표준 ClothingTagSchema로 변환합니다.

        Args:
            raw: tag()가 반환한 원시 결과

        Returns:
            ClothingTagSchema (채워지지 않은 필드는 None 또는 빈 리스트)
        """
        ...


class MockTagger(BaseTagger):
    """
    모델 미확정 시 사용하는 Mock 구현체.
    파이프라인 전체 흐름 검증 및 DB 저장 테스트 목적으로 더미 태그를 반환합니다.
    """

    async def tag(self, image: Image.Image) -> dict:
        """
        Mock: 고정 더미 메타데이터를 반환.
        실제 모델 연동 시 이 메서드를 교체합니다.
        """
        return {
            "category": "상의",
            "sub_category": "후드티",
            "color": ["Black"],
            "pattern": "무지",
            "material": ["Cotton"],
            "style": ["Casual"],
            "season": ["Spring", "Autumn"],
        }

    def parse_result(self, raw: dict) -> ClothingTagSchema:
        """Mock 원시 결과를 ClothingTagSchema로 변환"""
        return ClothingTagSchema(
            category=raw.get("category"),
            sub_category=raw.get("sub_category"),
            color=raw.get("color", []),
            pattern=raw.get("pattern"),
            material=raw.get("material", []),
            style=raw.get("style", []),
            season=raw.get("season", []),
        )


class CLIPAttributeTagger(BaseTagger):
    """
    CLIP(openai/clip-vit-base-patch32) 모델을 사용하는 실제 의류 속성 태거.

    YolosCLIPPipeline 싱글턴을 통해 CLIP 모델을 사용합니다.
    tag()의 raw 결과에는 YOLOS 탐지 정보(label, score)가 포함되어야
    sub_category 세분화 로직이 올바르게 동작합니다.

    orchestrator에서 config.tagger_type == "clip" 일 때 선택됩니다.
    """

    def __init__(self) -> None:
        from app.pipeline.yolos_pipeline import YolosCLIPPipeline
        self._pipeline = YolosCLIPPipeline.get_instance()

    async def tag(self, image: Image.Image) -> dict:
        """
        CLIP으로 크롭된 의류 이미지의 세부 속성을 분류합니다.

        Args:
            image: YOLOS로 크롭된 단일 의류 PIL Image

        Returns:
            {"attrs": {카테고리: [(속성, 확률), ...]}, "label": str, "score": float}
            ※ label과 score는 orchestrator가 BoundingBox에서 주입합니다.
        """
        import asyncio
        attrs = await asyncio.to_thread(self._pipeline.classify_attributes, image)
        return {"attrs": attrs, "label": None, "score": 1.0}

    def parse_result(self, raw: dict) -> ClothingTagSchema:
        """
        CLIP 속성 결과를 ClothingTagSchema로 변환합니다.

        raw 딕셔너리의 "label"과 "score" 필드를 사용하여
        YOLOS 카테고리 매핑 및 소분류 세분화를 수행합니다.
        """
        return self._pipeline.build_tag_schema(
            original_label=raw.get("label") or "top, t-shirt, sweatshirt",
            raw_attrs=raw.get("attrs", {}),
            detection_score=raw.get("score", 1.0),
        )


# ============================================================
# 추후 구현 예시 (팀원 모델 확정 후 추가)
# ============================================================
#
# class OpenAIVLMTagger(BaseTagger):
#     """GPT-4o-mini 기반 의류 태깅"""
#
#     def __init__(self, api_key: str, model: str = "gpt-4o-mini"):
#         import openai
#         self.client = openai.AsyncOpenAI(api_key=api_key)
#         self.model = model
#
#     async def tag(self, image: Image.Image) -> dict:
#         import base64, io
#         buffer = io.BytesIO()
#         image.save(buffer, format="JPEG")
#         b64 = base64.b64encode(buffer.getvalue()).decode()
#
#         response = await self.client.beta.chat.completions.parse(
#             model=self.model,
#             messages=[
#                 {"role": "system", "content": "당신은 의류 전문가입니다. 주어진 의류 이미지의 메타데이터를 JSON으로 추출하세요."},
#                 {"role": "user", "content": [{"type": "image_url", "image_url": {"url": f"data:image/jpeg;base64,{b64}"}}]},
#             ],
#             response_format=ClothingTagSchema,
#         )
#         return response.choices[0].message.parsed.model_dump()
#
#     def parse_result(self, raw: dict) -> ClothingTagSchema:
#         return ClothingTagSchema(**raw)
