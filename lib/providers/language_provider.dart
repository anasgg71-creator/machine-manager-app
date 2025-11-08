import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Language {
  final String name;
  final String code;
  final String flag;

  const Language({
    required this.name,
    required this.code,
    required this.flag,
  });
}

class LanguageProvider extends ChangeNotifier {
  String _selectedLanguageCode = 'en';

  String get selectedLanguageCode => _selectedLanguageCode;
  Locale get currentLocale => Locale(_selectedLanguageCode);

  // Get current language object
  Language get currentLanguage {
    return supportedLanguages.firstWhere(
      (lang) => lang.code == _selectedLanguageCode,
      orElse: () => supportedLanguages.first,
    );
  }

  // Static list of supported languages
  static const List<Language> supportedLanguages = [
    Language(name: 'English', code: 'en', flag: '🇬🇧'),
    Language(name: 'العربية', code: 'ar', flag: '🇸🇦'),
    Language(name: 'Español', code: 'es', flag: '🇪🇸'),
    Language(name: 'Français', code: 'fr', flag: '🇫🇷'),
    Language(name: 'Deutsch', code: 'de', flag: '🇩🇪'),
    Language(name: 'Italiano', code: 'it', flag: '🇮🇹'),
    Language(name: 'Português', code: 'pt', flag: '🇵🇹'),
    Language(name: 'Русский', code: 'ru', flag: '🇷🇺'),
    Language(name: '中文', code: 'zh', flag: '🇨🇳'),
    Language(name: '日本語', code: 'ja', flag: '🇯🇵'),
    Language(name: '한국어', code: 'ko', flag: '🇰🇷'),
    Language(name: 'हिन्दी', code: 'hi', flag: '🇮🇳'),
  ];

  LanguageProvider() {
    _loadSavedLanguage();
  }

  // Load saved language preference
  Future<void> _loadSavedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLanguageCode = prefs.getString('selected_language_code');
    if (savedLanguageCode != null) {
      // Verify the language code is supported
      final isSupported = supportedLanguages.any((lang) => lang.code == savedLanguageCode);
      if (isSupported) {
        _selectedLanguageCode = savedLanguageCode;
        notifyListeners();
      }
    }
  }

  // Change language by language code and save preference
  Future<void> setLanguageByCode(String languageCode) async {
    // Verify the language code is supported
    final isSupported = supportedLanguages.any((lang) => lang.code == languageCode);
    if (isSupported) {
      _selectedLanguageCode = languageCode;

      // Save to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('selected_language_code', languageCode);

      notifyListeners();
    }
  }

  // Change language by Language object
  Future<void> setLanguage(Language language) async {
    await setLanguageByCode(language.code);
  }
}
