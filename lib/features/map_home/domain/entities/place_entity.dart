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
}
