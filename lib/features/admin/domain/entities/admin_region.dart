class AdminRegion {
  const AdminRegion({
    required this.id,
    required this.focusZoom,
    required this.name,
    this.enabled,
  });

  final String id;
  final double focusZoom;
  final Map<String, String> name;
  final bool? enabled;

  String localizedName(String languageCode) {
    final isZh = languageCode.toLowerCase().startsWith('zh');
    final zh = name['zh']?.trim() ?? '';
    final en = name['en']?.trim() ?? '';
    if (isZh && zh.isNotEmpty) {
      return zh;
    }
    if (en.isNotEmpty) {
      return en;
    }
    return zh;
  }

  bool get hasName => name['zh']?.trim().isNotEmpty == true || name['en']?.trim().isNotEmpty == true;

  bool get supportsEnabledFlag => enabled != null;

  AdminRegion copyWith({
    String? id,
    double? focusZoom,
    Map<String, String>? name,
    bool? enabled,
    bool clearEnabled = false,
  }) {
    return AdminRegion(
      id: id ?? this.id,
      focusZoom: focusZoom ?? this.focusZoom,
      name: name ?? this.name,
      enabled: clearEnabled ? null : (enabled ?? this.enabled),
    );
  }
}
