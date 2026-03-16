import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleProvider extends ChangeNotifier {
  static const String _localeKey = 'app_locale';
  static const String _petVoiceLabelStyleKey = 'pet_voice_label_style';
  static const String _petVoiceLabelCustomKey = 'pet_voice_label_custom';

  static const String petVoiceStylePetSays = 'pet_says';
  static const String petVoiceStylePetVoice = 'pet_voice';
  static const String petVoiceStyleAiAnalysis = 'ai_analysis';
  static const String petVoiceStyleCustom = 'custom';

  Locale _locale = const Locale('tr', 'TR');
  String _petVoiceLabelStyle = petVoiceStylePetSays;
  String? _petVoiceLabelCustom;

  Locale get locale => _locale;
  bool get isEnglish => _locale.languageCode == 'en';
  bool get isTurkish => _locale.languageCode == 'tr';
  String get languageCode => _locale.languageCode;
  String get petVoiceLabelStyle => _petVoiceLabelStyle;
  String? get petVoiceLabelCustom => _petVoiceLabelCustom;

  LocaleProvider() {
    _loadLocale();
    _loadPetVoiceLabelPrefs();
  }

  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLocale = prefs.getString(_localeKey);
    
    if (savedLocale != null) {
      _locale = Locale(savedLocale);
    } else {
      // Auto-detect system language
      final systemLocale = WidgetsBinding.instance.platformDispatcher.locale;
      if (systemLocale.languageCode == 'tr') {
        _locale = const Locale('tr', 'TR');
      } else {
        // Default to English for all other system languages
        _locale = const Locale('en', 'US');
      }
    }
    notifyListeners();
  }

  Future<void> _loadPetVoiceLabelPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _petVoiceLabelStyle =
        prefs.getString(_petVoiceLabelStyleKey) ?? petVoiceStylePetSays;
    _petVoiceLabelCustom = prefs.getString(_petVoiceLabelCustomKey);
    notifyListeners();
  }

  Future<void> setPetVoiceLabelStyle(String value) async {
    if (_petVoiceLabelStyle == value) return;
    _petVoiceLabelStyle = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_petVoiceLabelStyleKey, value);
    notifyListeners();
  }

  Future<void> setPetVoiceLabelCustom(String? value) async {
    _petVoiceLabelCustom = value?.trim().isEmpty == true ? null : value?.trim();
    final prefs = await SharedPreferences.getInstance();
    if (_petVoiceLabelCustom == null) {
      await prefs.remove(_petVoiceLabelCustomKey);
    } else {
      await prefs.setString(_petVoiceLabelCustomKey, _petVoiceLabelCustom!);
    }
    notifyListeners();
  }

  Future<void> setLocale(Locale locale) async {
    if (_locale == locale) return;
    _locale = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, locale.languageCode);
    notifyListeners();
  }

  Future<void> toggleLocale() async {
    if (isEnglish) {
      await setLocale(const Locale('tr', 'TR'));
    } else {
      await setLocale(const Locale('en', 'US'));
    }
  }
}
