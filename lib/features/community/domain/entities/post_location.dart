class PostLocation {
  const PostLocation({
    required this.fullName,
    required this.city,
    required this.country,
    required this.latitude,
    required this.longitude,
    this.placeType,
    this.placeFormatted,
    this.mapboxId,
    this.sessionToken,
  });

  final String? fullName;
  final String? city;
  final String? country;
  final double? latitude;
  final double? longitude;
  final String? placeType;
  final String? placeFormatted;

  /// Search Box 的 suggest / retrieve 需要复用 mapbox_id 和 session_token。
  final String? mapboxId;
  final String? sessionToken;

  bool get hasValue {
    return _hasText(fullName) ||
        _hasText(city) ||
        _hasText(country) ||
        _hasText(placeFormatted) ||
        latitude != null ||
        longitude != null;
  }

  bool get hasCoordinates => latitude != null && longitude != null;

  bool get canRetrieveDetails {
    return _hasText(mapboxId) && _hasText(sessionToken);
  }

  String? get summaryLabel {
    final cleanCountry = _clean(country);
    final cleanCity = _clean(city);
    if (cleanCountry != null && cleanCity != null) {
      return '$cleanCountry · $cleanCity';
    }
    if (cleanCountry != null) {
      return cleanCountry;
    }
    if (cleanCity != null) {
      return cleanCity;
    }
    return _clean(fullName) ?? _clean(placeFormatted);
  }

  String? get fullLabel {
    final cleanFullName = _clean(fullName);
    final cleanFormatted = _clean(placeFormatted);
    if (cleanFullName != null && cleanFormatted != null) {
      return '$cleanFullName, $cleanFormatted';
    }
    return cleanFullName ?? cleanFormatted ?? summaryLabel;
  }

  PostLocation copyWith({
    String? fullName,
    String? city,
    String? country,
    double? latitude,
    double? longitude,
    String? placeType,
    String? placeFormatted,
    String? mapboxId,
    String? sessionToken,
  }) {
    return PostLocation(
      fullName: fullName ?? this.fullName,
      city: city ?? this.city,
      country: country ?? this.country,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      placeType: placeType ?? this.placeType,
      placeFormatted: placeFormatted ?? this.placeFormatted,
      mapboxId: mapboxId ?? this.mapboxId,
      sessionToken: sessionToken ?? this.sessionToken,
    );
  }

  bool _hasText(String? value) => _clean(value) != null;

  String? _clean(String? value) {
    if (value == null) {
      return null;
    }
    final cleanValue = value.trim();
    return cleanValue.isEmpty ? null : cleanValue;
  }
}
