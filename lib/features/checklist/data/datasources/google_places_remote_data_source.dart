import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../../core/config/checklist_debug_config.dart';
import '../../../../core/config/google_places_config.dart';

class GooglePlacesRemoteDataSource {
  GooglePlacesRemoteDataSource({required this.client});

  static const Duration _requestTimeout = Duration(seconds: 12);
  static const bool _enablePlacesSummaryLogs = kChecklistSummaryLogs;
  static const bool _enablePlacesDebugLogs = kChecklistVerboseLogs;
  static const List<Duration> _retryDelays = <Duration>[
    Duration(milliseconds: 500),
    Duration(milliseconds: 1000),
  ];
  static const String _fieldMask =
      'places.id,places.displayName,places.formattedAddress,'
      'places.location,places.rating,places.photos.name,places.googleMapsUri';

  final http.Client client;

  void _debug(String message) {
    if (!_enablePlacesDebugLogs) {
      return;
    }
    debugPrint('[PlacesDebug] $message');
  }

  void _summary(String message) {
    if (!_enablePlacesSummaryLogs) {
      return;
    }
    debugPrint('[PlacesSummary] $message');
  }

  Future<GooglePlaceSearchResult?> searchHotelByName({
    required String hotelName,
    required String destination,
    required double latitude,
    required double longitude,
  }) async {
    _debug('search started type=hotel query=$hotelName');
    final results = await searchPlacesByText(
      query: '$hotelName $destination hotel',
      type: 'hotel',
      latitude: latitude,
      longitude: longitude,
      limit: 1,
    );
    _summary(
      'hotels total=1 success=${results.isNotEmpty ? 1 : 0} failed=${results.isEmpty ? 1 : 0}',
    );
    if (results.isEmpty) {
      return null;
    }
    final selected = results.first;
    _debug(
      'selected place title=${selected.name} '
      'address=${selected.address ?? ''} '
      'rating=${selected.rating} '
      'photoUrlHash=${_hashText(selected.photoUrl)}',
    );
    return results.first;
  }

  Future<List<GooglePlaceSearchResult>> searchPlacesByText({
    required String query,
    required String type,
    required double latitude,
    required double longitude,
    required int limit,
  }) async {
    final apiKey = googlePlacesApiKey.trim();
    if (apiKey.isEmpty) {
      _summary('type=$type total=1 elapsed=0ms success=0 failed=1');
      return const <GooglePlaceSearchResult>[];
    }

    final pageSize = limit.clamp(1, 20);
    final includedType = _resolveIncludedType(type);
    final uri = Uri.https('places.googleapis.com', '/v1/places:searchText');
    final requestBody = <String, dynamic>{
      'textQuery': query,
      'pageSize': pageSize,
      'locationBias': <String, dynamic>{
        'circle': <String, dynamic>{
          'center': <String, double>{
            'latitude': latitude,
            'longitude': longitude,
          },
          'radius': 12000,
        },
      },
    };
    if (includedType != null) {
      requestBody['includedType'] = includedType;
    }

    for (var attempt = 1; attempt <= 3; attempt++) {
      final attemptStopwatch = Stopwatch()..start();
      try {
        _debug('search started type=$type query=$query attempt=$attempt');
        final response = await client
            .post(
              uri,
              headers: <String, String>{
                'Content-Type': 'application/json',
                'X-Goog-Api-Key': apiKey,
                'X-Goog-FieldMask': _fieldMask,
              },
              body: jsonEncode(requestBody),
            )
            .timeout(_requestTimeout);
        final payload = utf8.decode(response.bodyBytes);
        _debug(
          'response statusCode=${response.statusCode} '
          'type=$type query=$query attempt=$attempt',
        );

        if (response.statusCode < 200 || response.statusCode >= 300) {
          _debug(
            'error response type=$type query=$query attempt=$attempt '
            'payloadPreview=${_truncate(payload, 500)}',
          );
          throw Exception(
            'Google Places request failed with statusCode=${response.statusCode}',
          );
        }

        final decoded = jsonDecode(payload);
        if (decoded is! Map<String, dynamic>) {
          throw const FormatException(
            'Google Places response is not a JSON object.',
          );
        }

        final rawPlaces = decoded['places'];
        if (rawPlaces is! List) {
          _summary(
            '$type total=1 elapsed=${attemptStopwatch.elapsedMilliseconds}ms success=0 failed=1 deduped=0',
          );
          return const <GooglePlaceSearchResult>[];
        }

        final results = rawPlaces
            .whereType<Map>()
            .map((item) => item.cast<Object?, Object?>())
            .map(_mapPlace)
            .where((item) => item.name.isNotEmpty)
            .toList(growable: false);
        _debug(
          'result count raw=${rawPlaces.length} kept=${results.length} '
          'type=$type query=$query',
        );
        if (results.isNotEmpty) {
          final selected = results.first;
          _debug(
            'selected place title=${selected.name} '
            'address=${selected.address ?? ''} '
            'rating=${selected.rating} '
            'photoUrlHash=${_hashText(selected.photoUrl)}',
          );
        }
        _summary(
          '$type total=1 elapsed=${attemptStopwatch.elapsedMilliseconds}ms success=${results.isNotEmpty ? 1 : 0} failed=${results.isEmpty ? 1 : 0} deduped=0',
        );
        return results;
      } on FormatException catch (error) {
        _debug('attempt=$attempt query=$query type=$type error=$error');
      } catch (error) {
        _debug('attempt=$attempt query=$query type=$type error=$error');
      }

      if (attempt < 3) {
        await Future<void>.delayed(_retryDelays[attempt - 1]);
      }
    }

    _summary(
      '$type total=1 elapsed=${_requestTimeout.inMilliseconds}ms success=0 failed=1 deduped=0',
    );
    _debug('result count raw=0 kept=0 type=$type query=$query');
    return const <GooglePlaceSearchResult>[];
  }

