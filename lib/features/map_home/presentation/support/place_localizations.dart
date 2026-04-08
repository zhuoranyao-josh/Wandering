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
    }

    return PlacePresentationCopy(
      name: t.mapPlaceTokyoName,
      description: t.mapPlaceTokyoDescription,
    );
  }
}
