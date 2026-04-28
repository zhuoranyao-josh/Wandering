class JourneyBasicInfoInput {
  const JourneyBasicInfoInput({
    required this.departureCity,
    this.departureCountry,
    this.departureLatitude,
    this.departureLongitude,
    this.departureSource,
    required this.startDate,
    required this.endDate,
    required this.tripDays,
    required this.nightCount,
    required this.travelerCount,
    required this.totalBudget,
    required this.currency,
    required this.preferences,
    required this.pace,
    required this.accommodationPreference,
    required this.basicInfoCompleted,
  });

  final String departureCity;
  final String? departureCountry;
  final double? departureLatitude;
  final double? departureLongitude;
  final String? departureSource;
  final DateTime startDate;
  final DateTime endDate;
  final int tripDays;
  final int nightCount;
  final int travelerCount;
  final double totalBudget;
  final String currency;
  final List<String> preferences;
  final String pace;
  final String accommodationPreference;
  final bool basicInfoCompleted;
}
