import 'checklist_destination_snapshot.dart';

class ChecklistItem {
  const ChecklistItem({
    required this.id,
    required this.destination,
    this.placeId,
    required this.coverImageUrl,
    this.destinationNames = const <String, String>{},
    this.destinationSourceType,
    this.destinationSnapshot,
    this.departureCity,
    this.departureCountry,
    this.departureLatitude,
    this.departureLongitude,
    this.departureSource,
    this.startDate,
    this.endDate,
    this.tripDays,
    this.nightCount,
    this.travelerCount,
    this.totalBudget,
    this.currency,
    this.preferences = const <String>[],
    this.pace,
    this.accommodationPreference,
    this.basicInfoCompleted = false,
    this.statusText,
  });

  final String id;
  final String destination;
  final String? placeId;
  final String coverImageUrl;
  final Map<String, String> destinationNames;
  final String? destinationSourceType;
  final ChecklistDestinationSnapshot? destinationSnapshot;
  final String? departureCity;
  final String? departureCountry;
  final double? departureLatitude;
  final double? departureLongitude;
  final String? departureSource;
  final DateTime? startDate;
  final DateTime? endDate;
  final int? tripDays;
  final int? nightCount;
  final int? travelerCount;
  final double? totalBudget;
  final String? currency;
  final List<String> preferences;
  final String? pace;
  final String? accommodationPreference;
  final bool basicInfoCompleted;
  final String? statusText;

  // Journey Wizard 入口分流规则：只有基础字段完整时才允许直达详情页。
  bool get isBasicInfoComplete {
    return hasValidDestination &&
        startDate != null &&
        endDate != null &&
        (departureCity?.trim().isNotEmpty ?? false) &&
        (totalBudget ?? 0) > 0 &&
        (currency?.trim().isNotEmpty ?? false) &&
        (travelerCount ?? 0) > 0 &&
        (pace?.trim().isNotEmpty ?? false) &&
        (accommodationPreference?.trim().isNotEmpty ?? false) &&
        preferences.isNotEmpty;
  }

  bool get hasValidDestination => destinationSnapshot?.hasCoreData ?? false;

  String get resolvedDestinationName {
    final snapshotName = destinationSnapshot?.name.trim() ?? '';
    if (snapshotName.isNotEmpty) {
      return snapshotName;
    }
    return destination.trim();
  }

  String resolveDestinationNameByLocale(String languageCode) {
    final normalizedLanguage = languageCode.toLowerCase();
    final preferredKey = normalizedLanguage.startsWith('zh') ? 'zh' : 'en';
    final fallbackKey = preferredKey == 'zh' ? 'en' : 'zh';

    // 列表展示优先读多语言名称，确保切换语言时地点名称同步变化。
    final preferred = destinationNames[preferredKey]?.trim() ?? '';
    if (preferred.isNotEmpty) {
      return preferred;
    }

    final fallback = destinationNames[fallbackKey]?.trim() ?? '';
    if (fallback.isNotEmpty) {
      return fallback;
    }

    return resolvedDestinationName;
  }

  String get resolvedCoverImageUrl {
    final snapshotImage = destinationSnapshot?.coverImageUrl?.trim() ?? '';
    if (snapshotImage.isNotEmpty) {
      return snapshotImage;
    }
    return coverImageUrl.trim();
  }

  double? get resolvedLatitude => destinationSnapshot?.latitude;

  double? get resolvedLongitude => destinationSnapshot?.longitude;

  ChecklistItem copyWith({
    String? id,
    String? destination,
    String? placeId,
    String? coverImageUrl,
    Map<String, String>? destinationNames,
    String? destinationSourceType,
    ChecklistDestinationSnapshot? destinationSnapshot,
    String? departureCity,
    String? departureCountry,
    double? departureLatitude,
    double? departureLongitude,
    String? departureSource,
    DateTime? startDate,
    DateTime? endDate,
    int? tripDays,
    int? nightCount,
    int? travelerCount,
    double? totalBudget,
    String? currency,
    List<String>? preferences,
    String? pace,
    String? accommodationPreference,
    bool? basicInfoCompleted,
    String? statusText,
  }) {
    return ChecklistItem(
      id: id ?? this.id,
      destination: destination ?? this.destination,
      placeId: placeId ?? this.placeId,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      destinationNames: destinationNames ?? this.destinationNames,
      destinationSourceType:
          destinationSourceType ?? this.destinationSourceType,
      destinationSnapshot: destinationSnapshot ?? this.destinationSnapshot,
      departureCity: departureCity ?? this.departureCity,
      departureCountry: departureCountry ?? this.departureCountry,
      departureLatitude: departureLatitude ?? this.departureLatitude,
      departureLongitude: departureLongitude ?? this.departureLongitude,
      departureSource: departureSource ?? this.departureSource,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      tripDays: tripDays ?? this.tripDays,
      nightCount: nightCount ?? this.nightCount,
      travelerCount: travelerCount ?? this.travelerCount,
      totalBudget: totalBudget ?? this.totalBudget,
      currency: currency ?? this.currency,
      preferences: preferences ?? this.preferences,
      pace: pace ?? this.pace,
      accommodationPreference:
          accommodationPreference ?? this.accommodationPreference,
      basicInfoCompleted: basicInfoCompleted ?? this.basicInfoCompleted,
      statusText: statusText ?? this.statusText,
    );
  }
}
