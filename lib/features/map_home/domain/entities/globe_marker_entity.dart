enum GlobeMarkerType { official, community, mixed }

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
}
