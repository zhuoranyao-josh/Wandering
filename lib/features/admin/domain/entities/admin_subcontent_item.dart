class AdminSubcontentItem {
  const AdminSubcontentItem({
    required this.id,
    required this.enabled,
    required this.order,
    required this.title,
    required this.badge,
    required this.badgeCode,
    required this.featureName,
    required this.name,
    required this.subtitle,
    required this.description,
    required this.caption,
    required this.imageUrl,
    required this.priceRange,
    this.priceMin,
    this.priceMax,
    this.currencySymbol,
  });

  final String id;
  final bool enabled;
  final int order;
  final Map<String, String> title;
  final Map<String, String> badge;
  final String badgeCode;
  final Map<String, String> featureName;
  final Map<String, String> name;
  final Map<String, String> subtitle;
  final Map<String, String> description;
  final Map<String, String> caption;
  final String imageUrl;
  final String priceRange;
  final double? priceMin;
  final double? priceMax;
  final String? currencySymbol;

  AdminSubcontentItem copyWith({
    String? id,
    bool? enabled,
    int? order,
    Map<String, String>? title,
    Map<String, String>? badge,
    String? badgeCode,
    Map<String, String>? featureName,
    Map<String, String>? name,
    Map<String, String>? subtitle,
    Map<String, String>? description,
    Map<String, String>? caption,
    String? imageUrl,
    String? priceRange,
    double? priceMin,
    double? priceMax,
    String? currencySymbol,
  }) {
    return AdminSubcontentItem(
      id: id ?? this.id,
      enabled: enabled ?? this.enabled,
      order: order ?? this.order,
      title: title ?? this.title,
      badge: badge ?? this.badge,
      badgeCode: badgeCode ?? this.badgeCode,
      featureName: featureName ?? this.featureName,
      name: name ?? this.name,
      subtitle: subtitle ?? this.subtitle,
      description: description ?? this.description,
      caption: caption ?? this.caption,
      imageUrl: imageUrl ?? this.imageUrl,
      priceRange: priceRange ?? this.priceRange,
      priceMin: priceMin ?? this.priceMin,
      priceMax: priceMax ?? this.priceMax,
      currencySymbol: currencySymbol ?? this.currencySymbol,
    );
  }
}
