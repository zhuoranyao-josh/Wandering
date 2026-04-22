enum GlobeMarkerType {
  official,
  community,
  mixed;

  String get rawValue {
    switch (this) {
      case GlobeMarkerType.official:
        return 'official';
      case GlobeMarkerType.community:
        return 'community';
      case GlobeMarkerType.mixed:
        return 'mixed';
    }
  }

  factory GlobeMarkerType.fromJson(String value) {
    switch (value.trim().toLowerCase()) {
      case 'official':
        return GlobeMarkerType.official;
      case 'community':
        return GlobeMarkerType.community;
      case 'mixed':
        return GlobeMarkerType.mixed;
    }

    return GlobeMarkerType.official;
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
  final double? latitude;
  final double? longitude;

  bool get hasCoordinates => latitude != null && longitude != null;

  factory GlobeMarkerEntity.fromMap(
    String documentId,
    Map<String, dynamic> json,
  ) {
    // marker 坐标改成可选，渲染时再回退到关联 place 坐标。
    return GlobeMarkerEntity(
      id: (json['id'] as String?)?.trim().isNotEmpty == true
          ? (json['id'] as String).trim()
          : documentId,
      placeId: (json['placeId'] as String?)?.trim() ?? '',
      type: GlobeMarkerType.fromJson((json['type'] as String?)?.trim() ?? ''),
      latitude: _readDouble(json['latitude']),
      longitude: _readDouble(json['longitude']),
    );
  }

  factory GlobeMarkerEntity.fromJson(Map<String, dynamic> json) {
    return GlobeMarkerEntity.fromMap((json['id'] as String?) ?? '', json);
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
