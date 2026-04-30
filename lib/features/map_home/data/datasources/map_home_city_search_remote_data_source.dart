import '../../domain/entities/map_home_city_search_result_entity.dart';

abstract class MapHomeCitySearchRemoteDataSource {
  Future<List<MapHomeCitySearchResultEntity>> searchCities({
    required String query,
    required String languageCode,
  });
}
