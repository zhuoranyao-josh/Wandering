import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../../core/config/google_places_config.dart';

class GooglePlacesRemoteDataSource {
  GooglePlacesRemoteDataSource({required this.client});

  static const Duration _requestTimeout = Duration(seconds: 12);
  static const List<Duration> _retryDelays = <Duration>[
    Duration(milliseconds: 500),
    Duration(milliseconds: 1000),
  ];
  static const String _fieldMask =
      'places.id,places.displayName,places.formattedAddress,'
      'places.location,places.rating,places.photos.name,places.googleMapsUri';

  final http.Client client;

  Future<GooglePlaceSearchResult?> searchHotelByName({
    required String hotelName,
    required String destination,
    required double latitude,
    required double longitude,
  }) async {
    debugPrint('[ChecklistPlan] hotel search started hotelName=$hotelName');
    final results = await searchPlacesByText(
      query: '$hotelName $destination hotel',
      type: 'hotel',
      latitude: latitude,
      longitude: longitude,
      limit: 1,
    );
    debugPrint(
      '[ChecklistPlan] hotel search final kept count=${results.length}',
    );
    if (results.isEmpty) {
      return null;
    }
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
      debugPrint('[ChecklistPlan] Google Places key missing');
      return const <GooglePlaceSearchResult>[];
    }
    debugPrint(
      '[ChecklistPlan] Google Places key exists length=${apiKey.length}',
    );

    if (type.trim().toLowerCase() == 'restaurant') {
      debugPrint('[ChecklistPlan] restaurant search started query=$query');
    } else if (type.trim().toLowerCase() == 'activity') {
      debugPrint('[ChecklistPlan] activity search started query=$query');
    } else {
      debugPrint(
        '[ChecklistPlan] places search started type=$type query=$query',
      );
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
      try {
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
        debugPrint(
          '[ChecklistPlan] Google Places response statusCode='
          '${response.statusCode} type=$type query=$query attempt=$attempt',
        );

        if (response.statusCode < 200 || response.statusCode >= 300) {
          debugPrint('[ChecklistPlan] Google Places error response=$payload');
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
          debugPrint('[ChecklistPlan] Google Places raw result count=0');
          debugPrint('[ChecklistPlan] Google Places final kept count=0');
          return const <GooglePlaceSearchResult>[];
        }

        final results = rawPlaces
            .whereType<Map>()
            .map((item) => item.cast<Object?, Object?>())
            .map(_mapPlace)
            .where((item) => item.name.isNotEmpty)
            .toList(growable: false);
        debugPrint(
          '[ChecklistPlan] Google Places raw result count=${rawPlaces.length}',
        );
        debugPrint(
          '[ChecklistPlan] Google Places final kept count=${results.length}',
        );
        return results;
      } on FormatException catch (error) {
        debugPrint(
          '[ChecklistPlan] Google Places attempt=$attempt '
          'query=$query type=$type error=$error',
        );
      } catch (error) {
        debugPrint(
          '[ChecklistPlan] Google Places attempt=$attempt '
          'query=$query type=$type error=$error',
        );
      }

      if (attempt < 3) {
        await Future<void>.delayed(_retryDelays[attempt - 1]);
      }
    }

    debugPrint(
      '[ChecklistPlan] Google Places final kept count=0 '
      'type=$type query=$query after retries',
    );
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
