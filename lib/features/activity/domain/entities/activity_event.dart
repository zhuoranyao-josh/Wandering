class ActivityEvent {
  const ActivityEvent({
    required this.id,
    required this.title,
    required this.categories,
    required this.cityName,
    required this.countryName,
    required this.cityCode,
    required this.coverImageUrl,
    required this.startAt,
    required this.endAt,
    required this.isPublished,
    required this.isFeatured,
    required this.detailText,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final Map<String, String> title;
  final List<String> categories;
  final Map<String, String> cityName;
  final Map<String, String> countryName;
  final String cityCode;
  final String coverImageUrl;
  final DateTime? startAt;
  final DateTime? endAt;
  final bool isPublished;
  final bool isFeatured;
  final Map<String, String> detailText;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // 长期开放型活动可能没有明确开始或结束时间。
  bool get isAlwaysOpen => startAt == null && endAt == null;

  bool get isOpenEnded => startAt != null && endAt == null;

  String localizedTitle(String languageCode) => _localizedText(title, languageCode);

  String localizedDetailText(String languageCode) =>
      _localizedText(detailText, languageCode);

  String localizedLocationLabel(String languageCode) {
    final city = _localizedText(cityName, languageCode);
    final country = _localizedText(countryName, languageCode);
    if (city.isEmpty && country.isEmpty) {
      return '';
    }
    if (city.isEmpty) {
      return country;
    }
    if (country.isEmpty) {
      return city;
    }
    return '$city, $country';
  }

  Iterable<String> get searchableTexts sync* {
    for (final value in title.values) {
      final trimmed = value.trim();
      if (trimmed.isNotEmpty) {
        yield trimmed;
      }
    }
    for (final value in cityName.values) {
      final trimmed = value.trim();
      if (trimmed.isNotEmpty) {
        yield trimmed;
      }
    }
  }

  String _localizedText(Map<String, String> map, String languageCode) {
    final isZh = languageCode.toLowerCase().startsWith('zh');
    final zh = map['zh']?.trim() ?? '';
    final en = map['en']?.trim() ?? '';
    if (isZh) {
      if (zh.isNotEmpty) {
        return zh;
      }
      if (en.isNotEmpty) {
        return en;
      }
    } else {
      if (en.isNotEmpty) {
        return en;
      }
      if (zh.isNotEmpty) {
        return zh;
      }
    }
    return '';
  }
}
