class MapHomeRegionEntity {
  const MapHomeRegionEntity({required this.id, required this.focusZoom});

  final String id;
  final double focusZoom;

  factory MapHomeRegionEntity.fromMap(
    String documentId,
    Map<String, dynamic> json,
  ) {
    return MapHomeRegionEntity(
      id: (json['id'] as String?)?.trim().isNotEmpty == true
          ? (json['id'] as String).trim()
          : documentId,
      focusZoom: _readDouble(json['focusZoom']) ?? 4.8,
    );
  }

  factory MapHomeRegionEntity.fromJson(Map<String, dynamic> json) {
    return MapHomeRegionEntity.fromMap((json['id'] as String?) ?? '', json);
  }

  static double? _readDouble(Object? value) {
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value.trim());
    }
    return null;
  }
}
