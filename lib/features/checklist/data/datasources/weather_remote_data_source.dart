import '../../domain/entities/trip_weather_summary.dart';

abstract class WeatherRemoteDataSource {
  Future<TripWeatherSummary> getTripWeatherSummary({
    required double latitude,
    required double longitude,
    required DateTime startDate,
    required DateTime endDate,
    String languageCode = 'en',
  });
}
