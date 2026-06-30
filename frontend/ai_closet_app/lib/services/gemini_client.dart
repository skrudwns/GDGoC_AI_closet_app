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

  static const _model = 'gemini-1.5-flash';

  Future<String> askCloset({
    required String question,
    required List<ClothingApiItem> closetItems,
  }) async {
    final trimmedKey = apiKey.trim();
    if (trimmedKey.isEmpty) {
      throw const GeminiException('Gemini API 키를 설정해주세요.');
    }

    final uri = Uri.https(
      'generativelanguage.googleapis.com',
      '/v1beta/models/$_model:generateContent',
      {'key': trimmedKey},
    );
    final response = await _httpClient.post(
      uri,
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': [
          {
            'role': 'user',
            'parts': [
              {
                'text':
                    buildPrompt(question: question, closetItems: closetItems)
              },
            ],
          },
        ],
        'generationConfig': {
          'temperature': 0.7,
          'maxOutputTokens': 700,
        },
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw GeminiException(
          'Gemini 요청 실패 (${response.statusCode}): ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final candidates = data['candidates'] as List<dynamic>? ?? [];
    if (candidates.isEmpty) {
      throw const GeminiException('Gemini 응답이 비어있어요.');
    }

    final content = candidates.first as Map<String, dynamic>;
    final parts = (content['content'] as Map<String, dynamic>?)?['parts']
            as List<dynamic>? ??
        [];
    final text = parts
        .map((part) => (part as Map<String, dynamic>)['text'])
        .whereType<String>()
        .join('\n')
        .trim();

    if (text.isEmpty) {
      throw const GeminiException('Gemini가 텍스트 답변을 반환하지 않았어요.');
    }
    return text;
  }

  static String buildPrompt({
    required String question,
    required List<ClothingApiItem> closetItems,
  }) {
    final closetSummary = closetItems.isEmpty
        ? '저장된 옷이 아직 없습니다.'
        : closetItems.map(_summarizeItem).join('\n');

    return '''
당신은 사용자의 실제 옷장 데이터를 바탕으로 현실적인 코디를 추천하는 스타일 어시스턴트입니다.
답변은 한국어로, 친근하지만 간결하게 작성하세요.
옷장에 없는 옷을 새로 사라고 하기보다 저장된 옷을 우선 조합하세요.
확실하지 않은 정보는 단정하지 말고 대안을 제시하세요.

[사용자 질문]
$question

[저장된 옷장]
$closetSummary

[답변 형식]
1. 추천 조합
2. 추천 이유
3. 상황별 조정 팁
''';
  }

  static String _summarizeItem(ClothingApiItem item) {
    final tags = item.tags
        .where((tag) => tag.tagType != 'detection_confidence')
        .map((tag) => '${tag.tagType}:${tag.tagValue}')
        .join(', ');
    final confidence =
        item.confidenceLabel == null ? '' : ', AI 신뢰도 ${item.confidenceLabel}';
    return '- ${item.displayName} (${item.categoryLabel}, 패턴 ${item.pattern ?? '미상'}$confidence, 태그: ${tags.isEmpty ? '없음' : tags})';
  }
}

class GeminiException implements Exception {
  const GeminiException(this.message);

  final String message;

  @override
  String toString() => message;
}
