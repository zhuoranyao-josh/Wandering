import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import '../../data/mock/map_home_mock_data.dart';
import '../../domain/entities/globe_marker_entity.dart';
import '../../domain/entities/place_entity.dart';

enum MapHomeViewStatus { loading, ready, error }

enum MapHomeLightPreset {
  day('day'),
  night('night');

  const MapHomeLightPreset(this.styleValue);

  final String styleValue;

  MapHomeLightPreset get toggled => this == MapHomeLightPreset.day
      ? MapHomeLightPreset.night
      : MapHomeLightPreset.day;
}

enum MapHomeBasemapLanguage {
  zhHans('zh-Hans'),
  en('en');

  const MapHomeBasemapLanguage(this.styleValue);

  final String styleValue;
}

class MapHomeController extends ChangeNotifier {
  static const String _basemapImportId = 'basemap';

  MapHomeViewStatus _status = MapHomeViewStatus.loading;
  MapHomeLightPreset _lightPreset = MapHomeLightPreset.day;
  MapHomeBasemapLanguage _basemapLanguage = MapHomeBasemapLanguage.en;
  final List<GlobeMarkerEntity> _markers = MapHomeMockData.markers;
  MapboxMap? _mapboxMap;
  CircleAnnotationManager? _markerManager;
  Cancelable? _markerTapCancelable;
  String? _errorDetails;
  int _mapWidgetVersion = 0;
  bool _isApplyingStyle = false;
  bool _isScaleBarVisible = true;
  PlaceEntity? _selectedPlace;
  String? _selectedMarkerId;
  final Map<String, PlaceEntity> _placesById = <String, PlaceEntity>{
    for (final place in MapHomeMockData.places) place.id: place,
  };
  final Map<String, GlobeMarkerEntity> _markersById =
      <String, GlobeMarkerEntity>{
        for (final marker in MapHomeMockData.markers) marker.id: marker,
      };
  final Map<String, String> _annotationIdToMarkerId = <String, String>{};
  final Map<String, CircleAnnotation> _markerAnnotationsById =
      <String, CircleAnnotation>{};

  MapHomeViewStatus get status => _status;
  MapHomeLightPreset get lightPreset => _lightPreset;
  MapHomeBasemapLanguage get basemapLanguage => _basemapLanguage;
  PlaceEntity? get selectedPlace => _selectedPlace;
  String? get errorDetails => _errorDetails;
  int get mapWidgetVersion => _mapWidgetVersion;

  bool get isLoading => _status == MapHomeViewStatus.loading;
  bool get hasError => _status == MapHomeViewStatus.error;
  bool get isReady => _status == MapHomeViewStatus.ready;
  bool get canToggleLightPreset =>
      isReady && _mapboxMap != null && !_isApplyingStyle;

  void onMapCreated(MapboxMap mapboxMap) {
    _markerTapCancelable?.cancel();
    _markerTapCancelable = null;
    _markerManager = null;
    _annotationIdToMarkerId.clear();
    _markerAnnotationsById.clear();
    _mapboxMap = mapboxMap;
    _status = MapHomeViewStatus.loading;
    _errorDetails = null;
    notifyListeners();
  }

  Future<void> onStyleLoaded() async {
    final mapboxMap = _mapboxMap;
    if (mapboxMap == null) {
      return;
    }

    try {
      _isApplyingStyle = true;
      await _applyMapStyle(
        mapboxMap,
        lightPreset: _lightPreset,
        basemapLanguage: _basemapLanguage,
        includeProjection: true,
      );
      await _syncMarkers();
      await _refreshMarkerVisuals();
      _status = MapHomeViewStatus.ready;
      _errorDetails = null;
    } catch (error) {
      _setError(error);
    } finally {
      _isApplyingStyle = false;
      notifyListeners();
    }
  }

  Future<void> toggleLightPreset() async {
    final mapboxMap = _mapboxMap;
    if (mapboxMap == null || !canToggleLightPreset) {
      return;
    }

    final nextPreset = _lightPreset.toggled;

    try {
      _isApplyingStyle = true;
      notifyListeners();
      await _applyMapStyle(
        mapboxMap,
        lightPreset: nextPreset,
        basemapLanguage: _basemapLanguage,
      );
      await _refreshMarkerVisuals();
      _lightPreset = nextPreset;
      _status = MapHomeViewStatus.ready;
      _errorDetails = null;
    } catch (error) {
      _setError(error);
    } finally {
      _isApplyingStyle = false;
      notifyListeners();
    }
  }

