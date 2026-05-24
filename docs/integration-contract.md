# Frontend Integration Contract

This file defines what the Flutter frontend expects from backend and AI teammates.

## Clothing Item

```json
{
  "id": "item_123",
  "imageUrl": "https://example.com/item.jpg",
  "category": "outerwear",
  "subcategory": "blazer",
  "colors": ["black"],
  "materials": ["wool"],
  "patterns": ["solid"],
  "seasons": ["fall", "winter"],
  "occasions": ["formal", "daily"],
  "tags": ["minimal", "warm"],
  "confidence": 0.91,
  "createdAt": "2026-05-24T09:00:00Z",
  "updatedAt": "2026-05-24T09:00:00Z"
}
```

## Endpoints Needed

### Upload And Classify

`POST /items/classify`

Request:

- Multipart image file.

Response:

```json
{
  "draftId": "draft_123",
  "imageUrl": "https://example.com/item.jpg",
  "prediction": {
    "category": "top",
    "subcategory": "shirt",
    "colors": ["white"],
    "materials": ["cotton"],
    "patterns": ["solid"],
    "seasons": ["spring", "summer"],
    "occasions": ["daily"],
    "tags": ["basic", "clean"],
    "confidence": 0.88
  }
}
```

### Save Reviewed Item

`POST /items`

Request: reviewed item metadata.

Response: saved clothing item.

### List Closet

`GET /items?category=&color=&season=&occasion=`

Response: list of clothing items.

### Item Detail

`GET /items/{id}`

Response: clothing item.

### Update Item

`PATCH /items/{id}`

Request: edited metadata fields.

Response: updated clothing item.

### Ask Closet

`POST /assistant/ask`

Request:

```json
{
  "question": "내일 발표 때 입을 옷 추천해줘",
  "context": {
    "weather": "optional",
    "occasion": "presentation",
    "excludedItemIds": []
  }
}
```

Response:

```json
{
  "answer": "검정 블레이저와 흰 셔츠 조합을 추천해요...",
  "outfits": [
    {
      "id": "outfit_123",
      "itemIds": ["item_1", "item_2", "item_3"],
      "reason": "단정하고 대비가 좋아 발표 상황에 적합합니다."
    }
  ]
}
```

## Frontend Requirements

- All AI predictions must be editable before save.
- API errors must show retry actions.
- Long classification should show progress and preserve the captured image.
- Chat answers should cite item names or thumbnails, not only text.

