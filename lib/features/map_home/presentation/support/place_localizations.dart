import '../../domain/entities/place_entity.dart';

class PlacePresentationCopy {
  const PlacePresentationCopy({required this.name, required this.description});

  final String name;
  final String description;
}

extension PlaceLocalizationX on PlaceEntity {
  PlacePresentationCopy localizedCopy(String languageCode) {
    final shortDescriptionValue = localizedShortDescription(languageCode);
    // 卡片优先展示短文案，短文案缺失时再回退到长文案。
    return PlacePresentationCopy(
      name: localizedName(languageCode),
      description: shortDescriptionValue.isNotEmpty
          ? shortDescriptionValue
          : localizedLongDescription(languageCode),
    );
  }
}