  void onMapLoadError(String message) {
    if (isReady) {
      return;
    }

    _status = MapHomeViewStatus.error;
    _errorDetails = message.trim().isEmpty ? null : message.trim();
    notifyListeners();
  }

  Future<void> syncBasemapLanguageWithLocale(Locale locale) async {
    final nextLanguage = _resolveBasemapLanguage(locale);
    // ignore: experimental_member_use
    MapboxMapsOptions.setLanguage(nextLanguage.styleValue);

    if (nextLanguage == _basemapLanguage) {
      return;
    }

    _basemapLanguage = nextLanguage;

    if (_mapboxMap != null) {
      retry();
    }
  }

  void retry() {
    _markerTapCancelable?.cancel();
    _markerTapCancelable = null;
    _markerManager = null;
    _annotationIdToMarkerId.clear();
    _markerAnnotationsById.clear();
    _mapWidgetVersion += 1;
    _mapboxMap = null;
    _status = MapHomeViewStatus.loading;
    _errorDetails = null;
    _isApplyingStyle = false;
    notifyListeners();
  }

  Future<void> _applyMapStyle(
    MapboxMap mapboxMap, {
    required MapHomeLightPreset lightPreset,
    required MapHomeBasemapLanguage basemapLanguage,
    bool includeProjection = false,
  }) async {
    if (includeProjection) {
      await mapboxMap.style.setProjection(
        StyleProjection(name: StyleProjectionName.globe),
      );
    }

    await mapboxMap.style.setStyleImportConfigProperties(_basemapImportId, {
      'lightPreset': lightPreset.styleValue,
      'language': basemapLanguage.styleValue,
    });
  }

  MapHomeBasemapLanguage _resolveBasemapLanguage(Locale locale) {
    if (locale.languageCode.toLowerCase().startsWith('zh')) {
      return MapHomeBasemapLanguage.zhHans;
    }
    return MapHomeBasemapLanguage.en;
  }

  void _setError(Object error) {
    _status = MapHomeViewStatus.error;
    _errorDetails = error.toString();
  }

  Future<void> selectMarkerById(String markerId) async {
    final marker = _markersById[markerId];
    if (marker == null) {
      return;
    }

    final place = _placesById[marker.placeId];
    if (place == null) {
      return;
    }

    await _updateMarkerSelection(markerId);

    final mapboxMap = _mapboxMap;
    if (mapboxMap != null) {
      final cameraState = await mapboxMap.getCameraState();
      await mapboxMap.flyTo(
        CameraOptions(
          center: Point(
            coordinates: Position(marker.longitude, marker.latitude),
          ),
          zoom: place.flyToZoom,
          pitch: cameraState.pitch,
          bearing: cameraState.bearing,
        ),
        MapAnimationOptions(duration: 1800),
      );
    }

    await _setMarkerHidden(markerId, true);
    _selectedPlace = place;
    notifyListeners();
  }

  Future<void> clearSelectedPlace() async {
    final markerId = _selectedMarkerId;
    if (markerId != null) {
      await _setMarkerHidden(markerId, false);
      await _updateMarkerSelection(markerId, keepSelectedState: false);
    }

    _selectedPlace = null;
    notifyListeners();
  }

  Future<void> updateScaleBarVisibility(bool isVisible) async {
    if (_isScaleBarVisible == isVisible) {
      return;
    }

    _isScaleBarVisible = isVisible;

    final mapboxMap = _mapboxMap;
    if (mapboxMap == null) {
      return;
    }

    await mapboxMap.scaleBar.updateSettings(
      ScaleBarSettings(enabled: isVisible),
    );
  }

  Future<void> _syncMarkers() async {
    final mapboxMap = _mapboxMap;
    if (mapboxMap == null) {
      return;
    }

    _markerTapCancelable?.cancel();
    _markerTapCancelable = null;
    _annotationIdToMarkerId.clear();
    _markerAnnotationsById.clear();

    final markerManager = await mapboxMap.annotations
        .createCircleAnnotationManager();
    _markerManager = markerManager;

    final createdAnnotations = await markerManager.createMulti(
      _markers.map(_buildMarkerOptions).toList(),
    );

    for (var i = 0; i < createdAnnotations.length; i++) {
      final annotation = createdAnnotations[i];
      if (annotation == null) {
        continue;
      }

      final marker = _markers[i];
      _annotationIdToMarkerId[annotation.id] = marker.id;
      _markerAnnotationsById[marker.id] = annotation;
    }

    _markerTapCancelable = markerManager.tapEvents(
      onTap: (annotation) {
        final markerId = _annotationIdToMarkerId[annotation.id];
        if (markerId == null) {
          return;
        }
        selectMarkerById(markerId);
      },
    );

    if (_selectedMarkerId != null) {
      await _updateMarkerSelection(_selectedMarkerId!);
    }
  }

