import 'package:translator/translator.dart';

/// Professional translation service for automatic message translation
/// Supports 26 languages with automatic detection and caching
class TranslationService {
  static final TranslationService _instance = TranslationService._internal();
  factory TranslationService() => _instance;
  TranslationService._internal();

  final GoogleTranslator _translator = GoogleTranslator();

  /// Supported languages with ISO 639-1 codes
  static const Map<String, String> supportedLanguages = {
    'en': 'English',
    'ar': 'Arabic',
    'es': 'Spanish',
    'fr': 'French',
    'de': 'German',
    'it': 'Italian',
    'pt': 'Portuguese',
    'ru': 'Russian',
    'zh': 'Chinese',
    'ja': 'Japanese',
    'ko': 'Korean',
    'hi': 'Hindi',
    'tr': 'Turkish',
    'nl': 'Dutch',
    'pl': 'Polish',
    'sv': 'Swedish',
    'no': 'Norwegian',
    'da': 'Danish',
    'fi': 'Finnish',
    'cs': 'Czech',
    'el': 'Greek',
    'he': 'Hebrew',
    'th': 'Thai',
    'vi': 'Vietnamese',
    'id': 'Indonesian',
    'ms': 'Malay',
  };

  /// Detect the language of a given text
  /// Returns ISO 639-1 language code
  Future<String> detectLanguage(String text) async {
    if (text.trim().isEmpty) return 'en';

    try {
      final translation = await _translator.translate(
        text,
        from: 'auto',
        to: 'en',
      );
      return translation.sourceLanguage.code;
    } catch (e) {
      print('❌ Translation Error - Language detection failed: $e');
      return 'en'; // Default to English on error
    }
  }

  /// Translate text from source language to target language
  /// Returns translated text or original text on error
  Future<String> translate({
    required String text,
    required String from,
    required String to,
  }) async {
    // Don't translate if source and target are the same
    if (from == to) return text;
    if (text.trim().isEmpty) return text;

    try {
      print('🌐 Translating from $from to $to');
      final translation = await _translator.translate(
        text,
        from: from,
        to: to,
      );
      print('✅ Translation successful');
      return translation.text;
    } catch (e) {
      print('❌ Translation Error: $e');
      return text; // Return original text on error
    }
  }

  /// Batch translate text to multiple languages
  /// Returns a map of language code to translated text
  /// Used for pre-caching translations
  Future<Map<String, String>> translateToMultiple({
    required String text,
    required String from,
    required List<String> targetLanguages,
  }) async {
    final Map<String, String> translations = {};

    for (final targetLang in targetLanguages) {
      if (targetLang == from) {
        translations[targetLang] = text;
        continue;
      }

      try {
        final translated = await translate(
          text: text,
          from: from,
          to: targetLang,
        );
        translations[targetLang] = translated;
      } catch (e) {
        print('❌ Error translating to $targetLang: $e');
        translations[targetLang] = text;
      }
    }

    return translations;
  }

  /// Get the translated message for a user's preferred language
  /// Uses cached translation if available, returns original as fallback
  String getTranslatedMessage({
    required String originalText,
    required String originalLang,
    required String preferredLang,
    Map<String, dynamic>? cachedTranslations,
  }) {
    // Return original if same language
    if (originalLang == preferredLang) return originalText;

    // Check cached translations
    if (cachedTranslations != null && cachedTranslations.containsKey(preferredLang)) {
      final cached = cachedTranslations[preferredLang];
      if (cached != null && cached.toString().isNotEmpty) {
        return cached.toString();
      }
    }

    // Return original as fallback
    return originalText;
  }

  /// Validate if a language code is supported
  bool isLanguageSupported(String langCode) {
    return supportedLanguages.containsKey(langCode);
  }

  /// Get language name from code
  String getLanguageName(String langCode) {
    return supportedLanguages[langCode] ?? 'Unknown';
  }

  /// Get flag emoji for language
  String getLanguageFlag(String langCode) {
    const Map<String, String> flagEmojis = {
      'en': '🇬🇧',
      'ar': '🇸🇦',
      'es': '🇪🇸',
      'fr': '🇫🇷',
      'de': '🇩🇪',
      'it': '🇮🇹',
      'pt': '🇵🇹',
      'ru': '🇷🇺',
      'zh': '🇨🇳',
      'ja': '🇯🇵',
      'ko': '🇰🇷',
      'hi': '🇮🇳',
      'tr': '🇹🇷',
      'nl': '🇳🇱',
      'pl': '🇵🇱',
      'sv': '🇸🇪',
      'no': '🇳🇴',
      'da': '🇩🇰',
      'fi': '🇫🇮',
      'cs': '🇨🇿',
      'el': '🇬🇷',
      'he': '🇮🇱',
      'th': '🇹🇭',
      'vi': '🇻🇳',
      'id': '🇮🇩',
      'ms': '🇲🇾',
    };
    return flagEmojis[langCode] ?? '🌐';
  }
}
