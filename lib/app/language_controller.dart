import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageController extends ChangeNotifier {
  static const String _languageCodeKey = 'app_language_code';

  Locale _locale = const Locale('en');

  Locale get locale => _locale;

  /// 初始化语言：
  /// 1. 优先读取本地保存的语言
  /// 2. 如果本地没有保存，再跟随系统语言
  Future<void> init(Locale systemLocale) async {
    final prefs = await SharedPreferences.getInstance();
    final savedLanguageCode = prefs.getString(_languageCodeKey);

    if (savedLanguageCode == 'zh' || savedLanguageCode == 'en') {
      _locale = Locale(savedLanguageCode!);
      return;
    }

    if (systemLocale.languageCode.toLowerCase().startsWith('zh')) {
      _locale = const Locale('zh');
    } else {
      _locale = const Locale('en');
    }
  }

  /// 用户手动设置语言并保存到本地
  Future<void> setLocaleAndSave(Locale locale) async {
    if (locale.languageCode != 'zh' && locale.languageCode != 'en') return;

    _locale = locale;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageCodeKey, locale.languageCode);
  }

  /// 切换语言并保存
  Future<void> toggleAndSave() async {
    if (_locale.languageCode == 'zh') {
      await setLocaleAndSave(const Locale('en'));
    } else {
      await setLocaleAndSave(const Locale('zh'));
    }
  }
}
