import '../entities/map_home_data_bundle.dart';

abstract class MapHomeRepository {
  Future<MapHomeDataBundle> loadMapHomeData();
}
