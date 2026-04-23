class AdminSubcontentItem {
  const AdminSubcontentItem({
    required this.id,
    required this.enabled,
    required this.order,
    required this.title,
    required this.badge,
    required this.name,
    required this.subtitle,
    required this.caption,
    required this.imageUrl,
    required this.priceRange,
  });

  final String id;
  final bool enabled;
  final int order;
  final Map<String, String> title;
  final Map<String, String> badge;
  final Map<String, String> name;
  final Map<String, String> subtitle;
  final Map<String, String> caption;
  final String imageUrl;
  final String priceRange;

  AdminSubcontentItem copyWith({
    String? id,
    bool? enabled,
    int? order,
    Map<String, String>? title,
    Map<String, String>? badge,
    Map<String, String>? name,
    Map<String, String>? subtitle,
    Map<String, String>? caption,
    String? imageUrl,
    String? priceRange,
  }) {
    return AdminSubcontentItem(
      id: id ?? this.id,
      enabled: enabled ?? this.enabled,
      order: order ?? this.order,
      title: title ?? this.title,
      badge: badge ?? this.badge,
      name: name ?? this.name,
      subtitle: subtitle ?? this.subtitle,
      caption: caption ?? this.caption,
      imageUrl: imageUrl ?? this.imageUrl,
      priceRange: priceRange ?? this.priceRange,
    );
  }
}
