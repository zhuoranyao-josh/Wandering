import '../../domain/entities/current_location_result.dart';

abstract class DeviceLocationDataSource {
  Future<CurrentLocationResult> getCurrentLocation();
}
