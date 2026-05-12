import '../../domain/entities/place_entity.dart';
import '../../domain/entities/place_detail_sections_entity.dart';

/// 地点详情页类型：城市不展示“城市 + 州/区域”，景点展示该行信息。
enum PlaceDetailsType { city, attraction }

/// 纯 UI 数据对象：
/// 当前仅承载展示层字段，后续可由 Controller 直接喂入真实数据。
class PlaceDetailUiModel {
  const PlaceDetailUiModel({
    required this.placeId,
    this.latitude,
    this.longitude,
    this.heroImageUrl,
    this.country,
    this.placeName,
    this.placeNameByLanguage = const <String, String>{},
    this.quote,
    this.quoteByLanguage = const <String, String>{},
    this.placeType = PlaceDetailsType.city,
    this.city,
    this.region,
    this.tagline,
    this.bestSeason,
    this.recommendedDuration,
    this.category,
    this.tags = const <String>[],
    this.description,
    this.longDescriptionByLanguage = const <String, String>{},
    this.experiences = const <PlaceExperienceUiModel>[],
    this.flavors = const <PlaceFlavorUiModel>[],
    this.stays = const <PlaceStayUiModel>[],
    this.communityMoments = const <PlaceCommunityMomentUiModel>[],
    this.galleryImageUrls = const <String>[],
    this.galleryOverflowCount = 0,
  });

  final String placeId;
  final double? latitude;
  final double? longitude;
  final String? heroImageUrl;
  final String? country;
  final String? placeName;
  final Map<String, String> placeNameByLanguage;
  final String? quote;
  final Map<String, String> quoteByLanguage;
  final PlaceDetailsType placeType;
  final String? city;
  final String? region;
  final String? tagline;
  final String? bestSeason;
  final String? recommendedDuration;
  final String? category;
  final List<String> tags;
  final String? description;
  final Map<String, String> longDescriptionByLanguage;
  final List<PlaceExperienceUiModel> experiences;
  final List<PlaceFlavorUiModel> flavors;
  final List<PlaceStayUiModel> stays;
  final List<PlaceCommunityMomentUiModel> communityMoments;
  final List<String> galleryImageUrls;
  final int galleryOverflowCount;

  /// 当前阶段仅映射 MapHome 已有真实字段，其他详情字段保持空位等待后续链路接入。
  factory PlaceDetailUiModel.fromPlaceEntity({required PlaceEntity place}) {
    final trimmedCover = place.coverImage.trim();

    return PlaceDetailUiModel(
      placeId: place.id,
      latitude: place.latitude,
      longitude: place.longitude,
      heroImageUrl: trimmedCover.isEmpty ? null : trimmedCover,
      placeNameByLanguage: place.name,
      quoteByLanguage: place.quote,
      longDescriptionByLanguage: place.longDescription,
      tags: place.tags,
      galleryImageUrls: trimmedCover.isEmpty
          ? const <String>[]
          : <String>[trimmedCover],
    );
  }

  factory PlaceDetailUiModel.fromDetailSections({
    required PlaceDetailSectionsEntity detail,
  }) {
    final place = detail.place;
    final trimmedCover = place.coverImage.trim();
    return PlaceDetailUiModel(
      placeId: place.id,
      latitude: place.latitude,
      longitude: place.longitude,
      heroImageUrl: trimmedCover.isEmpty ? null : trimmedCover,
      placeNameByLanguage: place.name,
      quoteByLanguage: place.quote,
      longDescriptionByLanguage: place.longDescription,
      tags: place.tags,
      experiences: detail.experiences
          .map(
            (item) => PlaceExperienceUiModel(
              badgeCode: item.badgeCode,
              badgeByLanguage: item.badge,
              featureNameByLanguage: item.featureName,
              titleByLanguage: item.title,
              descriptionByLanguage: item.description,
            ),
          )
          .toList(growable: false),
      flavors: detail.flavors
          .map(
            (item) => PlaceFlavorUiModel(
              imageUrl: item.imageUrl,
              nameByLanguage: item.name,
              subtitleByLanguage: item.subtitle,
            ),
          )
          .toList(growable: false),
      stays: detail.stays
          .map(
            (item) => PlaceStayUiModel(
              imageUrl: item.imageUrl,
              badgeByLanguage: item.badge,
              nameByLanguage: item.name,
              priceRange: item.priceRange,
              priceMin: item.priceMin,
              priceMax: item.priceMax,
              currencySymbol: item.currencySymbol,
            ),
          )
          .toList(growable: false),
      galleryImageUrls: detail.gallery
          .map((item) => item.imageUrl.trim())
          .where((url) => url.isNotEmpty)
          .toList(growable: false),
    );
  }

