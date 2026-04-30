import '../entities/map_home_data_bundle.dart';
import '../entities/map_home_city_search_result_entity.dart';
import '../entities/place_detail_sections_entity.dart';

abstract class MapHomeRepository {
  Future<MapHomeDataBundle> loadMapHomeData();

  Future<PlaceDetailSectionsEntity?> loadPlaceDetailSections(String placeId);

  Future<List<MapHomeCitySearchResultEntity>> searchCities({
    required String query,
    required String languageCode,
  });
}
