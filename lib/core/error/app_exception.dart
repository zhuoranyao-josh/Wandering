class AppException implements Exception {
  // 这里不用直接存中文/英文文案，而是存“错误码”
  // UI 层再根据错误码翻译成当前语言的提示文字
  final String code;

  AppException(this.code);

  @override
  String toString() => code;
}
