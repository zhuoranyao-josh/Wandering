import '../../domain/entities/globe_marker_entity.dart';
import '../../domain/entities/place_entity.dart';

abstract final class MapHomeMockData {
  static const PlaceEntity tokyoPlace = PlaceEntity(
    id: 'tokyo',
    previewAssetPath: 'assets/images/tokyo_preview.png',
    latitude: 35.6762,
    longitude: 139.6503,
    flyToZoom: 10.8,
    flyToPitch: 48.0,
    flyToBearing: 12.0,
  );

  static const GlobeMarkerEntity tokyoMarker = GlobeMarkerEntity(
    id: 'marker_tokyo',
    placeId: 'tokyo',
    type: GlobeMarkerType.official,
    latitude: 35.6762,
    longitude: 139.6503,
  );

  static const List<PlaceEntity> places = <PlaceEntity>[tokyoPlace];
  static const List<GlobeMarkerEntity> markers = <GlobeMarkerEntity>[
    tokyoMarker,
  ];
}
