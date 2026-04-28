class AdminActivity {
  const AdminActivity({
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
    required this.placeId,
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
  final String? placeId;

  String localizedTitle(String languageCode) => _localizedText(title, languageCode);

  String localizedCityName(String languageCode) => _localizedText(cityName, languageCode);

  String localizedCountryName(String languageCode) => _localizedText(countryName, languageCode);

  String localizedDetailText(String languageCode) => _localizedText(detailText, languageCode);

  String get categoryLabel => categories.join(', ');

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

  AdminActivity copyWith({
    String? id,
    Map<String, String>? title,
    List<String>? categories,
    Map<String, String>? cityName,
    Map<String, String>? countryName,
    String? cityCode,
    String? coverImageUrl,
    DateTime? startAt,
    DateTime? endAt,
    bool? isPublished,
    bool? isFeatured,
    Map<String, String>? detailText,
    String? placeId,
  }) {
    return AdminActivity(
      id: id ?? this.id,
      title: title ?? this.title,
      categories: categories ?? this.categories,
      cityName: cityName ?? this.cityName,
      countryName: countryName ?? this.countryName,
      cityCode: cityCode ?? this.cityCode,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      startAt: startAt ?? this.startAt,
      endAt: endAt ?? this.endAt,
      isPublished: isPublished ?? this.isPublished,
      isFeatured: isFeatured ?? this.isFeatured,
      detailText: detailText ?? this.detailText,
      placeId: placeId ?? this.placeId,
    );
  }
}
