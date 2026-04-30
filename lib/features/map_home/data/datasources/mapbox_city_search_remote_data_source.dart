import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../core/config/mapbox_config.dart';
import '../../../../core/error/app_exception.dart';
import '../../domain/entities/map_home_city_search_result_entity.dart';
import 'map_home_city_search_remote_data_source.dart';

class MapboxCitySearchRemoteDataSource
    implements MapHomeCitySearchRemoteDataSource {
  MapboxCitySearchRemoteDataSource({required this.httpClient});

  final http.Client httpClient;

  @override
  Future<List<MapHomeCitySearchResultEntity>> searchCities({
    required String query,
    required String languageCode,
  }) async {
    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty || !MapboxConfig.hasAccessToken) {
      return const <MapHomeCitySearchResultEntity>[];
    }

    final uri = Uri.https(
      'api.mapbox.com',
      '/search/geocode/v6/forward',
      <String, String>{
        'q': trimmedQuery,
        'types': 'place,district,region',
        'limit': '5',
        'language': _resolveSearchLanguage(languageCode),
        'autocomplete': 'false',
        'access_token': MapboxConfig.accessToken,
      },
    );

    final response = await httpClient.get(uri);
    if (response.statusCode != 200) {
      throw AppException('map_home_search_failed');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw AppException('map_home_search_failed');
    }

    final features = decoded['features'];
    if (features is! List) {
      return const <MapHomeCitySearchResultEntity>[];
    }

    final results = <MapHomeCitySearchResultEntity>[];
    for (final item in features) {
      if (item is! Map<String, dynamic>) {
        continue;
      }

      final properties = item['properties'];
      final featureType =
          _readText(item['feature_type']) ??
          _readText(properties is Map ? properties['feature_type'] : null) ??
          '';
      // 只保留城市、区县和一级行政区，避免把国家、街道和具体 POI 混进来。
      if (!_isAllowedFeatureType(featureType)) {
        continue;
      }

      final geometry = item['geometry'];
      if (geometry is! Map<String, dynamic>) {
        continue;
      }

      final coordinates = geometry['coordinates'];
      if (coordinates is! List || coordinates.length < 2) {
        continue;
      }

      final longitude = _readDouble(coordinates[0]);
      final latitude = _readDouble(coordinates[1]);
      if (latitude == null || longitude == null) {
        continue;
      }

      final context = item['context'];
      final name =
          _readText(item['name']) ??
          _readText(properties is Map ? properties['name'] : null) ??
          _readText(item['full_address']) ??
          _readText(properties is Map ? properties['full_address'] : null);
      if (name == null) {
        continue;
      }

      results.add(
        MapHomeCitySearchResultEntity(
          mapboxId: _readText(item['mapbox_id']) ?? '',
          name: name,
          preferredName: _readText(
            properties is Map ? properties['name_preferred'] : null,
          ),
          regionName: _readContextName(context, 'region'),
          countryName: _readContextName(context, 'country'),
          latitude: latitude,
          longitude: longitude,
        ),
      );
    }

    return results;
  }

  String _resolveSearchLanguage(String languageCode) {
    return languageCode.toLowerCase().startsWith('zh') ? 'zh-Hans' : 'en';
  }

  bool _isAllowedFeatureType(String featureType) {
    switch (featureType.trim().toLowerCase()) {
      case 'place':
      case 'city':
      case 'district':
      case 'region':
        return true;
      default:
        return false;
    }
  }

  String? _readContextName(Object? value, String expectedId) {
    if (value is! Map) {
      return null;
    }

    final dynamic contextItem = value[expectedId];
    if (contextItem is! Map) {
      return null;
    }

    return _readText(contextItem['name']);
  }

  String? _readText(Object? value) {
    if (value is! String) {
      return null;
    }
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  double? _readDouble(Object? value) {
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value.trim());
    }
    return null;
  }
}
