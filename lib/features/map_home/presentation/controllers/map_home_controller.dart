import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import '../../../../core/error/app_exception.dart';
import '../../domain/entities/globe_marker_entity.dart';
import '../../domain/entities/map_home_data_bundle.dart';
import '../../domain/entities/map_home_region_entity.dart';
import '../../domain/entities/place_entity.dart';
import '../../domain/repositories/map_home_repository.dart';

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
  static const double _overviewMarkerRadius = 10.0;
  static const double _clusterMarkerRadius = 11.0;
  static const double _cityMarkerRadius = 8.4;
  static const double _selectedCityMarkerRadius = 10.2;

  MapHomeController({
    required this.mapHomeRepository,
    required double initialMarkerZoom,
  }) : _initialMarkerZoom = initialMarkerZoom;

  final MapHomeRepository mapHomeRepository;
  final double _initialMarkerZoom;

  MapHomeViewStatus _status = MapHomeViewStatus.loading;
  MapHomeLightPreset _lightPreset = MapHomeLightPreset.day;
  MapHomeBasemapLanguage _basemapLanguage = MapHomeBasemapLanguage.en;
  List<GlobeMarkerEntity> _markers = <GlobeMarkerEntity>[];
  List<MapHomeRegionEntity> _regions = <MapHomeRegionEntity>[];
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
  final Map<String, MapHomeRegionEntity> _regionsById =
      <String, MapHomeRegionEntity>{};
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

  void onMapCreated(MapboxMap mapboxMap) {
    _log('onMapCreated');
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
      _log('onStyleLoaded skipped because mapboxMap is null');
      return;
    }

    try {
      _isApplyingStyle = true;
      _log('onStyleLoaded start');
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
      _log('onStyleLoaded ready');
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
      _lightPreset = nextPreset;
      _status = MapHomeViewStatus.ready;
      _errorDetails = null;
      _log('toggleLightPreset => ${nextPreset.styleValue}');
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
    _log('onMapLoadError: $_errorDetails');
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
    _log('syncBasemapLanguageWithLocale => ${nextLanguage.styleValue}');

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
    _log('retry => rebuild map widget');
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
    // Firestore 閻庢鍠栭崐鎼佹偉閸洖鐭楁い蹇撴閼稿墎绱撴担鍝勬瀺缂佹梹鎸抽弻銊モ枎閹烘繂娈?UI闂佹寧绋戞總鏃傜箔婢舵劕绠┑鐘插€搁弬褍鈹戦纰卞剰闁诡喗顨堢划鈺咁敍濞嗗海绠氶梺璇″弾閸ㄥ啿煤閸ф绠抽柕澶涢檮閻﹀綊姊婚崶銊ョ祷闁糕晛鏈妵鍕偨閸涘﹥銆?
    _errorDetails = error is AppException ? null : error.toString();
    _log('setError => ${error.runtimeType}: $_errorDetails');
  }

  Future<void> _loadMapData() async {
    final MapHomeDataBundle data = await mapHomeRepository.loadMapHomeData();
    _markers = data.markers;
    _regions = data.regions;
    _placesById
      ..clear()
      ..addEntries(data.places.map((place) => MapEntry(place.id, place)));
    _regionsById
      ..clear()
      ..addEntries(data.regions.map((region) => MapEntry(region.id, region)));
    _markersById
      ..clear()
      ..addEntries(data.markers.map((marker) => MapEntry(marker.id, marker)));
    _markersByPlaceId
      ..clear()
      ..addEntries(
        data.markers.map((marker) => MapEntry(marker.placeId, marker)),
      );

    _log(
      'loadMapData => places=${_placesById.length}, markers=${_markers.length}, regions=${_regionsById.length}',
    );
  }

  Future<void> selectMarkerById(String markerId) async {
    _log('selectMarkerById => $markerId');
    final marker = _markersById[markerId];
    if (marker == null) {
      _log('selectMarkerById => marker not found');
      return;
    }

    await selectPlaceById(marker.placeId, markerId: markerId);
  }

  Future<void> selectPlaceById(String placeId, {String? markerId}) async {
    _log('selectPlaceById => placeId=$placeId markerId=$markerId');
    final place = _placesById[placeId];
    if (place == null) {
      _log('selectPlaceById => place not found');
      return;
    }

    final marker = markerId != null ? _markersById[markerId] : null;
    final fallbackMarker = marker ?? _markersByPlaceId[placeId];
    if (fallbackMarker == null) {
      _log(
        'selectPlaceById => fallback marker not found, use place coordinates',
      );
    }
    // 鍏堟爣璁伴€変腑鎬侊紝鍐嶆墽琛岄琛屽姩鐢伙紝璁╁崱鐗囧拰鍦板浘鐘舵€佸悓姝ユ洿鐩存帴.
    _selectedMarkerId = fallbackMarker?.id;
    await _refreshMarkerVisuals();

    final mapboxMap = _mapboxMap;
    if (mapboxMap != null) {
      final cameraState = await mapboxMap.getCameraState();
      final targetCoordinates = fallbackMarker == null
          ? (place.longitude, place.latitude)
          : _resolveMarkerCoordinates(fallbackMarker) ??
                (place.longitude, place.latitude);
      await mapboxMap.flyTo(
        CameraOptions(
          center: Point(
            coordinates: Position(targetCoordinates.$1, targetCoordinates.$2),
          ),
          zoom: place.flyToZoom,
          pitch: cameraState.pitch,
          bearing: cameraState.bearing,
        ),
        MapAnimationOptions(duration: 1800),
      );
    }

    _selectedPlace = place;
    await _refreshMarkerVisuals();
    _log('selectPlaceById => selectedPlace=${place.id}');
    notifyListeners();
  }

  Future<void> clearSelectedPlace() async {
    _log('clearSelectedPlace');
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
    // 鍏ㄥ眬瑙嗚鍏堟樉绀哄尯鍩熷眰锛岄伩鍏嶈法澶у尯鍩熺殑鑷姩 clustering 鍘嬫墎绌洪棿缁撴瀯.
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
    _log('syncMarkers => layers added');
  }

  Future<void> _syncMarkerVisibilityWithZoom(double zoom) async {
    final shouldShowMarkers = _shouldShowMarkersForZoom(zoom);
    if (shouldShowMarkers == _areMarkersVisible) {
      return;
    }

    _areMarkersVisible = shouldShowMarkers;
    _log('marker visibility => $_areMarkersVisible at zoom=$zoom');
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
      _log('tap => x=${context.touchPosition.x}, y=${context.touchPosition.y}');

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

      _log('tap => raw feature count=${features.length}');

      final tappedFeature = _firstValidFeature(features);
      if (tappedFeature == null) {
        _log('tap => no feature hit');
        return;
      }

      final sourceId = tappedFeature.queriedFeature.source;
      final featureMap = tappedFeature.queriedFeature.feature;
      final properties = _readFeatureProperties(featureMap);
      _log(
        'tap => source=$sourceId '
        'markerId=${_readStringProperty(properties, 'markerId')} '
        'id=${_readStringProperty(properties, 'id')} '
        'placeId=${_readStringProperty(properties, 'placeId')} '
        'cluster=${properties['cluster']} '
        'point_count=${properties['point_count']}',
      );

      if (sourceId == _overviewSourceId) {
        _log('tap => overview tapped, zoom only');
        await _zoomIntoOverviewRegion(featureMap, properties);
        return;
      }

      if (_isClusterFeature(properties)) {
        _log('tap => cluster tapped, zoom only');
        await _zoomIntoCluster(featureMap);
        return;
      }

      _log('tap => city point tapped, try select place');
      await _handleCityFeatureTap(tappedFeature);
    } catch (error) {
      _log('tap => error: $error');
    }
  }

  QueriedRenderedFeature? _firstValidFeature(
    List<QueriedRenderedFeature?> features,
  ) {
    for (final feature in features) {
      if (feature != null) {
        return feature;
      }
    }
    return null;
  }

  Future<void> _handleCityFeatureTap(
    QueriedRenderedFeature tappedFeature,
  ) async {
    final featureMap = tappedFeature.queriedFeature.feature;
    final properties = _readFeatureProperties(featureMap);

    final markerId =
        _readStringProperty(properties, 'markerId') ??
        _readStringProperty(properties, 'id');
    final placeId = _readStringProperty(properties, 'placeId');

    _log('cityTap => markerId=$markerId, placeId=$placeId');

    if (markerId != null) {
      await selectMarkerById(markerId);
      if (_selectedPlace != null) {
        return;
      }
      _log('cityTap => marker selection did not produce selectedPlace');
    }

    if (placeId != null) {
      await selectPlaceById(placeId, markerId: markerId);
      return;
    }

    _log('cityTap => no markerId/placeId found');
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
    _log('overview zoom => focusZoom=$focusZoom');

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
    _log('cluster zoom => expansionZoom=$expansionZoom');

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
    // 区域配置改成动态读取，只为命中的 region 生成 overview 聚合.
    final features = _regions
        .map(_buildOverviewFeature)
        .whereType<Map<String, Object>>()
        .toList(growable: false);

    return jsonEncode(<String, Object>{
      'type': 'FeatureCollection',
      'features': features,
    });
  }

  Map<String, Object>? _buildOverviewFeature(MapHomeRegionEntity region) {
    final memberPoints = _placesById.values
        .where((place) => place.regionId == region.id)
        .map(_resolveMarkerPointForPlace)
        .whereType<_ResolvedMarkerPoint>()
        .toList(growable: false);
    if (memberPoints.isEmpty) {
      return null;
    }

    final center = _computeCenter(
      memberPoints
          .map((point) => (point.longitude, point.latitude))
          .toList(growable: false),
    );
    if (center == null) {
      return null;
    }

    final isSelectedRegion =
        _selectedMarkerId != null &&
        memberPoints.any((point) => point.marker.id == _selectedMarkerId);

    return <String, Object>{
      'type': 'Feature',
      'geometry': <String, Object>{
        'type': 'Point',
        'coordinates': <double>[center.$1, center.$2],
      },
      'properties': <String, Object>{
        'regionId': region.id,
        'pointCount': memberPoints.length,
        'focusZoom': region.focusZoom,
        'isSelected': isSelectedRegion,
      },
    };
  }

  String _buildMarkerFeatureCollection() {
    final features = _markers
        .map(_buildMarkerFeature)
        .whereType<Map<String, Object>>()
        .toList(growable: false);
    return jsonEncode(<String, Object>{
      'type': 'FeatureCollection',
      'features': features,
    });
  }

  Map<String, Object>? _buildMarkerFeature(GlobeMarkerEntity marker) {
    final resolvedPoint = _resolveMarkerPoint(marker);
    if (resolvedPoint == null) {
      return null;
    }

    final isSelectedMarker = _selectedMarkerId == marker.id;
    final isHiddenMarker = isSelectedMarker && _selectedPlace != null;

    return <String, Object>{
      'type': 'Feature',
      'geometry': <String, Object>{
        'type': 'Point',
        'coordinates': <double>[
          resolvedPoint.longitude,
          resolvedPoint.latitude,
        ],
      },
      'properties': <String, Object>{
        'id': marker.id,
        'markerId': marker.id,
        'placeId': marker.placeId,
        'pointType': 'city',
        'markerType': marker.type.rawValue,
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
      circleRadius: _overviewMarkerRadius,
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
      circleRadius: _clusterMarkerRadius,
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
        _selectedCityMarkerRadius,
        _cityMarkerRadius,
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

  (double, double)? _computeCenter(List<(double, double)> points) {
    if (points.isEmpty) {
      return null;
    }

    var longitudeSum = 0.0;
    var latitudeSum = 0.0;
    for (final point in points) {
      longitudeSum += point.$1;
      latitudeSum += point.$2;
    }

    return (longitudeSum / points.length, latitudeSum / points.length);
  }

  _ResolvedMarkerPoint? _resolveMarkerPoint(GlobeMarkerEntity marker) {
    final place = _placesById[marker.placeId];
    if (place == null) {
      return null;
    }

    final coordinates = _resolveMarkerCoordinates(marker);
    if (coordinates == null) {
      return null;
    }

    return _ResolvedMarkerPoint(
      place: place,
      marker: marker,
      longitude: coordinates.$1,
      latitude: coordinates.$2,
    );
  }

  _ResolvedMarkerPoint? _resolveMarkerPointForPlace(PlaceEntity place) {
    final marker = _markersByPlaceId[place.id];
    if (marker == null) {
      return null;
    }

    final coordinates = _resolveMarkerCoordinates(marker);
    if (coordinates == null) {
      return null;
    }

    return _ResolvedMarkerPoint(
      place: place,
      marker: marker,
      longitude: coordinates.$1,
      latitude: coordinates.$2,
    );
  }

  (double, double)? _resolveMarkerCoordinates(GlobeMarkerEntity marker) {
    if (marker.hasCoordinates) {
      return (marker.longitude!, marker.latitude!);
    }

    final place = _placesById[marker.placeId];
    if (place == null) {
      return null;
    }

    return (place.longitude, place.latitude);
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

  void _log(String message) {
    debugPrint('MapHome: $message');
  }
}

class _ResolvedMarkerPoint {
  const _ResolvedMarkerPoint({
    required this.place,
    required this.marker,
    required this.longitude,
    required this.latitude,
  });

  final PlaceEntity place;
  final GlobeMarkerEntity marker;
  final double longitude;
  final double latitude;
}
