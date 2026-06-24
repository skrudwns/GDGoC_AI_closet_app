"""
YOLOS + CLIP 통합 패션 분석 파이프라인 서비스

두 모델을 조합하여 의류 이미지를 분석합니다:
  - YOLOS (valentinafeve/yolos-fashionpedia): 의류 영역 탐지 + 카테고리 검출
  - CLIP (openai/clip-vit-base-patch32): 크롭된 의류의 세부 속성 분류

싱글턴 패턴으로 구현하여 서버 시작 시 모델을 1회 로드합니다.
"""
from __future__ import annotations

import logging
from typing import Any

from PIL import Image

from app.schemas.clothing import BoundingBox, ClothingTagSchema

logger = logging.getLogger(__name__)


# ─────────────────────────────────────────────────────────────
# 카테고리 매핑 테이블
# YOLOS 영문 레이블 → (한국어 대분류, 한국어 소분류)
# ─────────────────────────────────────────────────────────────
CATEGORY_MAP: dict[str, tuple[str, str]] = {
    "shirt, blouse":            ("상의", "셔츠"),
    "top, t-shirt, sweatshirt": ("상의", "티셔츠"),
    "sweater":                  ("니트", "스웨터"),
    "cardigan":                 ("니트", "카디건"),
    "jacket":                   ("아우터", "재킷"),
    "vest":                     ("아우터", "조끼"),
    "pants":                    ("하의", "바지"),
    "shorts":                   ("하의", "반바지"),
    "skirt":                    ("하의", "스커트"),
    "coat":                     ("아우터", "코트"),
    "dress":                    ("원피스", "원피스"),
    "jumpsuit":                 ("원피스", "점프수트"),
    "cape":                     ("아우터", "케이프"),
}

VALID_GARMENTS: set[str] = set(CATEGORY_MAP.keys())

# ─────────────────────────────────────────────────────────────
# CLIP 속성 정의
# ─────────────────────────────────────────────────────────────
CLIP_ATTRIBUTES: dict[str, list[str]] = {
    "color":    ["black", "white", "red", "blue", "green", "yellow", "pink",
                 "gray", "brown", "purple", "beige", "navy", "orange"],
    "pattern":  ["solid", "striped", "floral", "plaid", "graphic",
                 "polka dot", "camouflage", "checkered"],
    "material": ["denim", "leather", "knit", "lace", "cotton",
                 "silk", "wool", "fleece", "polyester", "velvet"],
    "sleeve":   ["sleeveless", "short-sleeve", "long-sleeve", "three-quarter sleeve"],
    "neckline": ["v-neck", "round-neck", "turtleneck", "off-shoulder",
                 "square-neck", "hooded", "collar"],
    "fit":      ["slim", "regular", "oversized", "relaxed"],
    "decoration": ["ruffle", "embroidery", "fringe", "sequin", "bow",
                   "pocket", "drawstring"],
}

# ─────────────────────────────────────────────────────────────
# 속성 → 한국어 번역 사전
# ─────────────────────────────────────────────────────────────
TRANSLATION_MAP: dict[str, str] = {
    # 색상
    "black": "블랙", "white": "화이트", "red": "레드", "blue": "블루",
    "green": "그린", "yellow": "옐로우", "pink": "핑크", "gray": "그레이",
    "brown": "브라운", "purple": "퍼플", "beige": "베이지",
    "navy": "네이비", "orange": "오렌지",
    # 패턴
    "solid": "무지", "striped": "스트라이프", "floral": "플로럴",
    "plaid": "체크", "graphic": "그래픽", "polka dot": "물방울무늬",
    "camouflage": "카모플라쥬", "checkered": "체크",
    # 소재
    "denim": "데님", "leather": "레더", "knit": "니트", "lace": "레이스",
    "cotton": "코튼", "silk": "실크", "wool": "울", "fleece": "플리스",
    "polyester": "폴리에스터", "velvet": "벨벳",
    # 핏
    "slim": "슬림핏", "regular": "레귤러핏", "oversized": "오버핏",
    "relaxed": "릴렉스핏",
    # 소매
    "sleeveless": "민소매", "short-sleeve": "반팔", "long-sleeve": "긴팔",
    "three-quarter sleeve": "칠부소매",
}


