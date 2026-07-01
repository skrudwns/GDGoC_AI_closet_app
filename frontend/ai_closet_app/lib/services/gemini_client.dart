import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/clothing_api_item.dart';

class GeminiClient {
  GeminiClient({
    required this.apiKey,
    http.Client? httpClient,
  }) : _httpClient = httpClient ?? http.Client();

  final String apiKey;
  final http.Client _httpClient;

  static const _models = ['gemini-2.5-flash', 'gemini-2.0-flash'];
  static const _maxRetries = 2;

  Future<String> askCloset({
    required String question,
    required List<ClothingApiItem> closetItems,
    String? weatherInfo,
    ClothingApiItem? targetItem,
  }) async {
    final trimmedKey = apiKey.trim();
    if (trimmedKey.isEmpty) {
      throw const GeminiException('Gemini API 키를 설정해주세요.');
    }

    final prompt = buildPrompt(
      question: question,
      closetItems: closetItems,
      weatherInfo: weatherInfo,
      targetItem: targetItem,
    );

    // 모델 목록을 순회하며 시도, 각 모델별로 재시도
    for (final model in _models) {
      for (var attempt = 0; attempt <= _maxRetries; attempt++) {
        final uri = Uri.https(
          'generativelanguage.googleapis.com',
          '/v1beta/models/$model:generateContent',
          {'key': trimmedKey},
        );

        final response = await _httpClient.post(
          uri,
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode({
            'contents': [
              {
                'role': 'user',
                'parts': [{'text': prompt}],
              },
            ],
            'generationConfig': {
              'temperature': 0.7,
              'maxOutputTokens': 8192,
              'responseMimeType': 'application/json',
            },
          }),
        );

        if (response.statusCode >= 200 && response.statusCode < 300) {
          return _parseResponse(response.body);
        }

        // 재시도 가능한 에러 (503 서버 과부하, 429 요청 제한)
        if ((response.statusCode == 503 || response.statusCode == 429) &&
            attempt < _maxRetries) {
          await Future.delayed(Duration(seconds: (attempt + 1) * 2));
          continue;
        }

        // 해당 모델 실패 → 다음 모델로 시도
        if (response.statusCode == 503 || response.statusCode == 429 ||
            response.statusCode == 404) {
          break; // 다음 모델 시도
        }

        // 그 외 에러는 즉시 종료
        throw GeminiException(_friendlyError(response.statusCode));
      }
    }

    // 모든 모델 실패
    throw const GeminiException(
      'Gemini 서버가 현재 혼잡합니다. 잠시 후 다시 시도해주세요.',
    );
  }

  String _parseResponse(String body) {

    final data = jsonDecode(body) as Map<String, dynamic>;
    final candidates = data['candidates'] as List<dynamic>? ?? [];
    if (candidates.isEmpty) {
      throw const GeminiException('Gemini 응답이 비어있어요.');
    }

    final finishReason = candidates.first['finishReason'];
    print('Gemini finishReason: $finishReason');
    
    final content = candidates.first as Map<String, dynamic>;
    final parts = (content['content'] as Map<String, dynamic>?)?['parts']
            as List<dynamic>? ??
        [];
    final text = parts
        .map((part) => (part as Map<String, dynamic>)['text'])
        .whereType<String>()
        .join('\n')
        .trim();

    print('Gemini API Response:\n$text');
    return text;
  }

  static String buildPrompt({
    required String question,
    required List<ClothingApiItem> closetItems,
    String? weatherInfo,
    ClothingApiItem? targetItem,
  }) {
    final closetSummary = closetItems.isEmpty
        ? '저장된 옷이 아직 없습니다.'
        : closetItems.map(_summarizeItem).join('\n');

    final weatherSection = weatherInfo != null
        ? '''
[현재 날씨 정보]
$weatherInfo

날씨와 온도에 어울리는 적합한 두께와 계절감의 코디 조합을 만들어 주세요.
'''
        : '';

    final targetSection = targetItem != null
        ? '\n[절대 규칙 - 필수 포함 아이템]\n사용자가 특정 옷을 필수로 포함하도록 지정했습니다. 무슨 일이 있어도 반드시 cloth_id가 ${targetItem.clothId}인 옷(${targetItem.displayName})을 item_ids에 포함해야 합니다. 사용자의 질문 내용과 어울리지 않더라도 무조건 포함해서 답변을 구성하세요.\n'
        : '';

    return '''
사용자의 옷장 데이터로 코디를 추천하는 스타일 어시스턴트입니다. 오직 JSON만 반환하세요.

[규칙]
1. 추천은 정확히 1개만 생성하세요.
2. [저장된 옷장]에 존재하는 실제 cloth_id 값만 item_ids 정수 배열에 포함하세요.
3. reason은 1~2문장으로 간결하게 작성하세요.
4. tip은 1문장으로 짧게 작성하세요.
$targetSection

$weatherSection
[질문] $question

[저장된 옷장]
$closetSummary

[JSON 형식]
{"recommendations":[{"name":"코디명","item_ids":[1,2],"reason":"추천이유","tip":"스타일링팁"}]}
''';
  }

  static String _summarizeItem(ClothingApiItem item) {
    final tags = item.tags
        .where((tag) => tag.tagType != 'detection_confidence')
        .map((tag) => '${tag.tagType}:${tag.tagValue}')
        .join(', ');
    return 'cloth_id: ${item.clothId} - ${item.displayName} (${item.categoryLabel}, 패턴 ${item.pattern ?? '미상'}, 태그: ${tags.isEmpty ? '없음' : tags})';
  }

  static String _friendlyError(int statusCode) {
    switch (statusCode) {
      case 400:
        return '요청 형식에 문제가 있어요. 질문을 다시 작성해보세요.';
      case 401:
      case 403:
        return 'API 키가 유효하지 않거나 권한이 없습니다. 설정에서 확인해주세요.';
      case 429:
        return '요청이 너무 많습니다. 잠시 후 다시 시도해주세요.';
      case 503:
        return 'Gemini 서버가 현재 혼잡합니다. 잠시 후 다시 시도해주세요.';
      default:
        return 'Gemini 요청에 실패했어요 (오류 $statusCode). 잠시 후 다시 시도해주세요.';
    }
  }
}

class GeminiException implements Exception {
  const GeminiException(this.message);

  final String message;

  @override
  String toString() => message;
}
