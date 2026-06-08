# AI 옷장 백엔드

Flutter 앱에서 의류 이미지를 수신하여 **전처리 → 객체 탐지 → 메타데이터 태깅 → DB 저장** 파이프라인을 처리하는 FastAPI 백엔드입니다.

---

## 빠른 시작

### 1. 사전 요구사항

- Python 3.11+
- PostgreSQL 15+

### 2. 환경 설정

```bash
cd backend

# 가상환경 생성 및 활성화
python -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate

# 의존성 설치
pip install -r requirements.txt

# 환경 변수 설정
cp .env.example .env
# .env 파일을 열어 PostgreSQL 접속 정보를 수정하세요
```

### 3. PostgreSQL DB 생성

```bash
createdb aicloset
```

### 4. 서버 실행

```bash
uvicorn app.main:app --reload
```

서버가 시작되면 자동으로 DB 테이블이 생성됩니다.

- API 문서: http://localhost:8000/docs
- 상태 확인: http://localhost:8000/

---

## API 엔드포인트

| Method | Path | 설명 |
|--------|------|------|
| `GET` | `/` | 서버 상태 확인 |
| `POST` | `/clothing/upload` | 의류 이미지 업로드 (HTTP 202 즉시 반환) |
| `GET` | `/clothing/` | 의류 목록 조회 (`?user_id=1`) |
| `GET` | `/clothing/{id}` | 의류 상세 조회 (`?user_id=1`) |
| `DELETE` | `/clothing/{id}` | 의류 삭제 (`?user_id=1`) |
| `GET` | `/pipeline/status/{task_id}` | 파이프라인 처리 상태 조회 |

### Flutter 앱 연동 흐름

```
1. POST /clothing/upload (multipart/form-data, file + user_id)
   → 즉시 { "task_id": "abc123", "status": "pending" } 반환

2. GET /pipeline/status/abc123  (폴링)
   → { "status": "processing" }
   → { "status": "done", "clothing_ids": [1, 2] }

3. GET /clothing/1?user_id=1
   → 저장된 의류 메타데이터 조회
```

---

## 파이프라인 구조

```
이미지 업로드
    │
    ├── [1] Preprocessor  — EXIF 보정, 리사이징 (최대 1024px), RGB 변환
    │
    ├── [2] Detector      — 의류 객체 탐지 → Bounding Box 목록
    │        └── MockDetector (현재) → YOLOv8 / Faster R-CNN (추후)
    │
    ├── [3] Tagger        — 크롭 이미지 → 메타데이터 태그 추출
    │        └── MockTagger (현재) → VLM (GPT-4o-mini 등) / FashionPedia (추후)
    │
    └── [4] Storage + DB  — 로컬 파일 저장 + PostgreSQL 저장
```

---

## 모델 교체 방법

`.env` 파일에서 구현체를 선택합니다:

```env
DETECTOR_TYPE=mock    # mock | yolo | faster_rcnn
TAGGER_TYPE=mock      # mock | vlm_openai | vlm_claude | fashionpedia
```

새 모델 구현체는 `app/pipeline/detector.py` 또는 `tagger.py`에 클래스를 추가하고,
`app/pipeline/orchestrator.py`의 팩토리 함수(`_get_detector`, `_get_tagger`)에 분기를 추가합니다.

---

## 테스트

```bash
# 전체 테스트 실행
pytest -v

# 파이프라인 단위 테스트만
pytest tests/test_pipeline.py -v

# API 통합 테스트만 (aiosqlite 필요)
pip install aiosqlite
pytest tests/test_api.py -v
```

---

## 디렉토리 구조

```
backend/
├── app/
│   ├── main.py              # FastAPI 진입점
│   ├── config.py            # 환경 설정
│   ├── database.py          # DB 연결 (PostgreSQL async)
│   ├── models/              # SQLAlchemy ORM 모델
│   ├── schemas/             # Pydantic 스키마
│   ├── pipeline/            # 파이프라인 모듈 (핵심)
│   │   ├── preprocessor.py  # 1단계: 이미지 전처리
│   │   ├── detector.py      # 2단계: 객체 탐지 (추상화)
│   │   ├── tagger.py        # 3단계: 메타데이터 태깅 (추상화)
│   │   ├── storage.py       # 로컬 이미지 저장
│   │   └── orchestrator.py  # 파이프라인 통합 실행
│   ├── services/            # 비즈니스 로직
│   └── routers/             # API 라우터
├── storage/
│   ├── originals/           # 원본 이미지
│   └── crops/               # 크롭 이미지
├── tests/
├── requirements.txt
├── .env.example
└── pytest.ini
```
