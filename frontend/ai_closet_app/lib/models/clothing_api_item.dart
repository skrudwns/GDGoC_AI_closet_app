/// 백엔드 ClothingResponse JSON을 Dart로 매핑하는 모델
class TagItem {
  const TagItem({required this.tagType, required this.tagValue});

  final String tagType;
  final String tagValue;

  factory TagItem.fromJson(Map<String, dynamic> json) => TagItem(
        tagType: json['tag_type'] as String,
        tagValue: json['tag_value'] as String,
      );
}

class ClothingApiItem {
  const ClothingApiItem({
    required this.clothId,
    required this.userId,
    required this.imageUrl,
    this.originalImageUrl,
    this.category,
    this.subCategory,
    this.pattern,
    required this.pipelineStatus,
    this.confidence,
    required this.tags,
    required this.createdAt,
  });

  final int clothId;
  final int userId;

  /// "storage/crops/xxx.jpg" 형식 — baseUrl과 조합하여 사용
  final String imageUrl;
  final String? originalImageUrl;

  final String? category;
  final String? subCategory;
  final String? pattern;
  final String pipelineStatus;

  /// YOLOS 탐지 신뢰도 (0.0 ~ 1.0)
  final double? confidence;
  final List<TagItem> tags;
  final DateTime createdAt;

  factory ClothingApiItem.fromJson(Map<String, dynamic> json) {
    return ClothingApiItem(
      clothId: json['cloth_id'] as int,
      userId: json['user_id'] as int,
      imageUrl: json['image_url'] as String,
      originalImageUrl: json['original_image_url'] as String?,
      category: json['category'] as String?,
      subCategory: json['sub_category'] as String?,
      pattern: json['pattern'] as String?,
      pipelineStatus: json['pipeline_status'] as String,
      confidence: (json['confidence'] as num?)?.toDouble(),
      tags: (json['tags'] as List<dynamic>)
          .map((t) => TagItem.fromJson(t as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  /// tag_type으로 태그 값 목록 추출
  List<String> tagValues(String tagType) => tags
      .where((t) => t.tagType == tagType && t.tagType != 'detection_confidence')
      .map((t) => t.tagValue)
      .toList();

  /// 표시용 이름: sub_category 우선, 없으면 category
  String get displayName => subCategory ?? category ?? '의류';

  /// 표시용 카테고리 라벨
  String get categoryLabel => category ?? '-';

  /// confidence 백분율 문자열 (예: "92%")
  String? get confidenceLabel {
    if (confidence == null) return null;
    return '${(confidence! * 100).round()}%';
  }
}

class ClothingListResponse {
  const ClothingListResponse({required this.total, required this.items});

  final int total;
  final List<ClothingApiItem> items;

  factory ClothingListResponse.fromJson(Map<String, dynamic> json) =>
      ClothingListResponse(
        total: json['total'] as int,
        items: (json['items'] as List<dynamic>)
            .map((i) => ClothingApiItem.fromJson(i as Map<String, dynamic>))
            .toList(),
      );
}

class PipelineStatus {
  const PipelineStatus({
    required this.taskId,
    required this.status,
    required this.clothingIds,
    this.error,
  });

  final String taskId;
  final String status; // pending | processing | done | failed
  final List<int> clothingIds;
  final String? error;

  bool get isDone => status == 'done';
  bool get isFailed => status == 'failed';

  factory PipelineStatus.fromJson(Map<String, dynamic> json) => PipelineStatus(
        taskId: json['task_id'] as String,
        status: json['status'] as String,
        clothingIds: (json['clothing_ids'] as List<dynamic>)
            .map((e) => e as int)
            .toList(),
        error: json['error'] as String?,
      );
}
