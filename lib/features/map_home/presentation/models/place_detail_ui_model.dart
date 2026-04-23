import '../../domain/entities/place_entity.dart';

/// 地点详情页类型：城市不展示“城市 + 州/区域”，景点展示该行信息。
enum PlaceDetailsType { city, attraction }

/// 纯 UI 数据对象：
/// 当前仅承载展示层字段，后续可由 Controller 直接喂入真实数据。
class PlaceDetailUiModel {
  const PlaceDetailUiModel({
    required this.placeId,
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
  const PlaceExperienceUiModel({this.badge, this.title});

  final String? badge;
  final String? title;
}

class PlaceFlavorUiModel {
  const PlaceFlavorUiModel({this.imageUrl, this.name, this.subtitle});

  final String? imageUrl;
  final String? name;
  final String? subtitle;
}

class PlaceStayUiModel {
  const PlaceStayUiModel({
    this.imageUrl,
    this.badge,
    this.name,
    this.priceRange,
  });

  final String? imageUrl;
  final String? badge;
  final String? name;
  final String? priceRange;
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
