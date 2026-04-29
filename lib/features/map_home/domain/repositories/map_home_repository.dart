import '../entities/map_home_data_bundle.dart';
import '../entities/place_detail_sections_entity.dart';

abstract class MapHomeRepository {
  Future<MapHomeDataBundle> loadMapHomeData();

  Future<PlaceDetailSectionsEntity?> loadPlaceDetailSections(String placeId);
}
