# AI 옷장 API 명세서 (Flutter ↔ Backend)

**Base URL** (개발): `http://localhost:8000`  
**API Version**: `v0.1.0`  
**인코딩**: `UTF-8`  
**인증**: MVP 단계 미적용 (모든 요청에 `user_id`를 파라미터로 전달)

---

## 목차

1. [공통 규칙](#1-공통-규칙)
2. [헬스 체크](#2-헬스-체크)
3. [의류 업로드 및 파이프라인](#3-의류-업로드-및-파이프라인)
   - [POST /clothing/upload](#31-post-clothingupload)
   - [GET /pipeline/status/{task_id}](#32-get-pipelinestatustask_id)
4. [의류 CRUD](#4-의류-crud)
   - [GET /clothing/](#41-get-clothing)
   - [GET /clothing/{cloth_id}](#42-get-clothingcloth_id)
   - [DELETE /clothing/{cloth_id}](#43-delete-clothingcloth_id)
5. [이미지 파일 접근](#5-이미지-파일-접근)
6. [에러 코드 정리](#6-에러-코드-정리)
7. [Flutter 연동 흐름 (Sequence)](#7-flutter-연동-흐름-sequence)
8. [공통 데이터 타입 정의](#8-공통-데이터-타입-정의)

---

## 1. 공통 규칙

### 요청 헤더

| 헤더 | 값 | 필수 |
|------|----|------|
| `Content-Type` | `application/json` 또는 `multipart/form-data` | 엔드포인트별 상이 |
| `Accept` | `application/json` | 권고 |

### 공통 에러 응답 형식

모든 에러 응답은 아래 형식을 따릅니다:

```json
{
  "detail": "에러 메시지"
}
```

### MVP 인증 방식

현재 JWT 등 별도 인증 없이 `user_id`를 쿼리 파라미터 또는 Form 필드로 전달합니다.  
추후 Firebase Auth 또는 JWT 토큰 방식으로 교체 예정입니다.

---

## 2. 헬스 체크

### `GET /`

서버 상태 및 현재 활성화된 파이프라인 모델 정보를 반환합니다.

**Request**

```
GET http://localhost:8000/
```

**Response** `200 OK`

```json
{
  "status": "ok",
  "app": "AI 옷장 백엔드",
  "version": "0.1.0",
  "detector": "mock",
  "tagger": "mock"
}
```

| 필드 | 타입 | 설명 |
|------|------|------|
| `status` | `string` | 서버 상태 (`"ok"`) |
| `app` | `string` | 앱 이름 |
| `version` | `string` | API 버전 |
| `detector` | `string` | 현재 사용 중인 탐지 모델 (`mock` \| `yolo` \| ...) |
| `tagger` | `string` | 현재 사용 중인 태깅 모델 (`mock` \| `vlm_openai` \| ...) |

---

## 3. 의류 업로드 및 파이프라인

의류 이미지 업로드는 **비동기 2단계** 방식으로 동작합니다.

```
Step 1) POST /clothing/upload  →  즉시 task_id 반환 (HTTP 202)
Step 2) GET  /pipeline/status/{task_id}  →  폴링하여 완료 여부 확인
```

---

### 3.1 `POST /clothing/upload`

의류 이미지를 업로드합니다. 업로드 즉시 `HTTP 202`와 `task_id`를 반환하고, 백그라운드에서 파이프라인(전처리 → 탐지 → 태깅 → 저장)을 실행합니다.

**Request**

- **Content-Type**: `multipart/form-data`

| 필드 | 타입 | 필수 | 설명 |
|------|------|------|------|
| `file` | `File` | ✅ | 업로드할 이미지 파일. 허용 형식: **JPEG, PNG, WEBP**. 최대 크기: **10MB** |
| `user_id` | `integer` | ✅ | 업로드하는 사용자 ID |

**Flutter 예시 코드**

```dart
Future<UploadResponse> uploadClothing(File imageFile, int userId) async {
  final uri = Uri.parse('$baseUrl/clothing/upload');
  final request = http.MultipartRequest('POST', uri);

  request.fields['user_id'] = userId.toString();
  request.files.add(await http.MultipartFile.fromPath(
    'file',
    imageFile.path,
    contentType: MediaType('image', 'jpeg'), // 또는 'png', 'webp'
  ));

  final streamedResponse = await request.send();
  final response = await http.Response.fromStream(streamedResponse);

  if (response.statusCode == 202) {
    return UploadResponse.fromJson(jsonDecode(response.body));
  }
  throw Exception('업로드 실패: ${response.statusCode}');
}
```

**Response** `202 Accepted`

```json
{
  "task_id": "a3f8c1d2e0b74e5f9012ab34cd56ef78",
  "status": "pending",
  "message": "이미지가 업로드되었습니다. 파이프라인 처리 중입니다."
}
```

| 필드 | 타입 | 설명 |
|------|------|------|
| `task_id` | `string` | 파이프라인 작업 추적 ID (32자리 hex 문자열) |
| `status` | `string` | 초기 상태 (항상 `"pending"`) |
| `message` | `string` | 안내 메시지 |

**Error Responses**

| HTTP 코드 | 발생 조건 | `detail` 예시 |
|-----------|----------|--------------|
| `415 Unsupported Media Type` | 허용되지 않는 이미지 형식 | `"지원하지 않는 이미지 형식입니다: image/gif"` |
| `413 Request Entity Too Large` | 파일 크기 10MB 초과 | `"파일 크기가 제한을 초과합니다 (최대 10MB)."` |
| `422 Unprocessable Entity` | 필수 파라미터 누락 | `{"detail": [{"loc": ["body", "user_id"], "msg": "Field required"}]}` |

---

### 3.2 `GET /pipeline/status/{task_id}`

업로드 후 파이프라인 처리 상태를 조회합니다. `status`가 `"done"`이 될 때까지 폴링합니다.

**Request**

```
GET http://localhost:8000/pipeline/status/{task_id}
```

| Path Parameter | 타입 | 설명 |
|----------------|------|------|
| `task_id` | `string` | 업로드 시 발급받은 task_id |

**Flutter 폴링 예시 코드**

```dart
Future<List<int>> pollPipelineUntilDone(String taskId) async {
  const maxRetries = 30;
  const interval = Duration(seconds: 2);

  for (int i = 0; i < maxRetries; i++) {
    final response = await http.get(
      Uri.parse('$baseUrl/pipeline/status/$taskId'),
    );
    final data = jsonDecode(response.body);
    final status = data['status'] as String;

    switch (status) {
      case 'done':
        return List<int>.from(data['clothing_ids']);
      case 'failed':
        throw Exception('파이프라인 실패: ${data['error']}');
      case 'pending':
      case 'processing':
        await Future.delayed(interval);
    }
  }
  throw TimeoutException('파이프라인 처리 시간 초과');
}
```

**Response** `200 OK`

```json
{
  "task_id": "a3f8c1d2e0b74e5f9012ab34cd56ef78",
  "status": "done",
  "clothing_ids": [1, 2],
  "error": null,
  "message": "처리가 완료되었습니다."
}
```

| 필드 | 타입 | 설명 |
|------|------|------|
| `task_id` | `string` | 작업 ID |
| `status` | `string` | 처리 상태 — 아래 상태 전이도 참고 |
| `clothing_ids` | `integer[]` | 저장된 의류 ID 목록 (`status=done`일 때 채워짐) |
| `error` | `string \| null` | 오류 메시지 (`status=failed`일 때만 존재) |
| `message` | `string` | 상태별 안내 메시지 |

**`status` 값 및 전이**

```
pending  →  processing  →  done
                        ↘  failed
```

| `status` 값 | 의미 | Flutter 대응 |
|-------------|------|-------------|
| `"pending"` | 파이프라인 대기 중 | 2초 후 재폴링 |
| `"processing"` | 이미지 처리 진행 중 | 2초 후 재폴링 |
| `"done"` | 처리 완료 | `clothing_ids`로 상세 조회 |
| `"failed"` | 처리 실패 | `error` 메시지 표시 후 재시도 유도 |

**Error Responses**

| HTTP 코드 | 발생 조건 | `detail` 예시 |
|-----------|----------|--------------|
| `404 Not Found` | 존재하지 않는 `task_id` | `"task_id 'xxx'에 해당하는 작업을 찾을 수 없습니다."` |

> [!NOTE]
> **서버 재시작 시 task_id 초기화**: MVP 단계에서 파이프라인 상태는 서버 메모리에 저장됩니다. 서버가 재시작되면 기존 `task_id`는 404를 반환합니다.

---

## 4. 의류 CRUD

### 4.1 `GET /clothing/`

특정 사용자의 의류 목록을 등록 최신순으로 반환합니다.

**Request**

```
GET http://localhost:8000/clothing/?user_id={user_id}
```

| Query Parameter | 타입 | 필수 | 설명 |
|-----------------|------|------|------|
| `user_id` | `integer` | ✅ | 조회할 사용자 ID |

**Flutter 예시 코드**

```dart
Future<ClothingListResponse> getClothingList(int userId) async {
  final response = await http.get(
    Uri.parse('$baseUrl/clothing/?user_id=$userId'),
  );
  if (response.statusCode == 200) {
    return ClothingListResponse.fromJson(jsonDecode(response.body));
  }
  throw Exception('목록 조회 실패');
}
```

**Response** `200 OK`

```json
{
  "total": 2,
  "items": [
    {
      "cloth_id": 2,
      "user_id": 1,
      "image_url": "storage/crops/abc123_1.jpg",
      "original_image_url": "storage/originals/abc123.jpg",
      "category": "하의",
      "sub_category": "슬랙스",
      "pattern": "무지",
      "pipeline_status": "done",
      "tags": [
        { "tag_type": "color",    "tag_value": "Black" },
        { "tag_type": "material", "tag_value": "Polyester" },
        { "tag_type": "style",    "tag_value": "Minimal" },
        { "tag_type": "season",   "tag_value": "Spring" },
        { "tag_type": "season",   "tag_value": "Autumn" }
      ],
      "created_at": "2026-05-24T19:20:00+09:00"
    },
    {
      "cloth_id": 1,
      "user_id": 1,
      "image_url": "storage/crops/abc123_0.jpg",
      "original_image_url": "storage/originals/abc123.jpg",
      "category": "상의",
      "sub_category": "후드티",
      "pattern": "무지",
      "pipeline_status": "done",
      "tags": [
        { "tag_type": "color",    "tag_value": "Black" },
        { "tag_type": "material", "tag_value": "Cotton" },
        { "tag_type": "style",    "tag_value": "Casual" },
        { "tag_type": "season",   "tag_value": "Spring" },
        { "tag_type": "season",   "tag_value": "Autumn" }
      ],
      "created_at": "2026-05-24T19:19:00+09:00"
    }
  ]
}
```

| 필드 | 타입 | 설명 |
|------|------|------|
| `total` | `integer` | 전체 의류 수 |
| `items` | `ClothingItem[]` | 의류 목록 (최신순) |

---

### 4.2 `GET /clothing/{cloth_id}`

특정 의류 아이템의 상세 정보를 조회합니다.

**Request**

```
GET http://localhost:8000/clothing/{cloth_id}?user_id={user_id}
```

| 파라미터 | 위치 | 타입 | 필수 | 설명 |
|---------|------|------|------|------|
| `cloth_id` | Path | `integer` | ✅ | 조회할 의류 ID |
| `user_id` | Query | `integer` | ✅ | 소유자 확인용 사용자 ID |

**Flutter 예시 코드**

```dart
Future<ClothingItem> getClothingDetail(int clothId, int userId) async {
  final response = await http.get(
    Uri.parse('$baseUrl/clothing/$clothId?user_id=$userId'),
  );
  if (response.statusCode == 200) {
    return ClothingItem.fromJson(jsonDecode(response.body));
  }
  if (response.statusCode == 404) {
    throw Exception('의류를 찾을 수 없습니다.');
  }
  throw Exception('상세 조회 실패');
}
```

**Response** `200 OK`

```json
{
  "cloth_id": 1,
  "user_id": 1,
  "image_url": "storage/crops/abc123_0.jpg",
  "original_image_url": "storage/originals/abc123.jpg",
  "category": "상의",
  "sub_category": "후드티",
  "pattern": "무지",
  "pipeline_status": "done",
  "tags": [
    { "tag_type": "color",    "tag_value": "Black" },
    { "tag_type": "material", "tag_value": "Cotton" },
    { "tag_type": "style",    "tag_value": "Casual" },
    { "tag_type": "season",   "tag_value": "Spring" },
    { "tag_type": "season",   "tag_value": "Autumn" }
  ],
  "created_at": "2026-05-24T19:19:00+09:00"
}
```

**Error Responses**

| HTTP 코드 | 발생 조건 |
|-----------|----------|
| `404 Not Found` | `cloth_id`가 존재하지 않거나 해당 `user_id`의 것이 아님 |

---

### 4.3 `DELETE /clothing/{cloth_id}`

특정 의류 아이템을 삭제합니다. 연결된 태그도 함께 삭제됩니다 (CASCADE).

> [!WARNING]
> 이미지 파일(로컬 스토리지)은 현재 자동 삭제되지 않습니다. DB 레코드만 삭제됩니다.

**Request**

```
DELETE http://localhost:8000/clothing/{cloth_id}?user_id={user_id}
```

| 파라미터 | 위치 | 타입 | 필수 | 설명 |
|---------|------|------|------|------|
| `cloth_id` | Path | `integer` | ✅ | 삭제할 의류 ID |
| `user_id` | Query | `integer` | ✅ | 소유자 확인용 사용자 ID |

**Flutter 예시 코드**

```dart
Future<void> deleteClothing(int clothId, int userId) async {
  final response = await http.delete(
    Uri.parse('$baseUrl/clothing/$clothId?user_id=$userId'),
  );
  if (response.statusCode == 204) return;
  if (response.statusCode == 404) {
    throw Exception('의류를 찾을 수 없습니다.');
  }
  throw Exception('삭제 실패: ${response.statusCode}');
}
```

**Response** `204 No Content`

응답 본문 없음.

**Error Responses**

| HTTP 코드 | 발생 조건 |
|-----------|----------|
| `404 Not Found` | `cloth_id`가 존재하지 않거나 해당 `user_id`의 것이 아님 |

---

## 5. 이미지 파일 접근

서버는 로컬 저장소의 이미지를 정적 파일로 서빙합니다.  
`ClothingItem`의 `image_url`, `original_image_url` 값을 Base URL에 붙여 접근합니다.

**이미지 URL 접근 규칙**

```
전체 이미지 URL = {Base URL}/{image_url 필드값}
```

**예시**

| 필드 값 | 전체 접근 URL |
|---------|--------------|
| `storage/crops/abc123_0.jpg` | `http://localhost:8000/storage/crops/abc123_0.jpg` |
| `storage/originals/abc123.jpg` | `http://localhost:8000/storage/originals/abc123.jpg` |

**Flutter `Image.network` 사용 예시**

```dart
Image.network(
  '$baseUrl/${clothing.imageUrl}',
  fit: BoxFit.cover,
  errorBuilder: (context, error, stackTrace) =>
      const Icon(Icons.broken_image),
)
```

---

## 6. 에러 코드 정리

| HTTP 코드 | 의미 | 주요 발생 상황 |
|-----------|------|--------------|
| `200 OK` | 성공 | GET 요청 성공 |
| `202 Accepted` | 비동기 수락 | 이미지 업로드 성공, 처리 중 |
| `204 No Content` | 삭제 성공 | DELETE 요청 성공 |
| `404 Not Found` | 리소스 없음 | 존재하지 않는 cloth_id, task_id |
| `413 Request Entity Too Large` | 파일 크기 초과 | 10MB 초과 이미지 업로드 |
| `415 Unsupported Media Type` | 지원 안 되는 형식 | GIF, BMP 등 업로드 시도 |
| `422 Unprocessable Entity` | 유효성 실패 | 필수 파라미터 누락 |
| `500 Internal Server Error` | 서버 오류 | 예기치 못한 서버 내부 오류 |

---

## 7. Flutter 연동 흐름 (Sequence)

### 의류 등록 전체 흐름

```
Flutter App                       FastAPI Backend
    │                                   │
    │── POST /clothing/upload ──────────▶│
    │   (multipart: file + user_id)      │  즉시 task_id 반환
    │◀─────────────────────────────── 202│  파이프라인 BackgroundTask 등록
    │   { task_id: "abc123" }            │
    │                                   │  [Background] 1. 전처리
    │── GET /pipeline/status/abc123 ────▶│  [Background] 2. 객체 탐지
    │◀─────────────────────────── 200   │  [Background] 3. 메타데이터 태깅
    │   { status: "processing" }         │  [Background] 4. DB 저장
    │                                   │
    │   (2초 후 재폴링)                   │
    │── GET /pipeline/status/abc123 ────▶│
    │◀─────────────────────────── 200   │
    │   { status: "done",                │
    │     clothing_ids: [1, 2] }         │
    │                                   │
    │── GET /clothing/1?user_id=1 ──────▶│
    │◀─────────────────────────── 200   │
    │   { cloth_id: 1, tags: [...] }     │
    │                                   │
```

---

## 8. 공통 데이터 타입 정의

Flutter 모델 클래스 작성 참고용입니다.

### `ClothingItem`

```dart
class ClothingItem {
  final int clothId;
  final int userId;
  final String imageUrl;         // 크롭 이미지 상대 경로
  final String? originalImageUrl; // 원본 이미지 상대 경로
  final String? category;        // 상의 | 하의 | 아우터 | 원피스 | 신발
  final String? subCategory;     // 셔츠 | 후드티 | 슬랙스 | 패딩 등
  final String? pattern;         // 무지 | 스트라이프 | 체크 | 플로럴 등
  final String pipelineStatus;   // pending | processing | done | failed
  final List<TagItem> tags;
  final DateTime createdAt;

  // 태그를 타입별로 그룹핑하는 편의 getter
  List<String> get colors =>
      tags.where((t) => t.tagType == 'color').map((t) => t.tagValue).toList();
  List<String> get materials =>
      tags.where((t) => t.tagType == 'material').map((t) => t.tagValue).toList();
  List<String> get styles =>
      tags.where((t) => t.tagType == 'style').map((t) => t.tagValue).toList();
  List<String> get seasons =>
      tags.where((t) => t.tagType == 'season').map((t) => t.tagValue).toList();

  // 이미지 전체 URL 조합 (baseUrl 주입 필요)
  String fullImageUrl(String baseUrl) => '$baseUrl/$imageUrl';
}
```

### `TagItem`

```dart
class TagItem {
  final String tagType;   // color | material | style | season | (확장 필드명)
  final String tagValue;  // Black | Cotton | Casual | Spring | ...
}
```

### `UploadResponse`

```dart
class UploadResponse {
  final String taskId;
  final String status;   // 항상 "pending"
  final String message;
}
```

### `PipelineStatusResponse`

```dart
class PipelineStatusResponse {
  final String taskId;
  final String status;        // pending | processing | done | failed
  final List<int> clothingIds; // done 상태일 때 채워짐
  final String? error;        // failed 상태일 때 채워짐
  final String message;
}
```

### `tag_type` 값 목록

| `tag_type` | 의미 | `tag_value` 예시 |
|------------|------|-----------------|
| `color` | 색상 | `Black`, `White`, `Navy`, `Gray`, `Beige` |
| `material` | 소재 | `Cotton`, `Denim`, `Polyester`, `Wool`, `Linen` |
| `style` | 스타일 | `Casual`, `Minimal`, `Street`, `Formal`, `Sporty` |
| `season` | 계절 | `Spring`, `Summer`, `Autumn`, `Winter` |

> [!NOTE]
> 모델 확정 후 `tag_type` 값이 추가될 수 있습니다. Flutter 앱은 알 수 없는 `tag_type`을 무시하거나 `기타` 카테고리로 표시하는 방어 코드를 추가해 두세요.

---

*마지막 업데이트: 2026-05-24*  
*API 버전: v0.1.0*
