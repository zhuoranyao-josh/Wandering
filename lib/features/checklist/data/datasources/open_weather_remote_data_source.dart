import 'dart:convert';
import 'dart:io';

import '../../../../core/config/open_weather_config.dart';
import '../../domain/entities/trip_weather_summary.dart';
import 'weather_remote_data_source.dart';

class OpenWeatherRemoteDataSource implements WeatherRemoteDataSource {
  static const Duration _requestTimeout = Duration(seconds: 12);
  static const Duration _maxForecastDuration = Duration(days: 5);

  @override
  Future<TripWeatherSummary> getTripWeatherSummary({
    required double latitude,
    required double longitude,
    required DateTime startDate,
    required DateTime endDate,
    String languageCode = 'en',
  }) async {
    // OpenWeather 5 day / 3 hour forecast 仅覆盖未来 5 天。
    final now = DateTime.now();
    if (endDate.isAfter(now.add(_maxForecastDuration))) {
      return TripWeatherSummary.unavailable(reasonCode: 'forecast_limit');
    }

    if (openWeatherApiKey.trim().isEmpty) {
      return TripWeatherSummary.unavailable(reasonCode: 'api_key_missing');
    }

    HttpClient? client;
    try {
      final uri = Uri.https(
        'api.openweathermap.org',
        '/data/2.5/forecast',
        <String, String>{
          'lat': latitude.toString(),
          'lon': longitude.toString(),
          'appid': openWeatherApiKey.trim(),
          'units': 'metric',
          'lang': _toOpenWeatherLanguage(languageCode),
        },
      );

      client = HttpClient();
      final request = await client.getUrl(uri);
      final response = await request.close().timeout(_requestTimeout);
      final payload = await response.transform(utf8.decoder).join();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return TripWeatherSummary.unavailable(reasonCode: 'request_failed');
      }

      final decoded = jsonDecode(payload);
      if (decoded is! Map<String, dynamic>) {
        return TripWeatherSummary.unavailable(reasonCode: 'request_failed');
      }

      final rawList = decoded['list'];
      if (rawList is! List) {
        return TripWeatherSummary.unavailable(reasonCode: 'no_data');
      }

      final city = decoded['city'];
      final cityTimeZoneOffsetSeconds = city is Map<String, dynamic>
          ? _asInt(city['timezone']) ?? 0
          : 0;

      final rangeStart = DateTime(
        startDate.year,
        startDate.month,
        startDate.day,
      );
      final rangeEnd = DateTime(
        endDate.year,
        endDate.month,
        endDate.day,
        23,
        59,
        59,
      );

      final filtered = rawList
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .where((entry) {
            final tripTime = _toTripLocalDateTime(
              entry,
              cityTimeZoneOffsetSeconds,
            );
            if (tripTime == null) {
              return false;
            }
            return !tripTime.isBefore(rangeStart) &&
                !tripTime.isAfter(rangeEnd);
          })
          .toList(growable: false);

      if (filtered.isEmpty) {
        return TripWeatherSummary.unavailable(reasonCode: 'no_data');
      }

      double? minTemp;
      double? maxTemp;
      var humidityTotal = 0;
      var humidityCount = 0;
      var hasRain = false;
      var hasSnow = false;

      for (final entry in filtered) {
        final main = entry['main'];
        if (main is Map<String, dynamic>) {
          final tempMin = _asDouble(main['temp_min']);
          final tempMax = _asDouble(main['temp_max']);
          if (tempMin != null) {
            minTemp = minTemp == null
                ? tempMin
                : (tempMin < minTemp ? tempMin : minTemp);
          }
          if (tempMax != null) {
            maxTemp = maxTemp == null
                ? tempMax
                : (tempMax > maxTemp ? tempMax : maxTemp);
          }
          final humidity = _asInt(main['humidity']);
          if (humidity != null) {
            humidityTotal += humidity;
            humidityCount++;
          }
        }

        final weatherList = entry['weather'];
        if (weatherList is List) {
          for (final weather in weatherList) {
            if (weather is! Map) {
              continue;
            }
            final weatherMain =
                (weather['main'] as String?)?.trim().toLowerCase() ?? '';
            if (weatherMain == 'rain') {
              hasRain = true;
            }
            if (weatherMain == 'snow') {
              hasSnow = true;
            }
          }
        }

        final rain = entry['rain'];
        if (rain is Map<String, dynamic>) {
          final rain3h = _asDouble(rain['3h']);
          if ((rain3h ?? 0) > 0) {
            hasRain = true;
          }
        }

        final snow = entry['snow'];
        if (snow is Map<String, dynamic>) {
          final snow3h = _asDouble(snow['3h']);
          if ((snow3h ?? 0) > 0) {
            hasSnow = true;
          }
        }

        final pop = _asDouble(entry['pop']);
        if ((pop ?? 0) >= 0.4) {
          hasRain = true;
        }
      }

      if (minTemp == null || maxTemp == null) {
        return TripWeatherSummary.unavailable(reasonCode: 'no_data');
      }

      final minText = minTemp.round();
      final maxText = maxTemp.round();
      final humidityPercent = humidityCount > 0
          ? (humidityTotal / humidityCount).round()
          : null;
      if (hasSnow) {
        return TripWeatherSummary(
          isAvailable: true,
          minTemp: minTemp,
          maxTemp: maxTemp,
          humidityPercent: humidityPercent,
          hasRain: hasRain,
          hasSnow: true,
          mainText: '$minText°C – $maxText°C · Snow',
          subText: 'Snow expected',
          iconType: 'snow',
        );
      }
      if (hasRain) {
        return TripWeatherSummary(
          isAvailable: true,
          minTemp: minTemp,
          maxTemp: maxTemp,
          humidityPercent: humidityPercent,
          hasRain: true,
          hasSnow: false,
          mainText: '$minText°C – $maxText°C · Rainy',
          subText: 'Rain expected',
          iconType: 'rain',
        );
      }

      return TripWeatherSummary(
        isAvailable: true,
        minTemp: minTemp,
        maxTemp: maxTemp,
        humidityPercent: humidityPercent,
        hasRain: false,
        hasSnow: false,
        mainText: '$minText°C – $maxText°C',
        subText: 'Mostly clear',
        iconType: 'clear',
      );
    } catch (_) {
      return TripWeatherSummary.unavailable(reasonCode: 'request_failed');
    } finally {
      client?.close(force: true);
    }
  }

  String _toOpenWeatherLanguage(String languageCode) {
    final normalized = languageCode.trim().toLowerCase();
    if (normalized.startsWith('zh')) {
      return 'zh_cn';
    }
    return 'en';
  }

  DateTime? _toTripLocalDateTime(
    Map<String, dynamic> entry,
    int cityTimeZoneOffsetSeconds,
  ) {
    final timestamp = _asInt(entry['dt']);
    if (timestamp == null) {
      return null;
    }
    final utc = DateTime.fromMillisecondsSinceEpoch(
      timestamp * 1000,
      isUtc: true,
    );
    final cityLocal = utc.add(Duration(seconds: cityTimeZoneOffsetSeconds));
    return DateTime(
      cityLocal.year,
      cityLocal.month,
      cityLocal.day,
      cityLocal.hour,
      cityLocal.minute,
      cityLocal.second,
    );
  }

  int? _asInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }

  double? _asDouble(Object? value) {
    if (value is double) {
      return value;
    }
    if (value is int) {
      return value.toDouble();
    }
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value);
    }
    return null;
  }
}