  String? buildPhotoUrl(
    String? photoName, {
    int maxWidthPx = 900,
    int maxHeightPx = 900,
  }) {
    final trimmedPhotoName = photoName?.trim() ?? '';
    final apiKey = googlePlacesApiKey.trim();
    if (trimmedPhotoName.isEmpty || apiKey.isEmpty) {
      return null;
    }

    return Uri.https(
      'places.googleapis.com',
      '/v1/$trimmedPhotoName/media',
      <String, String>{
        'maxWidthPx': maxWidthPx.toString(),
        'maxHeightPx': maxHeightPx.toString(),
        'key': apiKey,
      },
    ).toString();
  }

  String? resolvePhotoUrl(List<String> photoNames) {
    for (final photoName in photoNames) {
      final url = buildPhotoUrl(photoName);
      if ((url ?? '').isNotEmpty) {
        return url;
      }
    }
    return null;
  }

  GooglePlaceSearchResult _mapPlace(Map<Object?, Object?> map) {
    final displayName = map['displayName'];
    final name = displayName is Map
        ? (displayName['text'] as String?)?.trim() ?? ''
        : '';
    final formattedAddress = (map['formattedAddress'] as String?)?.trim();
    final location = map['location'];
    final latitude = location is Map ? _readDouble(location['latitude']) : null;
    final longitude = location is Map
        ? _readDouble(location['longitude'])
        : null;
    final photoNames = <String>[];
    final photos = map['photos'];
    if (photos is List) {
      for (final photo in photos.whereType<Map>()) {
        final photoName = (photo['name'] as String?)?.trim() ?? '';
        if (photoName.isNotEmpty) {
          photoNames.add(photoName);
        }
      }
    }

    return GooglePlaceSearchResult(
      placeId: (map['id'] as String?)?.trim() ?? '',
      name: name,
      address: formattedAddress,
      photoUrl: resolvePhotoUrl(photoNames),
      latitude: latitude,
      longitude: longitude,
      rating: _readDouble(map['rating']),
      googleMapsUrl: (map['googleMapsUri'] as String?)?.trim(),
    );
  }

  String? _resolveIncludedType(String type) {
    switch (type.trim().toLowerCase()) {
      case 'hotel':
        return 'lodging';
      case 'restaurant':
        return 'restaurant';
      default:
        return null;
    }
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

  String _truncate(String value, int maxLength) {
    final trimmed = value.trim();
    if (trimmed.length <= maxLength) {
      return trimmed;
    }
    return '${trimmed.substring(0, maxLength)}...';
  }

  String _hashText(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) {
      return 'none';
    }
    final hash = Object.hashAll(text.codeUnits);
    return hash.toUnsigned(32).toRadixString(16);
  }
}

class GooglePlaceSearchResult {
  const GooglePlaceSearchResult({
    required this.placeId,
    required this.name,
    required this.address,
    required this.photoUrl,
    required this.latitude,
    required this.longitude,
    required this.rating,
    required this.googleMapsUrl,
  });

  final String placeId;
  final String name;
  final String? address;
  final String? photoUrl;
  final double? latitude;
  final double? longitude;
  final double? rating;
  final String? googleMapsUrl;
}
