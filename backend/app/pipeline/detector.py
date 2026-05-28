"""
파이프라인 2단계: 객체 탐지 (추상화 + Mock 구현체)

설계 원칙:
  - BaseDetector: 추상 인터페이스. detect()와 parse_result()를 분리하여
    모델별 원시 출력 형태가 달라져도 파이프라인 코드 변경 없이 교체 가능.
  - detect(): 모델을 실행하여 원시(raw) 결과를 반환 (형태 자유)
  - parse_result(): 원시 결과를 내부 표준 BoundingBox 목록으로 변환

팀원이 모델 확정 후 새 구현체를 추가하고 config.py의 DETECTOR_TYPE만 변경하면 됩니다.
"""
from __future__ import annotations

from abc import ABC, abstractmethod
from typing import Any, List

from PIL import Image

from app.schemas.clothing import BoundingBox


class BaseDetector(ABC):
    """
    의류 객체 탐지 추상 인터페이스.

    구현 시 주의:
      - detect()는 모델의 원시 출력을 그대로 반환합니다.
        (YOLO tensor, dict, list 등 모델마다 형태가 다름)
      - parse_result()에서 원시 출력을 BoundingBox 목록으로 변환합니다.
      - 탐지 결과가 없으면 전체 이미지를 단일 박스로 처리하는 fallback을
        orchestrator에서 처리합니다.
    """

    @abstractmethod
    async def detect(self, image: Image.Image) -> Any:
        """
        이미지에서 의류 객체를 탐지하고 모델의 원시 결과를 반환합니다.

        Args:
            image: 전처리된 PIL Image (RGB 모드)

        Returns:
            모델별 원시 결과 (형태 자유 — YOLO results, dict, tensor 등)
        """
        ...

    @abstractmethod
    def parse_result(self, raw: Any) -> List[BoundingBox]:
        """
        모델의 원시 결과를 내부 표준 BoundingBox 목록으로 변환합니다.

        Args:
            raw: detect()가 반환한 원시 결과

        Returns:
            BoundingBox 목록 (없으면 빈 리스트)
        """
        ...


class MockDetector(BaseDetector):
    """
    모델 미확정 시 사용하는 Mock 구현체.
    전체 이미지를 단일 의류 아이템으로 간주하여 하나의 BoundingBox를 반환합니다.
    """

    async def detect(self, image: Image.Image) -> dict:
        """
        Mock: 이미지 전체를 단일 BoundingBox로 반환.
        실제 모델 연동 시 이 메서드를 교체합니다.
        """
        w, h = image.size
        return {
            "boxes": [
                {
                    "xmin": 0.0,
                    "ymin": 0.0,
                    "xmax": float(w),
                    "ymax": float(h),
                    "confidence": 1.0,
                    "label": "clothing",
                }
            ]
        }

    def parse_result(self, raw: dict) -> List[BoundingBox]:
        """Mock 원시 결과를 BoundingBox 목록으로 변환"""
        return [
            BoundingBox(
                xmin=box["xmin"],
                ymin=box["ymin"],
                xmax=box["xmax"],
                ymax=box["ymax"],
                confidence=box["confidence"],
                label=box["label"],
            )
            for box in raw.get("boxes", [])
        ]


class YolosFashionpediaDetector(BaseDetector):
    """
    valentinafeve/yolos-fashionpedia 모델을 사용하는 실제 의류 탐지기.

    YolosCLIPPipeline 싱글턴을 통해 모델을 사용합니다.
    orchestrator에서 config.detector_type == "yolos" 일 때 선택됩니다.
    """

    def __init__(self) -> None:
        # 싱글턴을 통해 모델 로드 (최초 1회만 다운로드/로드)
        from app.pipeline.yolos_pipeline import YolosCLIPPipeline
        self._pipeline = YolosCLIPPipeline.get_instance()

    async def detect(self, image: Image.Image) -> list:
        """
        YOLOS 모델로 의류 탐지.

        Args:
            image: 전처리된 PIL Image (RGB 모드)

        Returns:
            YOLOS 탐지 결과 목록 (유효한 패션 카테고리만 필터링됨)
        """
        import asyncio
        # YOLOS 추론은 동기 함수이므로 별도 스레드에서 실행
        return await asyncio.to_thread(self._pipeline.detect_clothing, image)

    def parse_result(self, raw: list) -> List[BoundingBox]:
        """YOLOS 탐지 결과를 내부 표준 BoundingBox 목록으로 변환"""
        return self._pipeline.to_bounding_boxes(raw)


# ============================================================
# 추후 구현 예시 (팀원 모델 확정 후 추가)
# ============================================================
#
# class YOLOv8Detector(BaseDetector):
#     def __init__(self, model_path: str):
#         from ultralytics import YOLO
#         self.model = YOLO(model_path)
#
#     async def detect(self, image: Image.Image) -> Any:
#         # ultralytics YOLO는 동기 실행이므로 asyncio.to_thread 사용 권장
#         import asyncio
#         return await asyncio.to_thread(self.model, image)
#
#     def parse_result(self, raw: Any) -> List[BoundingBox]:
#         boxes = []
#         for result in raw:
#             for box in result.boxes:
#                 xyxy = box.xyxy[0].tolist()
#                 boxes.append(BoundingBox(
#                     xmin=xyxy[0], ymin=xyxy[1],
#                     xmax=xyxy[2], ymax=xyxy[3],
#                     confidence=float(box.conf[0]),
#                     label=result.names[int(box.cls[0])],
#                 ))
#         return boxes
