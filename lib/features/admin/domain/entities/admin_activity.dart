class AdminActivity {
  const AdminActivity({
    required this.id,
    required this.title,
    required this.category,
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
  final String title;
  final String category;
  final String cityName;
  final String countryName;
  final String cityCode;
  final String coverImageUrl;
  final DateTime? startAt;
  final DateTime? endAt;
  final bool isPublished;
  final bool isFeatured;
  final String detailText;
  final String? placeId;

  AdminActivity copyWith({
    String? id,
    String? title,
    String? category,
    String? cityName,
    String? countryName,
    String? cityCode,
    String? coverImageUrl,
    DateTime? startAt,
    DateTime? endAt,
    bool? isPublished,
    bool? isFeatured,
    String? detailText,
    String? placeId,
  }) {
    return AdminActivity(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
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