  Future<void> _refreshMarkerVisuals() async {
    final markerManager = _markerManager;
    if (markerManager == null) {
      return;
    }

    for (final marker in _markers) {
      final annotation = _markerAnnotationsById[marker.id];
      if (annotation == null) {
        continue;
      }

      final isCurrentMarker = _selectedMarkerId == marker.id;
      _applyMarkerVisual(
        annotation,
        marker: marker,
        isSelected: isCurrentMarker && _selectedPlace == null,
        isHidden: isCurrentMarker && _selectedPlace != null,
      );
      await markerManager.update(annotation);
    }
  }

  CircleAnnotationOptions _buildMarkerOptions(GlobeMarkerEntity marker) {
    return CircleAnnotationOptions(
      geometry: Point(coordinates: Position(marker.longitude, marker.latitude)),
      circleColor: _markerColor(marker.type).toARGB32(),
      circleRadius: 6.4,
      circleBlur: 0.5,
      circleOpacity: 0.92,
      circleStrokeColor: const Color(0xFFFFF0C2).toARGB32(),
      circleStrokeOpacity: 0.88,
      circleStrokeWidth: 1.2,
    );
  }

  Future<void> _updateMarkerSelection(
    String markerId, {
    bool keepSelectedState = true,
  }) async {
    final markerManager = _markerManager;
    if (markerManager == null) {
      _selectedMarkerId = keepSelectedState ? markerId : null;
      return;
    }

    final previousMarkerId = _selectedMarkerId;
    if (previousMarkerId != null && previousMarkerId != markerId) {
      final previousAnnotation = _markerAnnotationsById[previousMarkerId];
      final previousMarker = _markersById[previousMarkerId];
      if (previousAnnotation != null && previousMarker != null) {
        _applyMarkerVisual(
          previousAnnotation,
          marker: previousMarker,
          isSelected: false,
        );
        await markerManager.update(previousAnnotation);
      }
    }

    final nextAnnotation = _markerAnnotationsById[markerId];
    final nextMarker = _markersById[markerId];
    if (nextAnnotation != null && nextMarker != null) {
      _applyMarkerVisual(
        nextAnnotation,
        marker: nextMarker,
        isSelected: keepSelectedState,
      );
      await markerManager.update(nextAnnotation);
    }

    _selectedMarkerId = keepSelectedState ? markerId : null;
    notifyListeners();
  }

  Future<void> _setMarkerHidden(String markerId, bool isHidden) async {
    final markerManager = _markerManager;
    final annotation = _markerAnnotationsById[markerId];
    final marker = _markersById[markerId];
    if (markerManager == null || annotation == null || marker == null) {
      return;
    }

    _applyMarkerVisual(
      annotation,
      marker: marker,
      isSelected: false,
      isHidden: isHidden,
    );
    await markerManager.update(annotation);
  }

  void _applyMarkerVisual(
    CircleAnnotation annotation, {
    required GlobeMarkerEntity marker,
    required bool isSelected,
    bool isHidden = false,
  }) {
    if (isHidden) {
      annotation.circleOpacity = 0.0;
      annotation.circleStrokeOpacity = 0.0;
      annotation.circleRadius = 0.1;
      annotation.circleStrokeWidth = 0.0;
      return;
    }

    annotation.circleColor = isSelected
        ? const Color(0xFFFFC36B).toARGB32()
        : _markerColor(marker.type).toARGB32();
    annotation.circleRadius = isSelected ? 7.8 : 6.4;
    annotation.circleBlur = isSelected ? 0.42 : 0.5;
    annotation.circleStrokeColor = const Color(0xFFFFF3D6).toARGB32();
    annotation.circleStrokeOpacity = isSelected ? 0.96 : 0.88;
    annotation.circleStrokeWidth = isSelected ? 1.6 : 1.2;
    annotation.circleOpacity = isSelected ? 0.98 : 0.92;
  }

  Color _markerColor(GlobeMarkerType type) {
    switch (type) {
      case GlobeMarkerType.official:
        return const Color(0xFFFFB347);
      case GlobeMarkerType.community:
        return const Color(0xFFFFC46A);
      case GlobeMarkerType.mixed:
        return const Color(0xFFFFA94D);
    }
  }
}
