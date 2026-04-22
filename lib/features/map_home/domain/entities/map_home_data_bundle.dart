import 'globe_marker_entity.dart';
import 'place_entity.dart';
import 'map_home_region_entity.dart';

class MapHomeDataBundle {
  const MapHomeDataBundle({
    required this.places,
    required this.markers,
    required this.regions,
  });

  final List<PlaceEntity> places;
  final List<GlobeMarkerEntity> markers;
  final List<MapHomeRegionEntity> regions;
}
