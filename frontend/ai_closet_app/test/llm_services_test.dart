import 'package:ai_closet_app/models/clothing_api_item.dart';
import 'package:ai_closet_app/services/gemini_client.dart';
import 'package:ai_closet_app/services/llm_settings_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('LlmSettingsStore saves and loads a Gemini API key', () async {
    SharedPreferences.setMockInitialValues({});
    final store = LlmSettingsStore();

    await store.saveGeminiApiKey('  test-key  ');

    expect(await store.loadGeminiApiKey(), 'test-key');
  });

  test('GeminiClient builds a closet-aware prompt from backend items', () {
    final prompt = GeminiClient.buildPrompt(
      question: '내일 면접에 뭐 입을까?',
      closetItems: [
        ClothingApiItem(
          clothId: 1,
          userId: 1,
          imageUrl: 'storage/crops/blazer.jpg',
          originalImageUrl: 'storage/originals/blazer.jpg',
          category: '아우터',
          subCategory: '블레이저',
          pattern: '무지',
          pipelineStatus: 'done',
          confidence: 0.92,
          tags: const [
            TagItem(tagType: 'color', tagValue: '블랙'),
            TagItem(tagType: 'material', tagValue: '울'),
            TagItem(tagType: 'style', tagValue: '포멀'),
          ],
          createdAt: DateTime.utc(2026, 6, 28),
        ),
      ],
    );

    expect(prompt, contains('내일 면접에 뭐 입을까?'));
    expect(prompt, contains('블레이저'));
    expect(prompt, contains('아우터'));
    expect(prompt, contains('블랙'));
    expect(prompt, contains('울'));
    expect(prompt, contains('포멀'));
  });
}
