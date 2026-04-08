import 'package:flutter/foundation.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

abstract final class MapboxConfig {
  static const String _primaryAccessToken = String.fromEnvironment(
    'MAPBOX_ACCESS_TOKEN',
  );
  static const String _legacyAccessToken = String.fromEnvironment(
    'ACCESS_TOKEN',
  );

  static String get accessToken {
    if (_primaryAccessToken.trim().isNotEmpty) {
      return _primaryAccessToken.trim();
    }
    return _legacyAccessToken.trim();
  }

  static bool get hasAccessToken => accessToken.isNotEmpty;

  static bool get isSupportedPlatform {
    if (kIsWeb) {
      return false;
    }

    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  static void initialize() {
    if (!isSupportedPlatform || !hasAccessToken) {
      return;
    }
    MapboxOptions.setAccessToken(accessToken);
  }
}
