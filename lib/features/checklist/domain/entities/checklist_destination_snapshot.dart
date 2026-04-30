class ChecklistDestinationSourceType {
  static const String official = 'official';
  static const String mapbox = 'mapbox';
}

class ChecklistDestinationSnapshot {
  const ChecklistDestinationSnapshot({
    required this.name,
    required this.latitude,
    required this.longitude,
    this.coverImageUrl,
    required this.provider,
    this.providerPlaceId,
    this.placeLevel,
    this.country,
    this.region,
  });

  final String name;
  final double latitude;
  final double longitude;
  final String? coverImageUrl;
  final String provider;
  final String? providerPlaceId;
  final String? placeLevel;
  final String? country;
  final String? region;

  bool get hasCoreData =>
      name.trim().isNotEmpty &&
      latitude.isFinite &&
      longitude.isFinite &&
      !(latitude == 0 && longitude == 0);

  ChecklistDestinationSnapshot copyWith({
    String? name,
    double? latitude,
    double? longitude,
    String? coverImageUrl,
    String? provider,
    String? providerPlaceId,
    String? placeLevel,
    String? country,
    String? region,
  }) {
    return ChecklistDestinationSnapshot(
      name: name ?? this.name,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      provider: provider ?? this.provider,
      providerPlaceId: providerPlaceId ?? this.providerPlaceId,
      placeLevel: placeLevel ?? this.placeLevel,
      country: country ?? this.country,
      region: region ?? this.region,
    );
  }
}
