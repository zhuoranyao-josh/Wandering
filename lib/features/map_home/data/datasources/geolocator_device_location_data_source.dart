import 'dart:async';

import 'package:geolocator/geolocator.dart';

import '../../domain/entities/current_location_entity.dart';
import '../../domain/entities/current_location_result.dart';
import 'device_location_data_source.dart';

class GeolocatorDeviceLocationDataSource implements DeviceLocationDataSource {
  @override
  Future<CurrentLocationResult> getCurrentLocation() async {
    // 先检查系统定位服务和权限，避免页面层自己处理平台细节。
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return CurrentLocationResult.failure(
        CurrentLocationFailure.serviceDisabled,
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      return CurrentLocationResult.failure(
        CurrentLocationFailure.permissionDenied,
      );
    }

    if (permission == LocationPermission.deniedForever) {
      return CurrentLocationResult.failure(
        CurrentLocationFailure.permissionDeniedForever,
      );
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      return CurrentLocationResult.success(
        CurrentLocationEntity(
          latitude: position.latitude,
          longitude: position.longitude,
          accuracy: position.accuracy,
        ),
      );
    } on TimeoutException {
      return _lastKnownOrFailure(CurrentLocationFailure.unavailable);
    } catch (_) {
      return _lastKnownOrFailure(CurrentLocationFailure.unknown);
    }
  }

  Future<CurrentLocationResult> _lastKnownOrFailure(
    CurrentLocationFailure fallback,
  ) async {
    // 实时定位失败时尽量回退到最近一次缓存位置，保证体验更平滑。
    final lastKnownPosition = await Geolocator.getLastKnownPosition();
    if (lastKnownPosition == null) {
      return CurrentLocationResult.failure(fallback);
    }

    return CurrentLocationResult.success(
      CurrentLocationEntity(
        latitude: lastKnownPosition.latitude,
        longitude: lastKnownPosition.longitude,
        accuracy: lastKnownPosition.accuracy,
      ),
    );
  }
}
