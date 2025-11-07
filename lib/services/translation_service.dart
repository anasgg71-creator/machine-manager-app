import 'dart:convert';
import 'package:http/http.dart' as http;

class TranslationService {
  // Using LibreTranslate API (free and open-source)
  static const String _apiUrl = 'https://libretranslate.com/translate';

  // Cache to avoid re-translating the same messages
  static final Map<String, String> _cache = {};

  /// Translate text to target language
  /// Default target is English ('en')
  static Future<String> translate(
    String text, {
    String targetLang = 'en',
    String? sourceLang,
  }) async {
    // Create cache key
    final cacheKey = '${sourceLang ?? 'auto'}_${targetLang}_$text';

    // Check cache first
    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey]!;
    }

    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'q': text,
          'source': sourceLang ?? 'auto',
          'target': targetLang,
          'format': 'text',
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final translatedText = data['translatedText'] as String;

        // Cache the translation
        _cache[cacheKey] = translatedText;

        return translatedText;
      } else {
        print('Translation API error: ${response.statusCode} - ${response.body}');
        // Return original text on error (silently fail)
        return text;
      }
    } catch (e) {
      print('Translation error: $e');
      return text; // Return original text on error
    }
  }

  /// Detect language of text
  static Future<String?> detectLanguage(String text) async {
    try {
      final response = await http.post(
        Uri.parse('https://libretranslate.com/detect'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'q': text}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List && data.isNotEmpty) {
          return data[0]['language'] as String?;
        }
      }
    } catch (e) {
      print('Language detection error: $e');
    }
    return null;
  }

  /// Clear translation cache
  static void clearCache() {
    _cache.clear();
  }

  /// Get supported languages
  static List<Map<String, String>> getSupportedLanguages() {
    return [
      {'code': 'en', 'name': 'English'},
      {'code': 'ar', 'name': 'Arabic'},
      {'code': 'es', 'name': 'Spanish'},
      {'code': 'fr', 'name': 'French'},
      {'code': 'de', 'name': 'German'},
      {'code': 'zh', 'name': 'Chinese'},
      {'code': 'ja', 'name': 'Japanese'},
      {'code': 'ko', 'name': 'Korean'},
      {'code': 'ru', 'name': 'Russian'},
      {'code': 'pt', 'name': 'Portuguese'},
      {'code': 'it', 'name': 'Italian'},
      {'code': 'hi', 'name': 'Hindi'},
    ];
  }
}
