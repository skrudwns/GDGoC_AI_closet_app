AI 옷장 백엔드 파이프라인 및 서비스 개발 계획서 (Project Plan)

본 프로젝트는 사용자가 업로드한 의류 이미지에서 자동으로 객체를 탐지하고 메타데이터를 추출(태깅)하여, 개인 맞춤형 옷장 관리, 자연어 기반 검색, 그리고 스타일 일관성 및 TPO를 고려한 코디 추천 시스템을 제공하는 FastAPI 기반 백엔드 파이프라인 개발을 목표로 합니다.

---

## 1. 시스템 아키텍처 및 파이프라인 (Pipeline Architecture)

전체 파이프라인은 데이터의 실시간 처리 부하를 분산하고, 사용자 경험을 최적화하기 위해 **비동기 이벤트 기반 구조(Asynchronous Event-Driven Architecture)**로 설계합니다. 이미지 처리는 무거운 작업이므로 FastAPI의 `BackgroundTasks` 또는 `Celery` 워커를 활용합니다.


[클라이언트 (App)] ──(이미지 업로드)──> [FastAPI 엔드포인트]
│ (HTTP 202 즉시 반환 / Task 등록)
▼
[비동기 백그라운드 워커]
│
┌──────────────────────────────────────┴──────────────────────────────────────┐
▼                                      ▼                                      ▼
[1단계: 이미지 전처리]                 [2단계: 객체 탐지 및 크롭]             [3단계: 메타데이터 태깅]

* 이미지 리사이징/정규화                 - YOLO 기반 의류 영역 탐지            - VLM 또는 특화 모델(fashionpedia) 활용 구조화 데이터 추출
*                                  - 상의/하의/아우터/신발               - 카테고리, 색상, 소재, 스타일
│                                      │                                      │
└──────────────────────────────────────┼──────────────────────────────────────┘
▼
[4단계: 데이터 영속화]
- MVP 단계에서 로컬DB로 관리

```

### 파이프라인 세부 단계
1. **이미지 수신 및 전처리 (Ingestion & Preprocessing)**
   - 프론트는 flutter로 앱에서 이미지 파일을 수신받음
   - 이미지 정규화 및 전처리 과정
   - 이미지의 불필요한 배경 및 객체 제거 (rembg 라이브러리 같은)
2. **객체 탐지 및 크롭 (Object Detection & Cropping)**
   - 전신 사진이나 여러 의류가 동시에 찍힌 경우를 대비하여 `YOLOv8` 또는 `Faster R-CNN` 기반의 의류 검출 모델을 거칩니다.
   - 검출된 각 Bounding Box(`[xmin, ymin, xmax, ymax]`)를 기준으로 이미지를 각각 크롭(Crop)하여 개별 의류 단위로 분할합니다.
3. **메타데이터 태깅 (Metadata Tagging)**
   - 크롭된 개별 의류 이미지를 태깅 파이프라인으로 전달합니다.
4. **DB 저장**
   - 크롭된 이미지와 원본 이미지를 로컬 스토리지에 업로드하고 고유 URL을 발급받습니다.
   - 발급된 이미지 URL과 추출된 태그 정보를 구조화하여 관계형 데이터베이스(RDB)에 저장합니다.

---

## 2. 주요 기능별 세부 구현 전략

### ① 의류 자동 태깅 (Clothing Tagging)

- **VLM (GPT-4o-mini / Claude 3.5 Haiku) 활용 전략**
  - FastAPI에서 `Pydantic` 라이브러리를 사용해 반환받고자 하는 데이터 구조(Schema)를 정의합니다.
  - 아직 어떤 모델로 객체 탐지와 태깅 작업을 수행할 지 미정(일단 내 역할은 백엔드의 파이프라인만 구축하는 것이 목표)
- **정의할 메타데이터 구조 (Pydantic Schema 예시)**
  ```python
  from pydantic import BaseModel
  from typing import List

  class ClothingTagSchema(BaseModel):
      category: str  # 상의, 하의, 아우터, 원피스, 신발 등
      sub_category: str  # 셔츠, 후드티, 슬랙스, 패딩 등
      color: List[str]  # ['Black', 'Navy']
      pattern: str  # 무지, 스트라이프, 체크, 플로럴 등
      material: List[str]  # ['Cotton', 'Denim']
      style: List[str]  # ['Casual', 'Street', 'Minimal']
      season: List[str]  # ['Spring', 'Autumn']

