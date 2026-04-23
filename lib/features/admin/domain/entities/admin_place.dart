class AdminPlace {
  const AdminPlace({
    required this.id,
    required this.name,
    required this.regionId,
    required this.latitude,
    required this.longitude,
    required this.coverImage,
    required this.quote,
    required this.shortDescription,
    required this.longDescription,
    required this.tags,
    required this.flyToZoom,
    required this.flyToPitch,
    required this.flyToBearing,
    required this.enabled,
    required this.markerId,
    required this.markerType,
    required this.markerLatitude,
    required this.markerLongitude,
  });

  final String id;
  final Map<String, String> name;
  final String regionId;
  final double latitude;
  final double longitude;
  final String coverImage;
  final Map<String, String> quote;
  final Map<String, String> shortDescription;
  final Map<String, String> longDescription;
  final List<String> tags;
  final double flyToZoom;
  final double flyToPitch;
  final double flyToBearing;
  final bool enabled;
  final String? markerId;
  final String markerType;
  final double? markerLatitude;
  final double? markerLongitude;

  String localizedName(String languageCode) {
    final isZh = languageCode.toLowerCase().startsWith('zh');
    final zh = name['zh']?.trim() ?? '';
    final en = name['en']?.trim() ?? '';
    if (isZh && zh.isNotEmpty) {
      return zh;
    }
    if (en.isNotEmpty) {
      return en;
    }
    return zh;
  }

  AdminPlace copyWith({
    String? id,
    Map<String, String>? name,
    String? regionId,
    double? latitude,
    double? longitude,
    String? coverImage,
    Map<String, String>? quote,
    Map<String, String>? shortDescription,
    Map<String, String>? longDescription,
    List<String>? tags,
    double? flyToZoom,
    double? flyToPitch,
    double? flyToBearing,
    bool? enabled,
    String? markerId,
    String? markerType,
    double? markerLatitude,
    double? markerLongitude,
  }) {
    return AdminPlace(
      id: id ?? this.id,
      name: name ?? this.name,
      regionId: regionId ?? this.regionId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      coverImage: coverImage ?? this.coverImage,
      quote: quote ?? this.quote,
      shortDescription: shortDescription ?? this.shortDescription,
      longDescription: longDescription ?? this.longDescription,
      tags: tags ?? this.tags,
      flyToZoom: flyToZoom ?? this.flyToZoom,
      flyToPitch: flyToPitch ?? this.flyToPitch,
      flyToBearing: flyToBearing ?? this.flyToBearing,
      enabled: enabled ?? this.enabled,
      markerId: markerId ?? this.markerId,
      markerType: markerType ?? this.markerType,
      markerLatitude: markerLatitude ?? this.markerLatitude,
      markerLongitude: markerLongitude ?? this.markerLongitude,
    );
  }
}
