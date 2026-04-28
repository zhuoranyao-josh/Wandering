class ChecklistItem {
  const ChecklistItem({
    required this.id,
    required this.destination,
    required this.placeId,
    required this.coverImageUrl,
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
  final String placeId;
  final String coverImageUrl;
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
    return placeId.trim().isNotEmpty &&
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

  ChecklistItem copyWith({
    String? id,
    String? destination,
    String? placeId,
    String? coverImageUrl,
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
