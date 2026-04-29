import '../../domain/entities/globe_marker_entity.dart';
import '../../domain/entities/place_entity.dart';
import '../../domain/entities/map_home_region_entity.dart';
import '../../domain/entities/place_detail_sections_entity.dart';

abstract class MapHomeRemoteDataSource {
  Future<List<PlaceEntity>> getPlaces();

  Future<List<GlobeMarkerEntity>> getMarkers();

  Future<List<MapHomeRegionEntity>> getRegions();

  Future<PlaceDetailSectionsEntity?> getPlaceDetailSections(String placeId);
}
