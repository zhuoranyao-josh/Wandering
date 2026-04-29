import 'place_entity.dart';

class PlaceDetailSectionsEntity {
  const PlaceDetailSectionsEntity({
    required this.place,
    this.experiences = const <PlaceExperienceEntity>[],
    this.flavors = const <PlaceFlavorEntity>[],
    this.stays = const <PlaceStayEntity>[],
    this.gallery = const <PlaceGalleryEntity>[],
  });

  final PlaceEntity place;
  final List<PlaceExperienceEntity> experiences;
  final List<PlaceFlavorEntity> flavors;
  final List<PlaceStayEntity> stays;
  final List<PlaceGalleryEntity> gallery;
}

class PlaceExperienceEntity {
  const PlaceExperienceEntity({
    required this.title,
    required this.badge,
    required this.order,
    this.enabled = true,
  });

  final Map<String, String> title;
  final Map<String, String> badge;
  final int order;
  final bool enabled;
}

class PlaceFlavorEntity {
  const PlaceFlavorEntity({
    required this.name,
    required this.subtitle,
    required this.imageUrl,
    required this.order,
    this.enabled = true,
  });

  final Map<String, String> name;
  final Map<String, String> subtitle;
  final String imageUrl;
  final int order;
  final bool enabled;
}

class PlaceStayEntity {
  const PlaceStayEntity({
    required this.name,
    required this.badge,
    required this.imageUrl,
    required this.priceRange,
    required this.order,
    this.enabled = true,
  });

  final Map<String, String> name;
  final Map<String, String> badge;
  final String imageUrl;
  final String priceRange;
  final int order;
  final bool enabled;
}

class PlaceGalleryEntity {
  const PlaceGalleryEntity({
    required this.imageUrl,
    required this.caption,
    required this.order,
    this.enabled = true,
  });

  final String imageUrl;
  final Map<String, String> caption;
  final int order;
  final bool enabled;
}
