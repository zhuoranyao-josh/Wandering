import 'dart:convert';

import 'package:flutter/services.dart';

import '../../domain/entities/globe_marker_entity.dart';
import '../../domain/entities/place_entity.dart';

class MapHomeDataBundle {
  const MapHomeDataBundle({required this.places, required this.markers});

  final List<PlaceEntity> places;
  final List<GlobeMarkerEntity> markers;
}

abstract final class MapHomeMockData {
  static const String _placesAssetPath = 'assets/data/map_home/places.json';
  static const String _markersAssetPath = 'assets/data/map_home/markers.json';

  static MapHomeDataBundle? _cachedBundle;

  static Future<MapHomeDataBundle> load() async {
    final cachedBundle = _cachedBundle;
    if (cachedBundle != null) {
      return cachedBundle;
    }

    final places = await _loadPlaces();
    final markers = await _loadMarkers();
    final bundle = MapHomeDataBundle(places: places, markers: markers);
    _cachedBundle = bundle;
    return bundle;
  }

  static Future<List<PlaceEntity>> _loadPlaces() async {
    final raw = await rootBundle.loadString(_placesAssetPath);
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((item) => PlaceEntity.fromJson(Map<String, dynamic>.from(item)))
        .toList(growable: false);
  }

  static Future<List<GlobeMarkerEntity>> _loadMarkers() async {
    final raw = await rootBundle.loadString(_markersAssetPath);
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map(
          (item) => GlobeMarkerEntity.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList(growable: false);
  }
}
