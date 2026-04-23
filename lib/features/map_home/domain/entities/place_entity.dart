class PlaceEntity {
  const PlaceEntity({
    required this.id,
    required this.name,
    required this.regionId,
    required this.latitude,
    required this.longitude,
    required this.coverImage,
    required this.quote,
    required this.shortDescription,
    required this.longDescription,
    required this.tags,
    required this.flyToZoom,
    required this.flyToPitch,
    required this.flyToBearing,
  });

  final String id;
  final Map<String, String> name;
  final String regionId;
  final double latitude;
  final double longitude;
  final String coverImage;
  final Map<String, String> quote;
  final Map<String, String> shortDescription;
  final Map<String, String> longDescription;
  final List<String> tags;
  final double flyToZoom;
  final double flyToPitch;
  final double flyToBearing;

  // 中文优先，英文兜底。
  String localizedName(String languageCode) {
    return _localizedText(languageCode, name);
  }

  String localizedShortDescription(String languageCode) {
    return _localizedText(languageCode, shortDescription);
  }

  String localizedLongDescription(String languageCode) {
    return _localizedText(languageCode, longDescription);
  }

  String localizedQuote(String languageCode) {
    return _localizedText(languageCode, quote);
  }

  factory PlaceEntity.fromMap(String documentId, Map<String, dynamic> json) {
    // 只支持语言 map 结构，不再兼容旧的扁平字段。
    return PlaceEntity(
      id: _readText(json['id']) ?? documentId,
      name: _readLanguageMap(json['name']),
      regionId: _readText(json['regionId']) ?? '',
      latitude: _readDouble(json['latitude']) ?? 0.0,
      longitude: _readDouble(json['longitude']) ?? 0.0,
      coverImage:
          _readText(json['coverImage']) ??
          _readText(json['previewAssetPath']) ??
          '',
      quote: _readLanguageMap(json['quote']),
      shortDescription: _readLanguageMap(json['shortDescription']),
      longDescription: _readLanguageMap(json['longDescription']),
      tags: _readTags(json['tags']),
      flyToZoom: _readDouble(json['flyToZoom']) ?? 10.8,
      flyToPitch: _readDouble(json['flyToPitch']) ?? 48.0,
      flyToBearing: _readDouble(json['flyToBearing']) ?? 12.0,
    );
  }

  factory PlaceEntity.fromJson(Map<String, dynamic> json) {
    return PlaceEntity.fromMap((json['id'] as String?) ?? '', json);
  }

  static double? _readDouble(Object? value) {
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value.trim());
    }
    return null;
  }

  static String? _readText(Object? value) {
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isNotEmpty) {
        return trimmed;
      }
    }
    return null;
  }

  static Map<String, String> _readLanguageMap(Object? value) {
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

  static String? _normalizeLanguageKey(String rawKey) {
    final normalized = rawKey.trim().toLowerCase().replaceAll('_', '-');
    if (normalized.startsWith('zh')) {
      return 'zh';
    }
    if (normalized.startsWith('en')) {
      return 'en';
    }
    return null;
  }

  static List<String> _readTags(Object? value) {
    if (value is List<dynamic>) {
      return value
          .whereType<String>()
          .map((tag) => tag.trim())
          .where((tag) => tag.isNotEmpty)
          .toList(growable: false);
    }

    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) {
        return const <String>[];
      }

      final normalized = trimmed.startsWith('[') && trimmed.endsWith(']')
          ? trimmed.substring(1, trimmed.length - 1)
          : trimmed;
      return normalized
          .split(RegExp(r'[,;，、\n\r|]+'))
          .map((tag) => tag.trim())
          .where((tag) => tag.isNotEmpty)
          .toList(growable: false);
    }

    return const <String>[];
  }

  static String _localizedText(
    String languageCode,
    Map<String, String> values,
  ) {
    final zh = values['zh']?.trim() ?? '';
    final en = values['en']?.trim() ?? '';
    final isChinese = languageCode.toLowerCase().startsWith('zh');

    if (isChinese && zh.isNotEmpty) {
      return zh;
    }
    if (en.isNotEmpty) {
      return en;
    }
    if (zh.isNotEmpty) {
      return zh;
    }
    return '';
  }
}
