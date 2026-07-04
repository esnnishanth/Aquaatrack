import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  static const _key = 'language_code';
  String _locale = 'en';

  String get locale => _locale;

  LanguageProvider() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _locale = prefs.getString(_key) ?? 'en';
    notifyListeners();
  }

  Future<void> setLocale(String code) async {
    _locale = code;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, code);
    notifyListeners();
  }
}