```

### ② 자연어 기반 옷장 검색 (Natural Language Search)

"내일 입을 만한 어두운 색 아우터 보여줘"와 같은 복잡한 사용자의 자연어 요청을 처리하기 위해 **하이브리드 검색(Hybrid Search)** 아키텍처를 구성합니다.

1. **LLM 기반 쿼리 파싱 (Query Parsing)**
* 사용자의 자연어 입력 스트링을 가벼운 텍스트 LLM에 통과시켜 DB 검색용 필터 조건(JSON)으로 변환합니다.
* 날씨와 같은 정보는 추후 API로 받아올 예정
* 예: `"내일 입을 어두운 아우터"` → `{"category": "outer", "color_tone": "dark", "weather_context": "rainy"}`


2. **벡터 유사도 검색 (Vector Search) 연동**
* 옷을 등록할 때 추출된 메타데이터를 문장형 태그("가을에 입기 좋은 검은색 면 소재의 오버핏 후드 자켓")로 조합한 뒤, 이를 텍스트 임베딩 모델(`text-embedding-3-small`)을 통해 벡터로 변환합니다.
* PostgreSQL의 `pgvector` 플러그인을 활용하여, 사용자의 검색어 임베딩과 옷장 내 아이템들 간의 코사인 유사도(Cosine Similarity)를 계산하여 순위를 매깁니다.



### ③ 코디 추천 시스템 (Outfit Recommendation)

사용자가 인용한 논문(Polyvore Dataset 기반 시각적 호환성 및 스타일 일관성 평가)의 철학을 반영하되, 실시간 서비스에서 발생할 수 있는 **조합 폭발(Combinatorial Explosion)** 문제를 해결하기 위해 2단계 필터 및 랭킹 구조(Two-stage Filtering & Ranking)를 설계합니다.

1. **1단계: 룰 베이스 필터링 (Rule-based Filtering)**
* 날씨 API(OpenWeatherMap 등)를 호출하여 현재/내일의 기온, 강수 여부를 파악합니다.
* 현재 기온에 맞지 않는 계절성 옷(예: 여름에 패딩, 겨울에 반바지)을 DB 쿼리 레벨에서 1차적으로 제외합니다.
* 상의/하의/아우터 등 필수 카테고리 조합의 후보군을 생성합니다.


2. **2단계: 스타일 호환성 및 적합도 평가 (Ranking Stage)**
* **기반 데이터셋:** Polyvore Dataset으로 학습된 임베딩 스페이스 또는 사전에 정의된 스타일 매칭 매트릭스를 활용합니다.
* **VLM 기반 평점 시스템 (MVP 단계):** 1단계에서 필터링된 상위 조합 후보(약 5~10개 세트)의 이미지 URL 또는 메타데이터 텍스트를 VLM에게 전달합니다.
* VLM에게 아래 3가지 가이드라인을 기반으로 각 조합당 100점 만점의 점수와 추천 사유를 반환하도록 프롬프팅합니다.
* *시각적 호환성(Visual Compatibility):* 색상 조합 및 핏의 조화도
* *스타일 일관성(Style Consistency):* 미니멀, 스트릿 등 무드의 통일성
* *상황 적합성(TPO/Weather):* 사용자의 일정(출근, 데이트 등) 및 날씨 부합도




3. **3단계: 최종 추천 조합 노출**
* 가장 높은 점수를 받은 Top 3 코디 조합을 추천 사유 한 줄 요약과 함께 프론트엔드로 반환합니다.



---

## 3. 데이터베이스 스키마 설계 (Database Schema)

관계형 데이터베이스(PostgreSQL)를 기반으로 확장성을 고려해 설계한 개념적 스키마입니다.

```sql
-- 1. 사용자 테이블
CREATE TABLE users (
    user_id SERIAL PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 2. 의류 아이템 테이블
CREATE TABLE clothes (
    cloth_id SERIAL PRIMARY KEY,
    user_id INT REFERENCES users(user_id) ON DELETE CASCADE,
    image_url TEXT NOT NULL,          -- S3 크롭 이미지 URL
    original_image_url TEXT,          -- S3 원본 이미지 URL
    category VARCHAR(50) NOT NULL,    -- 상의, 하의 등
    sub_category VARCHAR(50),         -- 셔츠, 슬랙스 등
    pattern VARCHAR(50),              -- 무지, 스트라이프 등
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 3. 의류 다중 태그 테이블 (색상, 소재, 스타일, 계절 등 다중 값을 위해 매핑)
CREATE TABLE cloth_tags (
    tag_id SERIAL PRIMARY KEY,
    cloth_id INT REFERENCES clothes(cloth_id) ON DELETE CASCADE,
    tag_type VARCHAR(50) NOT NULL,    -- 'color', 'material', 'style', 'season'
    tag_value VARCHAR(100) NOT NULL
);

-- 4. 자연어 검색용 벡터 저장 테이블 (pgvector 사용 시)
CREATE TABLE cloth_embeddings (
    embedding_id SERIAL PRIMARY KEY,
    cloth_id INT REFERENCES clothes(cloth_id) ON DELETE CASCADE,
    description_text TEXT NOT NULL,   -- 메타데이터 총합 문장
    embedding vector(1536)            -- OpenAI Embedding 차원 수
);

-- 5. 사용자가 저장하거나 추천된 코디 조합 히스토리 테이블
CREATE TABLE outfits (
    outfit_id SERIAL PRIMARY KEY,
    user_id INT REFERENCES users(user_id) ON DELETE CASCADE,
    name VARCHAR(100),
    description TEXT,
    compatibility_score INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 6. 코디-의류 매핑 테이블 (N:M 관계 인터섹션 테이블)
CREATE TABLE outfit_items (
    outfit_id INT REFERENCES outfits(outfit_id) ON DELETE CASCADE,
    cloth_id INT REFERENCES clothes(cloth_id) ON DELETE CASCADE,
    PRIMARY KEY (outfit_id, cloth_id)
);

```

---