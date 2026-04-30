import '../../domain/entities/globe_marker_entity.dart';
import '../../domain/entities/map_home_data_bundle.dart';
import '../../domain/entities/map_home_city_search_result_entity.dart';
import '../../domain/entities/map_home_region_entity.dart';
import '../../domain/entities/place_detail_sections_entity.dart';
import '../../domain/entities/place_entity.dart';
import '../../domain/repositories/map_home_repository.dart';
import '../datasources/map_home_city_search_remote_data_source.dart';
import '../datasources/map_home_remote_data_source.dart';

class MapHomeRepositoryImpl implements MapHomeRepository {
  MapHomeRepositoryImpl(this.remoteDataSource, this.citySearchRemoteDataSource);

  final MapHomeRemoteDataSource remoteDataSource;
  final MapHomeCitySearchRemoteDataSource citySearchRemoteDataSource;

  @override
  Future<MapHomeDataBundle> loadMapHomeData() async {
    final results = await Future.wait([
      remoteDataSource.getPlaces(),
      remoteDataSource.getMarkers(),
      remoteDataSource.getRegions(),
    ]);
    return MapHomeDataBundle(
      places: List<PlaceEntity>.from(results[0] as Iterable),
      markers: List<GlobeMarkerEntity>.from(results[1] as Iterable),
      regions: List<MapHomeRegionEntity>.from(results[2] as Iterable),
    );
  }

  @override
  Future<PlaceDetailSectionsEntity?> loadPlaceDetailSections(String placeId) {
    return remoteDataSource.getPlaceDetailSections(placeId);
  }

  @override
  Future<List<MapHomeCitySearchResultEntity>> searchCities({
    required String query,
    required String languageCode,
  }) {
    return citySearchRemoteDataSource.searchCities(
      query: query,
      languageCode: languageCode,
    );
  }
}
