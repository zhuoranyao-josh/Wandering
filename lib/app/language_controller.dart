import 'package:flutter/material.dart';

class LanguageController extends ChangeNotifier {
  Locale _locale = const Locale('en');

  Locale get locale => _locale;

  // 根据系统语言初始化
  void initFromSystem(Locale systemLocale) {
    if (systemLocale.languageCode.toLowerCase().startsWith('zh')) {
      _locale = const Locale('zh');
    } else {
      _locale = const Locale('en');
    }
  }

  // 手动切换中英文
  void toggle() {
    if (_locale.languageCode == 'zh') {
      _locale = const Locale('en');
    } else {
      _locale = const Locale('zh');
    }
    notifyListeners();
  }
}
