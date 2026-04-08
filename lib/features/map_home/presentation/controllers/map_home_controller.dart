import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

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
  MapboxMap? _mapboxMap;
  String? _errorDetails;
  int _mapWidgetVersion = 0;
  bool _isApplyingStyle = false;

  MapHomeViewStatus get status => _status;
  MapHomeLightPreset get lightPreset => _lightPreset;
  MapHomeBasemapLanguage get basemapLanguage => _basemapLanguage;
  String? get errorDetails => _errorDetails;
  int get mapWidgetVersion => _mapWidgetVersion;

  bool get isLoading => _status == MapHomeViewStatus.loading;
  bool get hasError => _status == MapHomeViewStatus.error;
  bool get isReady => _status == MapHomeViewStatus.ready;
  bool get canToggleLightPreset =>
      isReady && _mapboxMap != null && !_isApplyingStyle;

  void onMapCreated(MapboxMap mapboxMap) {
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
}
