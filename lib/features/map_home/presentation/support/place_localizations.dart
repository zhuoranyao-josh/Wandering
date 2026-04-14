import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/place_entity.dart';

class PlacePresentationCopy {
  const PlacePresentationCopy({required this.name, required this.description});

  final String name;
  final String description;
}

extension PlaceLocalizationX on PlaceEntity {
  PlacePresentationCopy localizedCopy(AppLocalizations t) {
    switch (id) {
      case 'tokyo':
        return PlacePresentationCopy(
          name: t.mapPlaceTokyoName,
          description: t.mapPlaceTokyoDescription,
        );
      case 'new_york':
        return PlacePresentationCopy(
          name: t.mapPlaceNewYorkName,
          description: t.mapPlaceNewYorkDescription,
        );
      case 'los_angeles':
        return PlacePresentationCopy(
          name: t.mapPlaceLosAngelesName,
          description: t.mapPlaceLosAngelesDescription,
        );
      case 'moscow':
        return PlacePresentationCopy(
          name: t.mapPlaceMoscowName,
          description: t.mapPlaceMoscowDescription,
        );
      case 'saint_petersburg':
        return PlacePresentationCopy(
          name: t.mapPlaceSaintPetersburgName,
          description: t.mapPlaceSaintPetersburgDescription,
        );
      case 'yokohama':
        return PlacePresentationCopy(
          name: t.mapPlaceYokohamaName,
          description: t.mapPlaceYokohamaDescription,
        );
      case 'osaka':
        return PlacePresentationCopy(
          name: t.mapPlaceOsakaName,
          description: t.mapPlaceOsakaDescription,
        );
      case 'beijing':
        return PlacePresentationCopy(
          name: t.mapPlaceBeijingName,
          description: t.mapPlaceBeijingDescription,
        );
      case 'shanghai':
        return PlacePresentationCopy(
          name: t.mapPlaceShanghaiName,
          description: t.mapPlaceShanghaiDescription,
        );
      case 'guangzhou':
        return PlacePresentationCopy(
          name: t.mapPlaceGuangzhouName,
          description: t.mapPlaceGuangzhouDescription,
        );
      case 'tianjin':
        return PlacePresentationCopy(
          name: t.mapPlaceTianjinName,
          description: t.mapPlaceTianjinDescription,
        );
      case 'lhasa':
        return PlacePresentationCopy(
          name: t.mapPlaceLhasaName,
          description: t.mapPlaceLhasaDescription,
        );
      case 'suzhou':
        return PlacePresentationCopy(
          name: t.mapPlaceSuzhouName,
          description: t.mapPlaceSuzhouDescription,
        );
      case 'munich':
        return PlacePresentationCopy(
          name: t.mapPlaceMunichName,
          description: t.mapPlaceMunichDescription,
        );
      case 'berlin':
        return PlacePresentationCopy(
          name: t.mapPlaceBerlinName,
          description: t.mapPlaceBerlinDescription,
        );
      case 'frankfurt':
        return PlacePresentationCopy(
          name: t.mapPlaceFrankfurtName,
          description: t.mapPlaceFrankfurtDescription,
        );
      case 'istanbul':
        return PlacePresentationCopy(
          name: t.mapPlaceIstanbulName,
          description: t.mapPlaceIstanbulDescription,
        );
      case 'toronto':
        return PlacePresentationCopy(
          name: t.mapPlaceTorontoName,
          description: t.mapPlaceTorontoDescription,
        );
      case 'buenos_aires':
        return PlacePresentationCopy(
          name: t.mapPlaceBuenosAiresName,
          description: t.mapPlaceBuenosAiresDescription,
        );
      case 'sao_paulo':
        return PlacePresentationCopy(
          name: t.mapPlaceSaoPauloName,
          description: t.mapPlaceSaoPauloDescription,
        );
      case 'cairo':
        return PlacePresentationCopy(
          name: t.mapPlaceCairoName,
          description: t.mapPlaceCairoDescription,
        );
      case 'cape_town':
        return PlacePresentationCopy(
          name: t.mapPlaceCapeTownName,
          description: t.mapPlaceCapeTownDescription,
        );
      case 'sydney':
        return PlacePresentationCopy(
          name: t.mapPlaceSydneyName,
          description: t.mapPlaceSydneyDescription,
        );
      case 'melbourne':
        return PlacePresentationCopy(
          name: t.mapPlaceMelbourneName,
          description: t.mapPlaceMelbourneDescription,
        );
      case 'wellington':
        return PlacePresentationCopy(
          name: t.mapPlaceWellingtonName,
          description: t.mapPlaceWellingtonDescription,
        );
      case 'hong_kong':
        return PlacePresentationCopy(
          name: t.mapPlaceHongKongName,
          description: t.mapPlaceHongKongDescription,
        );
      case 'paris':
        return PlacePresentationCopy(
          name: t.mapPlaceParisName,
          description: t.mapPlaceParisDescription,
        );
      case 'london':
        return PlacePresentationCopy(
          name: t.mapPlaceLondonName,
          description: t.mapPlaceLondonDescription,
        );
    }

    return PlacePresentationCopy(
      name: t.mapPlaceTokyoName,
      description: t.mapPlaceTokyoDescription,
    );
  }
}
