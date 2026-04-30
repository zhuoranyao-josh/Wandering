import '../entities/current_location_result.dart';

abstract class CurrentLocationRepository {
  Future<CurrentLocationResult> fetchCurrentLocation();
}
