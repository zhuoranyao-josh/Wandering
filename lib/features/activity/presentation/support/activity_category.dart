import '../../../../l10n/app_localizations.dart';

class ActivityCategoryOption {
  final String key;
  final List<String> aliases;
  final String Function(AppLocalizations t) labelBuilder;

  const ActivityCategoryOption({
    required this.key,
    required this.aliases,
    required this.labelBuilder,
  });

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
    key: 'traditionalFestival',
    aliases: <String>[
      'traditionalfestival',
      'traditional_festival',
      'traditional festival',
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

  static ActivityCategoryOption? fromRawCategory(String rawCategory) {
    final normalized = _normalize(rawCategory);
    if (normalized.isEmpty) return null;

    for (final option in all.where((option) => !option.isAll)) {
      if (option.aliases.any((alias) => _normalize(alias) == normalized)) {
        return option;
      }
    }
    return null;
  }

  static String _normalize(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'[\s_\-]'), '');
  }

  static String _allLabel(AppLocalizations t) {
    return t.activityCategoryAll;
  }

  static String _traditionalFestivalLabel(AppLocalizations t) {
    return t.activityCategoryTraditionalFestival;
  }

  static String _musicLabel(AppLocalizations t) {
    return t.activityCategoryMusic;
  }

  static String _exhibitionLabel(AppLocalizations t) {
    return t.activityCategoryExhibition;
  }

  static String _entertainmentLabel(AppLocalizations t) {
    return t.activityCategoryEntertainment;
  }

  static String _natureLabel(AppLocalizations t) {
    return t.activityCategoryNature;
  }
}