  String? resolvePlaceName(String languageCode) {
    final directValue = placeName?.trim() ?? '';
    if (directValue.isNotEmpty) {
      return directValue;
    }

    final localized = _resolveLocalizedText(languageCode, placeNameByLanguage);
    return localized.isEmpty ? null : localized;
  }

  String? resolveDescription(String languageCode) {
    final directValue = description?.trim() ?? '';
    if (directValue.isNotEmpty) {
      return directValue;
    }

    final longValue = _resolveLocalizedText(
      languageCode,
      longDescriptionByLanguage,
    );
    return longValue.isEmpty ? null : longValue;
  }

  String? resolveQuote(String languageCode) {
    final directValue = quote?.trim() ?? '';
    if (directValue.isNotEmpty) {
      return directValue;
    }

    final localized = _resolveLocalizedText(languageCode, quoteByLanguage);
    return localized.isEmpty ? null : localized;
  }

  String? get locationLine {
    if (placeType != PlaceDetailsType.attraction) {
      return null;
    }

    final trimmedCity = city?.trim() ?? '';
    final trimmedRegion = region?.trim() ?? '';
    if (trimmedCity.isEmpty && trimmedRegion.isEmpty) {
      return null;
    }
    if (trimmedCity.isEmpty) {
      return trimmedRegion;
    }
    if (trimmedRegion.isEmpty) {
      return trimmedCity;
    }
    return '$trimmedCity, $trimmedRegion';
  }

  String _resolveLocalizedText(
    String languageCode,
    Map<String, String> values,
  ) {
    final zh = values['zh']?.trim() ?? '';
    final en = values['en']?.trim() ?? '';
    final isChinese = languageCode.toLowerCase().startsWith('zh');

    if (isChinese && zh.isNotEmpty) {
      return zh;
    }
    if (en.isNotEmpty) {
      return en;
    }
    if (zh.isNotEmpty) {
      return zh;
    }
    return '';
  }
}

class PlaceExperienceUiModel {
  const PlaceExperienceUiModel({
    this.badgeCode,
    this.badge,
    this.featureName,
    this.title,
    this.description,
    this.badgeByLanguage = const <String, String>{},
    this.featureNameByLanguage = const <String, String>{},
    this.titleByLanguage = const <String, String>{},
    this.descriptionByLanguage = const <String, String>{},
  });

  final String? badgeCode;
  final String? badge;
  final String? featureName;
  final String? title;
  final String? description;
  final Map<String, String> badgeByLanguage;
  final Map<String, String> featureNameByLanguage;
  final Map<String, String> titleByLanguage;
  final Map<String, String> descriptionByLanguage;

  String get normalizedBadgeCode => badgeCode?.trim().toLowerCase() ?? '';

  String? resolveBadge(String languageCode) {
    final direct = badge?.trim() ?? '';
    if (direct.isNotEmpty) {
      return direct;
    }
    return _resolveLocalized(languageCode, badgeByLanguage);
  }

