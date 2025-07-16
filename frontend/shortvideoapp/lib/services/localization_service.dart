import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppLanguage {
  english('en', 'English', '🇺🇸'),
  italian('it', 'Italiano', '🇮🇹'),
  french('fr', 'Français', '🇫🇷');

  const AppLanguage(this.code, this.name, this.flag);

  final String code;
  final String name;
  final String flag;

  static AppLanguage fromCode(String code) {
    switch (code) {
      case 'en':
        return AppLanguage.english;
      case 'it':
        return AppLanguage.italian;
      case 'fr':
        return AppLanguage.french;
      default:
        return AppLanguage.english;
    }
  }
}

class LocalizationService extends ChangeNotifier {
  static final LocalizationService _instance = LocalizationService._internal();
  factory LocalizationService() => _instance;
  LocalizationService._internal();

  static const String _languageKey = 'selected_language';
  static AppLanguage _currentLanguage = AppLanguage.english;

  static AppLanguage get currentLanguage => _currentLanguage;

  static String translate(Map<AppLanguage, String> translations) {
    return translations[_currentLanguage] ??
        translations[AppLanguage.english] ??
        '';
  }

  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLanguage = prefs.getString(_languageKey) ?? 'en';
    _currentLanguage = AppLanguage.fromCode(savedLanguage);
  }

  static Future<void> changeLanguage(AppLanguage language) async {
    if (_currentLanguage == language) return;

    _currentLanguage = language;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, language.code);

    // Notify all listeners that the language has changed
    _instance.notifyListeners();
  }

  static List<AppLanguage> get supportedLanguages => AppLanguage.values;
}
