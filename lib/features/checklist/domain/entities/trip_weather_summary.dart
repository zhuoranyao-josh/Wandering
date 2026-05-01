class TripWeatherSummary {
  const TripWeatherSummary({
    required this.isAvailable,
    required this.minTemp,
    required this.maxTemp,
    required this.humidityPercent,
    required this.hasRain,
    required this.hasSnow,
    required this.mainText,
    required this.subText,
    required this.iconType,
    this.reasonCode,
  });

  final bool isAvailable;
  final double? minTemp;
  final double? maxTemp;
  final int? humidityPercent;
  final bool hasRain;
  final bool hasSnow;
  final String mainText;
  final String subText;
  final String iconType;
  final String? reasonCode;

  factory TripWeatherSummary.unavailable({
    required String reasonCode,
    String mainText = '',
    String subText = '',
    String iconType = 'cloud_off',
  }) {
    return TripWeatherSummary(
      isAvailable: false,
      minTemp: null,
      maxTemp: null,
      humidityPercent: null,
      hasRain: false,
      hasSnow: false,
      mainText: mainText,
      subText: subText,
      iconType: iconType,
      reasonCode: reasonCode,
    );
  }
}
