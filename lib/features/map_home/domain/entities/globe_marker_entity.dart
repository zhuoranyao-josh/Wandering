enum GlobeMarkerType {
  official,
  community,
  mixed;

  factory GlobeMarkerType.fromJson(String value) {
    switch (value) {
      case 'official':
        return GlobeMarkerType.official;
      case 'community':
        return GlobeMarkerType.community;
      case 'mixed':
        return GlobeMarkerType.mixed;
    }

    throw ArgumentError.value(value, 'type', 'Unsupported marker type');
  }
}

class GlobeMarkerEntity {
  const GlobeMarkerEntity({
    required this.id,
    required this.placeId,
    required this.type,
    required this.latitude,
    required this.longitude,
  });

  final String id;
  final String placeId;
  final GlobeMarkerType type;
  final double latitude;
  final double longitude;

  factory GlobeMarkerEntity.fromJson(Map<String, dynamic> json) {
    return GlobeMarkerEntity(
      id: json['id'] as String,
      placeId: json['placeId'] as String,
      type: GlobeMarkerType.fromJson(json['type'] as String),
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
    );
  }
}
