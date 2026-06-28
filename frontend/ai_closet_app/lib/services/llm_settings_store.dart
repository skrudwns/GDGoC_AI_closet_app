import 'package:shared_preferences/shared_preferences.dart';

class LlmSettingsStore {
  static const _geminiApiKeyKey = 'gemini_api_key';

  Future<String> loadGeminiApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_geminiApiKeyKey) ?? '';
  }

  Future<void> saveGeminiApiKey(String apiKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_geminiApiKeyKey, apiKey.trim());
  }
}
