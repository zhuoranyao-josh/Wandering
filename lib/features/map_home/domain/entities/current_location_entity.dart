class CurrentLocationEntity {
  const CurrentLocationEntity({
    required this.latitude,
    required this.longitude,
    this.accuracy,
  });

  final double latitude;
  final double longitude;
  final double? accuracy;
}