  String? resolveFeatureName(String languageCode) {
    final direct = featureName?.trim() ?? '';
    if (direct.isNotEmpty) {
      return direct;
    }
    final localized = _resolveLocalized(languageCode, featureNameByLanguage);
    return localized?.trim().isNotEmpty == true
        ? localized
        : resolveTitle(languageCode);
  }

  String? resolveTitle(String languageCode) {
    final direct = title?.trim() ?? '';
    if (direct.isNotEmpty) {
      return direct;
    }
    return _resolveLocalized(languageCode, titleByLanguage);
  }

  String? resolveDescription(String languageCode) {
    final direct = description?.trim() ?? '';
    if (direct.isNotEmpty) {
      return direct;
    }
    return _resolveLocalized(languageCode, descriptionByLanguage);
  }
}

class PlaceFlavorUiModel {
  const PlaceFlavorUiModel({
    this.imageUrl,
    this.name,
    this.subtitle,
    this.nameByLanguage = const <String, String>{},
    this.subtitleByLanguage = const <String, String>{},
  });

  final String? imageUrl;
  final String? name;
  final String? subtitle;
  final Map<String, String> nameByLanguage;
  final Map<String, String> subtitleByLanguage;

  String? resolveName(String languageCode) {
    final direct = name?.trim() ?? '';
    if (direct.isNotEmpty) {
      return direct;
    }
    return _resolveLocalized(languageCode, nameByLanguage);
  }

  String? resolveSubtitle(String languageCode) {
    final direct = subtitle?.trim() ?? '';
    if (direct.isNotEmpty) {
      return direct;
    }
    return _resolveLocalized(languageCode, subtitleByLanguage);
  }
}

class PlaceStayUiModel {
  const PlaceStayUiModel({
    this.imageUrl,
    this.badge,
    this.name,
    this.priceRange,
    this.priceMin,
    this.priceMax,
    this.currencySymbol,
    this.badgeByLanguage = const <String, String>{},
    this.nameByLanguage = const <String, String>{},
  });

  final String? imageUrl;
  final String? badge;
  final String? name;
  final String? priceRange;
  final double? priceMin;
  final double? priceMax;
  final String? currencySymbol;
  final Map<String, String> badgeByLanguage;
  final Map<String, String> nameByLanguage;

  String? resolveBadge(String languageCode) {
    final direct = badge?.trim() ?? '';
    if (direct.isNotEmpty) {
      return direct;
    }
    return _resolveLocalized(languageCode, badgeByLanguage);
  }

  String? resolveName(String languageCode) {
    final direct = name?.trim() ?? '';
    if (direct.isNotEmpty) {
      return direct;
    }
    return _resolveLocalized(languageCode, nameByLanguage);
  }

  String? get formattedPriceRange {
    final min = priceMin;
    final max = priceMax;
    final symbol = currencySymbol?.trim() ?? '';
    if (min != null && max != null) {
      return '${_formatPriceValue(min)}$symbol - ${_formatPriceValue(max)}$symbol';
    }

    final legacy = priceRange?.trim() ?? '';
    return legacy.isEmpty ? null : legacy;
  }

  String _formatPriceValue(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '');
  }
}

class PlaceCommunityMomentUiModel {
  const PlaceCommunityMomentUiModel({
    this.imageUrl,
    this.avatarUrl,
    this.userName,
    this.caption,
    this.likeCount,
  });

  final String? imageUrl;
  final String? avatarUrl;
  final String? userName;
  final String? caption;
  final int? likeCount;
}

String? _resolveLocalized(String languageCode, Map<String, String> values) {
  final zh = values['zh']?.trim() ?? '';
  final en = values['en']?.trim() ?? '';
  final isChinese = languageCode.toLowerCase().startsWith('zh');
  if (isChinese && zh.isNotEmpty) {
    return zh;
  }
  if (en.isNotEmpty) {
    return en;
  }
  if (zh.isNotEmpty) {
    return zh;
  }
  return null;
}
