import '../../../../l10n/app_localizations.dart';

class ActivityCategoryOption {
  const ActivityCategoryOption({
    required this.key,
    required this.aliases,
    required this.labelBuilder,
  });

  final String key;
  final List<String> aliases;
  final String Function(AppLocalizations t) labelBuilder;

  bool get isAll => key == 'all';

  String label(AppLocalizations t) => labelBuilder(t);
}

class ActivityCategories {
  static const allCategory = ActivityCategoryOption(
    key: 'all',
    aliases: <String>['all'],
    labelBuilder: _allLabel,
  );

  static const traditionalFestival = ActivityCategoryOption(
    key: 'traditional_festival',
    aliases: <String>[
      'traditional_festival',
      'traditional festival',
      'traditional-festival',
      'traditionalfestival',
      'traditionalFestival',
      'festival',
      'traditional',
      '传统节日',
    ],
    labelBuilder: _traditionalFestivalLabel,
  );

  static const music = ActivityCategoryOption(
    key: 'music',
    aliases: <String>['music', '音乐'],
    labelBuilder: _musicLabel,
  );

  static const exhibition = ActivityCategoryOption(
    key: 'exhibition',
    aliases: <String>['exhibition', 'exhibit', '展览'],
    labelBuilder: _exhibitionLabel,
  );

  static const entertainment = ActivityCategoryOption(
    key: 'entertainment',
    aliases: <String>['entertainment', 'fun', '娱乐'],
    labelBuilder: _entertainmentLabel,
  );

  static const nature = ActivityCategoryOption(
    key: 'nature',
    aliases: <String>['nature', 'natural', '自然'],
    labelBuilder: _natureLabel,
  );

  static const List<ActivityCategoryOption> all = <ActivityCategoryOption>[
    allCategory,
    traditionalFestival,
    music,
    exhibition,
    entertainment,
    nature,
  ];

  static const List<ActivityCategoryOption> selectable =
      <ActivityCategoryOption>[
        traditionalFestival,
        music,
        exhibition,
        entertainment,
        nature,
      ];

  static ActivityCategoryOption? fromRawCategory(String rawCategory) {
    final normalized = _normalize(rawCategory);
    if (normalized.isEmpty) {
      return null;
    }
    for (final option in selectable) {
      if (_normalize(option.key) == normalized) {
        return option;
      }
      if (option.aliases.any((alias) => _normalize(alias) == normalized)) {
        return option;
      }
    }
    return null;
  }

  static List<String> normalizeRawCategories(Iterable<String> rawValues) {
    final normalized = <String>{};
    for (final rawValue in rawValues) {
      final option = fromRawCategory(rawValue);
      if (option != null) {
        normalized.add(option.key);
      }
    }
    return normalized.toList(growable: false);
  }

  static String _normalize(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'[\s_\-]'), '');
  }

  static String _allLabel(AppLocalizations t) => t.activityCategoryAll;

  static String _traditionalFestivalLabel(AppLocalizations t) =>
      t.activityCategoryTraditionalFestival;

  static String _musicLabel(AppLocalizations t) => t.activityCategoryMusic;

  static String _exhibitionLabel(AppLocalizations t) =>
      t.activityCategoryExhibition;

  static String _entertainmentLabel(AppLocalizations t) =>
      t.activityCategoryEntertainment;

  static String _natureLabel(AppLocalizations t) => t.activityCategoryNature;
}
