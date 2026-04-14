import 'dart:async';
import 'dart:convert';

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
  static const String _overviewSourceId = 'map-home-overview-source';
  static const String _overviewCircleLayerId = 'map-home-overview-circle-layer';
  static const String _overviewCountLayerId = 'map-home-overview-count-layer';
  static const String _citySourceId = 'map-home-city-source';
  static const String _clusterCircleLayerId = 'map-home-cluster-circle-layer';
  static const String _clusterCountLayerId = 'map-home-cluster-count-layer';
  static const String _cityPointLayerId = 'map-home-city-point-layer';
  static const double _clusterRadius = 38;
  static const double _clusterMaxZoom = 10;
  static const double _overviewMaxZoom = 3.2;
  static const double _cityMinZoom = 3.2;
  static const double _markerVisibilityHysteresis = 0.08;

  static const List<_OverviewRegionConfig> _overviewRegionConfigs =
      <_OverviewRegionConfig>[
        _OverviewRegionConfig(
          id: 'japan_kanto',
          placeIds: <String>['tokyo', 'yokohama'],
          focusZoom: 5.1,
        ),
        _OverviewRegionConfig(
          id: 'japan_kansai',
          placeIds: <String>['osaka'],
          focusZoom: 5.1,
        ),
        _OverviewRegionConfig(
          id: 'china_north',
          placeIds: <String>['beijing', 'tianjin'],
          focusZoom: 4.8,
        ),
        _OverviewRegionConfig(
          id: 'china_east',
          placeIds: <String>['shanghai', 'suzhou'],
          focusZoom: 4.9,
        ),
        _OverviewRegionConfig(
          id: 'china_south',
          placeIds: <String>['guangzhou', 'hong_kong'],
          focusZoom: 4.8,
        ),
        _OverviewRegionConfig(
          id: 'china_west',
          placeIds: <String>['lhasa'],
          focusZoom: 4.8,
        ),
        _OverviewRegionConfig(
          id: 'usa_east',
          placeIds: <String>['new_york'],
          focusZoom: 4.8,
        ),
        _OverviewRegionConfig(
          id: 'usa_west',
          placeIds: <String>['los_angeles'],
          focusZoom: 4.8,
        ),
        _OverviewRegionConfig(
          id: 'russia_northwest',
          placeIds: <String>['moscow', 'saint_petersburg'],
          focusZoom: 4.6,
        ),
        _OverviewRegionConfig(
          id: 'germany',
          placeIds: <String>['berlin', 'frankfurt', 'munich'],
          focusZoom: 4.8,
        ),
        _OverviewRegionConfig(
          id: 'france',
          placeIds: <String>['paris'],
          focusZoom: 4.8,
        ),
        _OverviewRegionConfig(
          id: 'united_kingdom',
          placeIds: <String>['london'],
          focusZoom: 4.8,
        ),
        _OverviewRegionConfig(
          id: 'turkey',
          placeIds: <String>['istanbul'],
          focusZoom: 4.9,
        ),
        _OverviewRegionConfig(
          id: 'canada',
          placeIds: <String>['toronto'],
          focusZoom: 4.8,
        ),
        _OverviewRegionConfig(
          id: 'argentina',
          placeIds: <String>['buenos_aires'],
          focusZoom: 4.8,
        ),
        _OverviewRegionConfig(
          id: 'brazil',
          placeIds: <String>['sao_paulo'],
          focusZoom: 4.8,
        ),
        _OverviewRegionConfig(
          id: 'egypt',
          placeIds: <String>['cairo'],
          focusZoom: 4.9,
        ),
        _OverviewRegionConfig(
          id: 'south_africa',
          placeIds: <String>['cape_town'],
          focusZoom: 4.8,
        ),
        _OverviewRegionConfig(
          id: 'australia_east',
          placeIds: <String>['sydney', 'melbourne'],
          focusZoom: 4.9,
        ),
        _OverviewRegionConfig(
          id: 'new_zealand',
          placeIds: <String>['wellington'],
          focusZoom: 5.0,
        ),
      ];

  MapHomeViewStatus _status = MapHomeViewStatus.loading;
  final double _initialMarkerZoom;
  MapHomeLightPreset _lightPreset = MapHomeLightPreset.day;
  MapHomeBasemapLanguage _basemapLanguage = MapHomeBasemapLanguage.en;
  List<GlobeMarkerEntity> _markers = <GlobeMarkerEntity>[];
  GeoJsonSource? _overviewSource;
  GeoJsonSource? _citySource;
  MapboxMap? _mapboxMap;
  String? _errorDetails;
  int _mapWidgetVersion = 0;
  bool _isApplyingStyle = false;
  bool _areMarkersVisible = true;
  bool _isScaleBarVisible = true;
  PlaceEntity? _selectedPlace;
  String? _selectedMarkerId;
  final Map<String, PlaceEntity> _placesById = <String, PlaceEntity>{};
  final Map<String, GlobeMarkerEntity> _markersById =
      <String, GlobeMarkerEntity>{};
  final Map<String, GlobeMarkerEntity> _markersByPlaceId =
      <String, GlobeMarkerEntity>{};

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

  MapHomeController({required double initialMarkerZoom})
    : _initialMarkerZoom = initialMarkerZoom;

  void onMapCreated(MapboxMap mapboxMap) {
    _overviewSource = null;
    _citySource = null;
    _mapboxMap = mapboxMap;
    _areMarkersVisible = true;
    _status = MapHomeViewStatus.loading;
    _errorDetails = null;
    notifyListeners();
  }

  void onMapTap(MapContentGestureContext context) {
    unawaited(_handleMapTap(context));
  }

  void onCameraChanged(CameraChangedEventData event) {
    unawaited(_syncMarkerVisibilityWithZoom(event.cameraState.zoom));
  }

  Future<void> onStyleLoaded() async {
    final mapboxMap = _mapboxMap;
    if (mapboxMap == null) {
      return;
    }

    try {
      _isApplyingStyle = true;
      await _loadMapData();
      await _applyMapStyle(
        mapboxMap,
        lightPreset: _lightPreset,
        basemapLanguage: _basemapLanguage,
        includeProjection: true,
      );
      await _syncMarkers();
      await _refreshMarkerVisuals();
      await _applyMarkerLayerVisibility(_areMarkersVisible);
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
    _overviewSource = null;
    _citySource = null;
    _mapWidgetVersion += 1;
    _mapboxMap = null;
    _areMarkersVisible = true;
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

  Future<void> _loadMapData() async {
    final data = await MapHomeMockData.load();
    _markers = data.markers;
    _placesById
      ..clear()
      ..addEntries(data.places.map((place) => MapEntry(place.id, place)));
    _markersById
      ..clear()
      ..addEntries(data.markers.map((marker) => MapEntry(marker.id, marker)));
    _markersByPlaceId
      ..clear()
      ..addEntries(
        data.markers.map((marker) => MapEntry(marker.placeId, marker)),
      );
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

    // 先显示选中态，再执行飞行动画，让交互反馈更直接。
    _selectedMarkerId = markerId;
    await _refreshMarkerVisuals();

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

    // 卡片显示后隐藏当前城市点，避免主焦点重复。
    _selectedPlace = place;
    await _refreshMarkerVisuals();
    notifyListeners();
  }

  Future<void> clearSelectedPlace() async {
    _selectedPlace = null;
    _selectedMarkerId = null;
    await _refreshMarkerVisuals();
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

    await _removeMarkerLayersIfNeeded(mapboxMap);
    await _removeMarkerSourcesIfNeeded(mapboxMap);

    // 全球视角先显示“区域层”，避免跨大区域的自动 clustering 把空间结构压扁。
    final overviewSource = GeoJsonSource(
      id: _overviewSourceId,
      data: _buildOverviewFeatureCollection(),
    );
    await mapboxMap.style.addSource(overviewSource);
    _overviewSource = overviewSource;

    final citySource = GeoJsonSource(
      id: _citySourceId,
      data: _buildMarkerFeatureCollection(),
      cluster: true,
      clusterRadius: _clusterRadius,
      clusterMaxZoom: _clusterMaxZoom,
      clusterMinPoints: 2,
    );
    await mapboxMap.style.addSource(citySource);
    _citySource = citySource;

    await mapboxMap.style.addLayer(_buildOverviewCircleLayer());
    await mapboxMap.style.addLayer(_buildOverviewCountLayer());
    await mapboxMap.style.addLayer(_buildClusterCircleLayer());
    await mapboxMap.style.addLayer(_buildClusterCountLayer());
    await mapboxMap.style.addLayer(_buildCityPointLayer());
  }

  Future<void> _syncMarkerVisibilityWithZoom(double zoom) async {
    final shouldShowMarkers = _shouldShowMarkersForZoom(zoom);
    if (shouldShowMarkers == _areMarkersVisible) {
      return;
    }

    _areMarkersVisible = shouldShowMarkers;
    await _applyMarkerLayerVisibility(shouldShowMarkers);
  }

  bool _shouldShowMarkersForZoom(double zoom) {
    if (_areMarkersVisible) {
      return zoom >= (_initialMarkerZoom - _markerVisibilityHysteresis);
    }
    return zoom >= _initialMarkerZoom;
  }

  Future<void> _applyMarkerLayerVisibility(bool isVisible) async {
    final mapboxMap = _mapboxMap;
    if (mapboxMap == null) {
      return;
    }

    final visibilityValue = isVisible ? 'visible' : 'none';
    for (final layerId in <String>[
      _overviewCircleLayerId,
      _overviewCountLayerId,
      _clusterCircleLayerId,
      _clusterCountLayerId,
      _cityPointLayerId,
    ]) {
      if (await mapboxMap.style.styleLayerExists(layerId)) {
        await mapboxMap.style.setStyleLayerProperty(
          layerId,
          'visibility',
          visibilityValue,
        );
      }
    }
  }

  Future<void> _refreshMarkerVisuals() async {
    await _overviewSource?.updateGeoJSON(_buildOverviewFeatureCollection());
    await _citySource?.updateGeoJSON(_buildMarkerFeatureCollection());
  }

  Future<void> _handleMapTap(MapContentGestureContext context) async {
    final mapboxMap = _mapboxMap;
    if (mapboxMap == null || !isReady || _isApplyingStyle) {
      return;
    }

    try {
      final features = await mapboxMap.queryRenderedFeatures(
        RenderedQueryGeometry.fromScreenCoordinate(context.touchPosition),
        RenderedQueryOptions(
          layerIds: <String>[
            _overviewCircleLayerId,
            _overviewCountLayerId,
            _clusterCircleLayerId,
            _clusterCountLayerId,
            _cityPointLayerId,
          ],
        ),
      );

      QueriedRenderedFeature? tappedFeature;
      for (final feature in features) {
        if (feature == null) {
          continue;
        }
        tappedFeature = feature;
        break;
      }

      if (tappedFeature == null) {
        return;
      }

      final sourceId = tappedFeature.queriedFeature.source;
      final featureMap = tappedFeature.queriedFeature.feature;
      final properties = _readFeatureProperties(featureMap);

      if (sourceId == _overviewSourceId) {
        await _zoomIntoOverviewRegion(featureMap, properties);
        return;
      }

      if (_isClusterFeature(properties)) {
        await _zoomIntoCluster(featureMap);
        return;
      }

      final markerId = _readStringProperty(properties, 'markerId');
      if (markerId == null) {
        return;
      }

      await selectMarkerById(markerId);
    } catch (_) {
      // 点击未命中要保持地图可继续浏览，不打断主交互。
    }
  }

  Future<void> _zoomIntoOverviewRegion(
    Map<String?, Object?> feature,
    Map<String, Object?> properties,
  ) async {
    final mapboxMap = _mapboxMap;
    if (mapboxMap == null) {
      return;
    }

    final coordinates = _readCoordinates(feature);
    if (coordinates == null) {
      return;
    }

    final currentCamera = await mapboxMap.getCameraState();
    final focusZoom = _toDouble(properties['focusZoom']) ?? 4.8;

    await mapboxMap.easeTo(
      CameraOptions(
        center: Point(coordinates: Position(coordinates.$1, coordinates.$2)),
        zoom: focusZoom,
        pitch: currentCamera.pitch,
        bearing: currentCamera.bearing,
      ),
      MapAnimationOptions(duration: 900),
    );
  }

  Future<void> _zoomIntoCluster(Map<String?, Object?> feature) async {
    final mapboxMap = _mapboxMap;
    if (mapboxMap == null) {
      return;
    }

    final expansionZoomValue = await mapboxMap.getGeoJsonClusterExpansionZoom(
      _citySourceId,
      feature,
    );
    final coordinates = _readCoordinates(feature);
    if (coordinates == null) {
      return;
    }

    final currentCamera = await mapboxMap.getCameraState();
    final expansionZoom =
        _parseDouble(expansionZoomValue.value) ?? currentCamera.zoom + 1.5;

    await mapboxMap.easeTo(
      CameraOptions(
        center: Point(coordinates: Position(coordinates.$1, coordinates.$2)),
        zoom: expansionZoom + 0.35,
        pitch: currentCamera.pitch,
        bearing: currentCamera.bearing,
      ),
      MapAnimationOptions(duration: 950),
    );
  }

  Future<void> _removeMarkerLayersIfNeeded(MapboxMap mapboxMap) async {
    for (final layerId in <String>[
      _overviewCountLayerId,
      _overviewCircleLayerId,
      _clusterCountLayerId,
      _clusterCircleLayerId,
      _cityPointLayerId,
    ]) {
      if (await mapboxMap.style.styleLayerExists(layerId)) {
        await mapboxMap.style.removeStyleLayer(layerId);
      }
    }
  }

  Future<void> _removeMarkerSourcesIfNeeded(MapboxMap mapboxMap) async {
    for (final sourceId in <String>[_overviewSourceId, _citySourceId]) {
      if (await mapboxMap.style.styleSourceExists(sourceId)) {
        await mapboxMap.style.removeStyleSource(sourceId);
      }
    }
  }

  String _buildOverviewFeatureCollection() {
    final features = _overviewRegionConfigs
        .map(_buildOverviewFeature)
        .whereType<Map<String, Object>>()
        .toList(growable: false);

    return jsonEncode(<String, Object>{
      'type': 'FeatureCollection',
      'features': features,
    });
  }

  Map<String, Object>? _buildOverviewFeature(_OverviewRegionConfig config) {
    final memberMarkers = config.placeIds
        .map((placeId) => _markersByPlaceId[placeId])
        .whereType<GlobeMarkerEntity>()
        .toList(growable: false);
    if (memberMarkers.isEmpty) {
      return null;
    }

    final center = _computeCenter(memberMarkers);
    if (center == null) {
      return null;
    }
    final isSelectedRegion =
        _selectedMarkerId != null &&
        memberMarkers.any((marker) => marker.id == _selectedMarkerId);

    return <String, Object>{
      'type': 'Feature',
      'geometry': <String, Object>{
        'type': 'Point',
        'coordinates': <double>[center.$1, center.$2],
      },
      'properties': <String, Object>{
        'regionId': config.id,
        'pointCount': memberMarkers.length,
        'focusZoom': config.focusZoom,
        'isSelected': isSelectedRegion,
      },
    };
  }

  String _buildMarkerFeatureCollection() {
    final features = _markers.map(_buildMarkerFeature).toList(growable: false);
    return jsonEncode(<String, Object>{
      'type': 'FeatureCollection',
      'features': features,
    });
  }

  Map<String, Object> _buildMarkerFeature(GlobeMarkerEntity marker) {
    final isSelectedMarker = _selectedMarkerId == marker.id;
    final isHiddenMarker = isSelectedMarker && _selectedPlace != null;

    return <String, Object>{
      'type': 'Feature',
      'geometry': <String, Object>{
        'type': 'Point',
        'coordinates': <double>[marker.longitude, marker.latitude],
      },
      'properties': <String, Object>{
        'markerId': marker.id,
        'placeId': marker.placeId,
        'markerType': _markerTypePropertyValue(marker.type),
        'isSelected': isSelectedMarker,
        'isHidden': isHiddenMarker,
      },
    };
  }

  CircleLayer _buildOverviewCircleLayer() {
    return CircleLayer(
      id: _overviewCircleLayerId,
      slot: 'top',
      sourceId: _overviewSourceId,
      maxZoom: _overviewMaxZoom,
      circleColorExpression: <Object>[
        'case',
        <Object>[
          'boolean',
          <Object>['get', 'isSelected'],
          false,
        ],
        '#FFC36B',
        '#FFB347',
      ],
      circleRadiusExpression: <Object>[
        'interpolate',
        <Object>['linear'],
        <Object>['zoom'],
        0.5,
        8.6,
        _overviewMaxZoom,
        12.8,
      ],
      circleBlur: 0.1,
      circleOpacity: 0.96,
      circleStrokeColor: const Color(0xFFFFF3D6).toARGB32(),
      circleStrokeOpacity: 0.92,
      circleStrokeWidth: 1.6,
      circleEmissiveStrength: 1.0,
    );
  }

  SymbolLayer _buildOverviewCountLayer() {
    return SymbolLayer(
      id: _overviewCountLayerId,
      slot: 'top',
      sourceId: _overviewSourceId,
      maxZoom: _overviewMaxZoom,
      textFieldExpression: <Object>[
        'to-string',
        <Object>['get', 'pointCount'],
      ],
      textSize: 13,
      textColor: const Color(0xFFFFFBF2).toARGB32(),
      textHaloColor: const Color(0xFF7A4010).toARGB32(),
      textHaloBlur: 0.5,
      textHaloWidth: 0.8,
      textAllowOverlap: true,
      textIgnorePlacement: true,
    );
  }

  CircleLayer _buildClusterCircleLayer() {
    return CircleLayer(
      id: _clusterCircleLayerId,
      slot: 'top',
      sourceId: _citySourceId,
      minZoom: _cityMinZoom,
      filter: <Object>['has', 'point_count'],
      circleColorExpression: <Object>[
        'step',
        <Object>['get', 'point_count'],
        '#FFB347',
        6,
        '#FFA14A',
        16,
        '#FF8E36',
      ],
      circleRadiusExpression: <Object>[
        'interpolate',
        <Object>['linear'],
        <Object>['zoom'],
        _cityMinZoom,
        8.8,
        4.5,
        10.8,
        8.0,
        15.2,
      ],
      circleBlur: 0.12,
      circleOpacity: 0.96,
      circleStrokeColor: const Color(0xFFFFF3D6).toARGB32(),
      circleStrokeOpacity: 0.92,
      circleStrokeWidth: 1.6,
      circleEmissiveStrength: 1.0,
    );
  }

  SymbolLayer _buildClusterCountLayer() {
    return SymbolLayer(
      id: _clusterCountLayerId,
      slot: 'top',
      sourceId: _citySourceId,
      minZoom: _cityMinZoom,
      filter: <Object>['has', 'point_count'],
      textFieldExpression: <Object>['get', 'point_count_abbreviated'],
      textSize: 13,
      textColor: const Color(0xFFFFFBF2).toARGB32(),
      textHaloColor: const Color(0xFF7A4010).toARGB32(),
      textHaloBlur: 0.5,
      textHaloWidth: 0.8,
      textAllowOverlap: true,
      textIgnorePlacement: true,
    );
  }

  CircleLayer _buildCityPointLayer() {
    return CircleLayer(
      id: _cityPointLayerId,
      slot: 'top',
      sourceId: _citySourceId,
      minZoom: _cityMinZoom,
      filter: <Object>[
        '!',
        <Object>['has', 'point_count'],
      ],
      circleColorExpression: <Object>[
        'case',
        <Object>[
          'boolean',
          <Object>['get', 'isSelected'],
          false,
        ],
        '#FFC36B',
        <Object>[
          'match',
          <Object>['get', 'markerType'],
          'community',
          '#FFC46A',
          'mixed',
          '#FFA94D',
          '#FFB347',
        ],
      ],
      circleRadiusExpression: <Object>[
        'interpolate',
        <Object>['linear'],
        <Object>['zoom'],
        _cityMinZoom,
        <Object>[
          'case',
          <Object>[
            'boolean',
            <Object>['get', 'isHidden'],
            false,
          ],
          0.1,
          <Object>[
            'boolean',
            <Object>['get', 'isSelected'],
            false,
          ],
          5.0,
          3.6,
        ],
        4.5,
        <Object>[
          'case',
          <Object>[
            'boolean',
            <Object>['get', 'isHidden'],
            false,
          ],
          0.1,
          <Object>[
            'boolean',
            <Object>['get', 'isSelected'],
            false,
          ],
          8.2,
          6.3,
        ],
        8.0,
        <Object>[
          'case',
          <Object>[
            'boolean',
            <Object>['get', 'isHidden'],
            false,
          ],
          0.1,
          <Object>[
            'boolean',
            <Object>['get', 'isSelected'],
            false,
          ],
          12.0,
          9.6,
        ],
        11.0,
        <Object>[
          'case',
          <Object>[
            'boolean',
            <Object>['get', 'isHidden'],
            false,
          ],
          0.1,
          <Object>[
            'boolean',
            <Object>['get', 'isSelected'],
            false,
          ],
          16.0,
          12.8,
        ],
        13.0,
        <Object>[
          'case',
          <Object>[
            'boolean',
            <Object>['get', 'isHidden'],
            false,
          ],
          0.1,
          <Object>[
            'boolean',
            <Object>['get', 'isSelected'],
            false,
          ],
          18.4,
          14.8,
        ],
      ],
      circleBlurExpression: <Object>[
        'case',
        <Object>[
          'boolean',
          <Object>['get', 'isHidden'],
          false,
        ],
        0.0,
        <Object>[
          'boolean',
          <Object>['get', 'isSelected'],
          false,
        ],
        0.42,
        0.5,
      ],
      circleOpacityExpression: <Object>[
        'case',
        <Object>[
          'boolean',
          <Object>['get', 'isHidden'],
          false,
        ],
        0.0,
        <Object>[
          'boolean',
          <Object>['get', 'isSelected'],
          false,
        ],
        0.98,
        0.92,
      ],
      circleStrokeColor: const Color(0xFFFFF3D6).toARGB32(),
      circleStrokeOpacityExpression: <Object>[
        'case',
        <Object>[
          'boolean',
          <Object>['get', 'isHidden'],
          false,
        ],
        0.0,
        <Object>[
          'boolean',
          <Object>['get', 'isSelected'],
          false,
        ],
        0.96,
        0.88,
      ],
      circleStrokeWidthExpression: <Object>[
        'case',
        <Object>[
          'boolean',
          <Object>['get', 'isHidden'],
          false,
        ],
        0.0,
        <Object>[
          'boolean',
          <Object>['get', 'isSelected'],
          false,
        ],
        1.6,
        1.2,
      ],
      circleEmissiveStrength: 1.0,
    );
  }

  Map<String, Object?> _readFeatureProperties(Map<String?, Object?> feature) {
    final rawProperties = feature['properties'];
    if (rawProperties is Map) {
      return rawProperties.cast<String, Object?>();
    }
    return const <String, Object?>{};
  }

  bool _isClusterFeature(Map<String, Object?> properties) {
    return properties['cluster'] == true || properties['point_count'] != null;
  }

  (double, double)? _computeCenter(List<GlobeMarkerEntity> markers) {
    if (markers.isEmpty) {
      return null;
    }

    var longitudeSum = 0.0;
    var latitudeSum = 0.0;
    for (final marker in markers) {
      longitudeSum += marker.longitude;
      latitudeSum += marker.latitude;
    }

    return (longitudeSum / markers.length, latitudeSum / markers.length);
  }

  (double, double)? _readCoordinates(Map<String?, Object?> feature) {
    final geometry = feature['geometry'];
    if (geometry is! Map) {
      return null;
    }

    final rawCoordinates = geometry['coordinates'];
    if (rawCoordinates is! List || rawCoordinates.length < 2) {
      return null;
    }

    final longitude = _toDouble(rawCoordinates[0]);
    final latitude = _toDouble(rawCoordinates[1]);
    if (longitude == null || latitude == null) {
      return null;
    }

    return (longitude, latitude);
  }

  String? _readStringProperty(Map<String, Object?> properties, String key) {
    final value = properties[key];
    if (value is String && value.isNotEmpty) {
      return value;
    }
    return null;
  }

  String _markerTypePropertyValue(GlobeMarkerType type) {
    switch (type) {
      case GlobeMarkerType.official:
        return 'official';
      case GlobeMarkerType.community:
        return 'community';
      case GlobeMarkerType.mixed:
        return 'mixed';
    }
  }

  double? _parseDouble(String? value) {
    if (value == null) {
      return null;
    }
    return double.tryParse(value);
  }

  double? _toDouble(Object? value) {
    if (value is num) {
      return value.toDouble();
    }
    return null;
  }
}

class _OverviewRegionConfig {
  const _OverviewRegionConfig({
    required this.id,
    required this.placeIds,
    required this.focusZoom,
  });

  final String id;
  final List<String> placeIds;
  final double focusZoom;
}
