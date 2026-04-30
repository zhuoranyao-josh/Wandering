class MapHomeCitySearchResultEntity {
  const MapHomeCitySearchResultEntity({
    required this.mapboxId,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.preferredName,
    this.regionName,
    this.countryName,
  });

  final String mapboxId;
  final String name;
  final String? preferredName;
  final String? regionName;
  final String? countryName;
  final double latitude;
  final double longitude;

  String get displayName {
    final preferred = preferredName?.trim() ?? '';
    if (preferred.isNotEmpty) {
      return preferred;
    }
    return name;
  }
}