class YolosCLIPPipeline:
    """
    YOLOS 탐지 + CLIP 속성 분류 통합 서비스.

    싱글턴 패턴: get_instance()로만 생성하여 모델을 앱 수명 동안 1회만 로드합니다.
    """

    _instance: "YolosCLIPPipeline | None" = None

    @classmethod
    def get_instance(cls) -> "YolosCLIPPipeline":
        """싱글턴 인스턴스를 반환합니다. 없으면 생성합니다."""
        if cls._instance is None:
            cls._instance = cls()
        return cls._instance

    def __init__(self) -> None:
        import torch
        from transformers import pipeline as hf_pipeline, CLIPProcessor, CLIPModel

        self.torch = torch
        self.device = "cpu"
        logger.info(f"AI 파이프라인 장치: {self.device}")

        logger.info("YOLOS Fashionpedia 모델 로딩 중... (최초 실행 시 다운로드 수분 소요)")
        # pipeline의 device는 -1=CPU, 0,1,...=CUDA GPU 인덱스
        self.detector = hf_pipeline(
            "object-detection",
            model="valentinafeve/yolos-fashionpedia",
            device=-1,
        )
        logger.info("YOLOS 모델 로드 완료.")

        logger.info("CLIP 모델 로딩 중...")
        self.clip_model = CLIPModel.from_pretrained("openai/clip-vit-base-patch32")
        self.clip_processor = CLIPProcessor.from_pretrained("openai/clip-vit-base-patch32")
        self.clip_model.eval()
        logger.info("CLIP 모델 로드 완료. AI 파이프라인 준비됨.")

    # ─────────────────────────────────────────────────────────
    # Public API
    # ─────────────────────────────────────────────────────────

    def detect_clothing(
        self, image: Image.Image, threshold: float = 0.5
    ) -> list[dict[str, Any]]:
        """
        YOLOS 모델로 의류 객체를 탐지합니다.

        Args:
            image: 입력 PIL Image (RGB)
            threshold: 탐지 신뢰도 임계값 (기본 0.5)

        Returns:
            유효한 패션 카테고리의 탐지 결과 목록.
            각 항목: {"score": float, "label": str, "box": {"xmin", "ymin", "xmax", "ymax"}}
        """
        raw_detections = self.detector(image, threshold=threshold)
        valid = [d for d in raw_detections if d["label"] in VALID_GARMENTS]
        logger.info(f"YOLOS 탐지 결과: {len(raw_detections)}개 중 유효 {len(valid)}개")
        return valid

    def classify_attributes(self, crop: Image.Image) -> dict[str, list[tuple[str, float]]]:
        """
        CLIP 모델로 크롭된 의류 이미지의 세부 속성을 분류합니다.

        Args:
            crop: YOLOS로 크롭된 단일 의류 PIL Image

        Returns:
            속성 카테고리별 (속성명, 확률) 쌍의 내림차순 목록.
            예: {"color": [("black", 0.82), ("navy", 0.11), ...], ...}
        """
        results: dict[str, list[tuple[str, float]]] = {}

        for category, candidates in CLIP_ATTRIBUTES.items():
            texts = [f"a {attr} clothing" for attr in candidates]
            inputs = self.clip_processor(
                text=texts, images=crop, return_tensors="pt", padding=True
            )
            with self.torch.no_grad():
                outputs = self.clip_model(**inputs)
            probs = outputs.logits_per_image.softmax(dim=1)[0]
            pairs = sorted(
                zip(candidates, probs.tolist()), key=lambda x: -x[1]
            )
            results[category] = [(attr, round(prob, 3)) for attr, prob in pairs]

        return results

    def build_tag_schema(
        self,
        original_label: str,
        raw_attrs: dict[str, list[tuple[str, float]]],
        detection_score: float,
    ) -> ClothingTagSchema:
        """
        YOLOS 탐지 레이블과 CLIP 속성 분석 결과를 ClothingTagSchema로 변환합니다.

        Args:
            original_label: YOLOS가 탐지한 원래 영문 레이블
            raw_attrs: classify_attributes()의 반환값
            detection_score: YOLOS 탐지 신뢰도

        Returns:
            파이프라인 표준 ClothingTagSchema
        """
        category, sub_category = CATEGORY_MAP.get(original_label, ("기타", original_label))

        # ── 티셔츠 그룹 세분화 ──────────────────────────────────
        if original_label == "top, t-shirt, sweatshirt":
            sleeve_results = raw_attrs.get("sleeve", [])
            neckline_results = raw_attrs.get("neckline", [])

            is_hooded = any(
                attr == "hooded" and prob >= 0.45
                for attr, prob in neckline_results
            )
            top_sleeve = (
                sleeve_results[0][0]
                if sleeve_results and sleeve_results[0][1] >= 0.45
                else "unknown"
            )

            if is_hooded:
                sub_category = "후드티"
            elif top_sleeve == "long-sleeve":
                sub_category = "긴팔 티셔츠"
            elif top_sleeve in ["short-sleeve", "three-quarter sleeve"]:
                sub_category = "반팔 티셔츠"

        # ── 셔츠/블라우스 세분화 ─────────────────────────────────
        elif original_label == "shirt, blouse":
            deco_results = raw_attrs.get("decoration", [])
            is_blouse = any(
                attr in ["ruffle", "bow"] and prob >= 0.45
                for attr, prob in deco_results
            )
            sub_category = "블라우스" if is_blouse else "셔츠"

        # ── 속성 추출 헬퍼 ──────────────────────────────────────
        def top_values(key: str, n: int = 2, threshold: float = 0.35) -> list[str]:
            """신뢰도 임계값 이상의 상위 n개 속성을 한국어로 반환합니다."""
            items = raw_attrs.get(key, [])
            return [
                TRANSLATION_MAP.get(attr, attr)
                for attr, prob in items[:n]
                if prob >= threshold
            ]

        def top_value(key: str, threshold: float = 0.45) -> str | None:
            """신뢰도 임계값 이상의 최상위 속성을 한국어로 반환합니다."""
            items = raw_attrs.get(key, [])
            if items and items[0][1] >= threshold:
                return TRANSLATION_MAP.get(items[0][0], items[0][0])
            return None

        # ── 스타일 태그 (핏 → 스타일) ───────────────────────────
        styles: list[str] = []
        fit_val = top_value("fit", threshold=0.45)
        if fit_val:
            styles.append(fit_val)

        return ClothingTagSchema(
            category=category,
            sub_category=sub_category,
            color=top_values("color", n=2, threshold=0.35),
            pattern=top_value("pattern", threshold=0.45),
            material=top_values("material", n=2, threshold=0.35),
            style=styles,
            season=[],  # 계절은 사용자 입력 또는 추후 날씨 API 연동
            extra={"detection_confidence": round(detection_score, 3)},
        )

    def to_bounding_boxes(
        self, detections: list[dict[str, Any]]
    ) -> list[BoundingBox]:
        """
        YOLOS 탐지 결과를 내부 표준 BoundingBox 목록으로 변환합니다.

        Args:
            detections: detect_clothing()의 반환값

        Returns:
            BoundingBox 목록
        """
        boxes: list[BoundingBox] = []
        for d in detections:
            box = d["box"]
            boxes.append(
                BoundingBox(
                    xmin=float(box["xmin"]),
                    ymin=float(box["ymin"]),
                    xmax=float(box["xmax"]),
                    ymax=float(box["ymax"]),
                    confidence=float(d["score"]),
                    label=d["label"],
                )
            )
        return boxes
