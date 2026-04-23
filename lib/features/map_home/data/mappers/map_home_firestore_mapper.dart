import '../../domain/entities/globe_marker_entity.dart';
import '../../domain/entities/map_home_region_entity.dart';
import '../../domain/entities/place_entity.dart';
import '../utils/map_home_firestore_utils.dart';

PlaceEntity mapPlaceEntityFromFirestore(
  String documentId,
  Map<String, dynamic> json,
) {
  return PlaceEntity(
    id: readTrimmedString(json, 'id') ?? documentId,
    name: readLanguageMap(json['name']),
    regionId: readTrimmedString(json, 'regionId') ?? '',
    latitude: readDouble(json['latitude']) ?? 0.0,
    longitude: readDouble(json['longitude']) ?? 0.0,
    coverImage:
        readTrimmedString(json, 'coverImage') ??
        readTrimmedString(json, 'previewAssetPath') ??
        '',
    quote: readLanguageMap(json['quote']),
    shortDescription: readLanguageMap(json['shortDescription']),
    longDescription: readLanguageMap(json['longDescription']),
    tags: readStringList(json['tags']),
    flyToZoom: readDouble(json['flyToZoom']) ?? 10.8,
    flyToPitch: readDouble(json['flyToPitch']) ?? 48.0,
    flyToBearing: readDouble(json['flyToBearing']) ?? 12.0,
  );
}

GlobeMarkerEntity mapGlobeMarkerEntityFromFirestore(
  String documentId,
  Map<String, dynamic> json,
) {
  return GlobeMarkerEntity(
    id: readTrimmedString(json, 'id') ?? documentId,
    placeId: readTrimmedString(json, 'placeId') ?? '',
    type: GlobeMarkerType.fromJson(readTrimmedString(json, 'type') ?? ''),
    latitude: readDouble(json['latitude']),
    longitude: readDouble(json['longitude']),
  );
}

MapHomeRegionEntity mapRegionEntityFromFirestore(
  String documentId,
  Map<String, dynamic> json,
) {
  return MapHomeRegionEntity(
    id: readTrimmedString(json, 'id') ?? documentId,
    focusZoom: readDouble(json['focusZoom']) ?? 4.8,
  );
}
