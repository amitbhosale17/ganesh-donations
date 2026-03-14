import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageService extends ChangeNotifier {
  Locale? _locale;
  bool _isLanguageSelected = false;

  Locale? get locale => _locale;
  bool get isLanguageSelected => _isLanguageSelected;

  LanguageService() {
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString('language_code');
    final isSelected = prefs.getBool('language_selected') ?? false;
    
    if (languageCode != null) {
      _locale = Locale(languageCode);
    }
    _isLanguageSelected = isSelected;
    notifyListeners();
  }

  Future<void> setLocale(Locale locale) async {
    if (_locale == locale) return;

    _locale = locale;
    _isLanguageSelected = true;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', locale.languageCode);
    await prefs.setBool('language_selected', true);
    
    notifyListeners();
  }

  Future<void> clearLocale() async {
    _locale = null;
    _isLanguageSelected = false;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('language_code');
    await prefs.remove('language_selected');
    
    notifyListeners();
  }
}
