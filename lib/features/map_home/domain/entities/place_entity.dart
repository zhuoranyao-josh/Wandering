class PlaceEntity {
  const PlaceEntity({
    required this.id,
    required this.previewAssetPath,
    required this.latitude,
    required this.longitude,
    required this.flyToZoom,
    required this.flyToPitch,
    required this.flyToBearing,
  });

  final String id;
  final String previewAssetPath;
  final double latitude;
  final double longitude;
  final double flyToZoom;
  final double flyToPitch;
  final double flyToBearing;

  factory PlaceEntity.fromJson(Map<String, dynamic> json) {
    return PlaceEntity(
      id: json['id'] as String,
      previewAssetPath: json['previewAssetPath'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      flyToZoom: (json['flyToZoom'] as num).toDouble(),
      flyToPitch: (json['flyToPitch'] as num).toDouble(),
      flyToBearing: (json['flyToBearing'] as num).toDouble(),
    );
  }
}
