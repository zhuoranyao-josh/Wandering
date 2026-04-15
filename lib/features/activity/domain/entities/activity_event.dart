class ActivityEvent {
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
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ActivityEvent({
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
    required this.createdAt,
    required this.updatedAt,
  });

  // 长期开放型活动可能没有明确开始或结束时间。
  bool get isAlwaysOpen => startAt == null && endAt == null;

  bool get isOpenEnded => startAt != null && endAt == null;

  String get locationLabel {
    if (cityName.isEmpty && countryName.isEmpty) {
      return '';
    }
    if (cityName.isEmpty) {
      return countryName;
    }
    if (countryName.isEmpty) {
      return cityName;
    }
    return '$cityName, $countryName';
  }
}
