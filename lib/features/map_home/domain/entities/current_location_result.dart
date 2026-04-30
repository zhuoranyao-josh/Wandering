import 'current_location_entity.dart';

enum CurrentLocationFailure {
  serviceDisabled,
  permissionDenied,
  permissionDeniedForever,
  unavailable,
  unknown,
}

class CurrentLocationResult {
  const CurrentLocationResult._({this.location, this.failure});

  final CurrentLocationEntity? location;
  final CurrentLocationFailure? failure;

  bool get isSuccess => location != null;

  factory CurrentLocationResult.success(CurrentLocationEntity location) {
    return CurrentLocationResult._(location: location);
  }

  factory CurrentLocationResult.failure(CurrentLocationFailure failure) {
    return CurrentLocationResult._(failure: failure);
  }
}
