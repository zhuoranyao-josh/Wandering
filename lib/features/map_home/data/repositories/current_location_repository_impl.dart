import '../../domain/entities/current_location_result.dart';
import '../../domain/repositories/current_location_repository.dart';
import '../datasources/device_location_data_source.dart';

class CurrentLocationRepositoryImpl implements CurrentLocationRepository {
  const CurrentLocationRepositoryImpl(this.deviceLocationDataSource);

  final DeviceLocationDataSource deviceLocationDataSource;

  @override
  Future<CurrentLocationResult> fetchCurrentLocation() {
    return deviceLocationDataSource.getCurrentLocation();
  }
}
