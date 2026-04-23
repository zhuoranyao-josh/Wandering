import 'dart:convert';

String? readTrimmedString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is String) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
  return null;
}

double? readDouble(Object? value) {
  if (value is num) {
    return value.toDouble();
  }
  if (value is String) {
    return double.tryParse(value.trim());
  }
  return null;
}

Map<String, String> readLanguageMap(Object? value) {
  if (value is! Map) {
    return const <String, String>{};
  }

  final result = <String, String>{};
  for (final entry in value.entries) {
    final key = _normalizeLanguageKey(entry.key.toString());
    final rawValue = entry.value;
    if (key != null && rawValue is String) {
      final trimmed = rawValue.trim();
      if (trimmed.isNotEmpty) {
        result[key] = trimmed;
      }
    }
  }
  return Map<String, String>.unmodifiable(result);
}

String? _normalizeLanguageKey(String rawKey) {
  final normalized = rawKey.trim().toLowerCase().replaceAll('_', '-');
  if (normalized.startsWith('zh')) {
    return 'zh';
  }
  if (normalized.startsWith('en')) {
    return 'en';
  }
  return null;
}

List<String> readStringList(Object? value) {
  if (value is List<dynamic>) {
    return value
        .whereType<String>()
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }

  if (value is String) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return const <String>[];
    }

    if (trimmed.startsWith('[') && trimmed.endsWith(']')) {
      try {
        final decoded = jsonDecode(trimmed);
        if (decoded is List) {
          return decoded
              .whereType<String>()
              .map((item) => item.trim())
              .where((item) => item.isNotEmpty)
              .toList(growable: false);
        }
      } catch (_) {
        // 继续按分隔符兜底解析。
      }
    }

    return trimmed
        .split(RegExp(r'[,;，、\n\r|]+'))
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }

  return const <String>[];
}
