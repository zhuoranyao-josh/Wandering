import 'package:flutter/widgets.dart';

import '../../../../l10n/app_localizations.dart';
import '../../data/datasources/weather_remote_data_source.dart';
import '../../domain/entities/checklist_detail.dart';
import '../../domain/entities/trip_weather_summary.dart';
import '../../domain/repositories/checklist_repository.dart';

class ChecklistDetailController extends ChangeNotifier {
  ChecklistDetailController({
    required this.repository,
    required this.weatherRemoteDataSource,
  });

  final ChecklistRepository repository;
  final WeatherRemoteDataSource weatherRemoteDataSource;

  bool _isLoading = false;
  bool _isGeneratingPlan = false;
  String? _errorMessage;
  ChecklistDetail? _checklistDetail;
  String _currentChecklistId = '';
  Locale _currentLocale = WidgetsBinding.instance.platformDispatcher.locale;

  bool get isLoading => _isLoading;
  bool get isGeneratingPlan => _isGeneratingPlan;
  String? get errorMessage => _errorMessage;
  ChecklistDetail? get checklistDetail => _checklistDetail;

  Future<void> updateLocale(Locale locale) async {
    final normalizedLocale = _normalizeLocale(locale);
    if (_currentLocale == normalizedLocale) {
      return;
    }
    _currentLocale = normalizedLocale;

    final detail = _checklistDetail;
    if (detail == null) {
      return;
    }
    _checklistDetail = await _withWeatherEssential(detail);
    notifyListeners();
  }

  Future<void> loadChecklistDetail(String checklistId) async {
    final trimmedChecklistId = checklistId.trim();
    _currentChecklistId = trimmedChecklistId;
    if (trimmedChecklistId.isEmpty) {
      _checklistDetail = null;
      _errorMessage = null;
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final detail = await repository.getChecklistDetail(trimmedChecklistId);
      if (detail == null) {
        _checklistDetail = null;
      } else {
        _checklistDetail = await _withWeatherEssential(detail);
      }
    } catch (_) {
      _errorMessage = 'checklistLoadFailed';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> retry() async {
    if (_currentChecklistId.isEmpty) {
      return;
    }
    await loadChecklistDetail(_currentChecklistId);
  }

  Future<void> updateBudget({
    double? totalBudget,
    String? currencySymbol,
  }) async {
    if (_currentChecklistId.isEmpty) {
      return;
    }
    try {
      await repository.updateBudget(
        checklistId: _currentChecklistId,
        totalBudget: totalBudget,
        currencySymbol: currencySymbol,
      );
      if (_checklistDetail != null) {
        _checklistDetail = _checklistDetail!.copyWith(
          totalBudget: totalBudget,
          currencySymbol: currencySymbol,
        );
        notifyListeners();
      }
    } catch (_) {
      _errorMessage = 'checklistLoadFailed';
      notifyListeners();
    }
  }

  Future<void> updateBudgetSplit({
    double? transportRatio,
    double? stayRatio,
    double? foodActivityRatio,
  }) async {
    if (_currentChecklistId.isEmpty) {
      return;
    }
    try {
      await repository.updateBudgetSplit(
        checklistId: _currentChecklistId,
        transportRatio: transportRatio,
        stayRatio: stayRatio,
        foodActivityRatio: foodActivityRatio,
      );
      if (_checklistDetail != null) {
        _checklistDetail = _checklistDetail!.copyWith(
          budgetSplit:
              (_checklistDetail!.budgetSplit ?? const ChecklistBudgetSplit())
                  .copyWith(
                    transportRatio: transportRatio,
                    stayRatio: stayRatio,
                    foodActivityRatio: foodActivityRatio,
                  ),
        );
        notifyListeners();
      }
    } catch (_) {
      _errorMessage = 'checklistLoadFailed';
      notifyListeners();
    }
  }

  Future<void> toggleItemCompleted(String itemId) async {
    if (_currentChecklistId.isEmpty || _checklistDetail == null) {
      return;
    }
    final trimmedId = itemId.trim();
    if (trimmedId.isEmpty) {
      return;
    }

    final currentItems = _checklistDetail!.items;
    final index = currentItems.indexWhere((item) => item.id == trimmedId);
    if (index < 0) {
      return;
    }

    // 先在本地切换勾选状态，失败时再回滚，提升操作反馈速度。
    final nextItems = currentItems.toList(growable: false);
    final target = nextItems[index];
    nextItems[index] = target.copyWith(isCompleted: !target.isCompleted);
    _checklistDetail = _checklistDetail!.copyWith(items: nextItems);
    notifyListeners();

    try {
      await repository.toggleItemCompleted(
        checklistId: _currentChecklistId,
        itemId: trimmedId,
      );
    } catch (_) {
      nextItems[index] = target;
      _checklistDetail = _checklistDetail!.copyWith(items: nextItems);
      _errorMessage = 'checklistLoadFailed';
      notifyListeners();
    }
  }

  Future<bool> generateChecklistPlan() async {
    if (_currentChecklistId.isEmpty || _isGeneratingPlan) {
      return false;
    }

    _isGeneratingPlan = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await repository.generateChecklistPlan(_currentChecklistId);
      final detail = await repository.getChecklistDetail(_currentChecklistId);
      if (detail == null) {
        _errorMessage = 'checklistGenerateFailed';
        return false;
      }
      _checklistDetail = await _withWeatherEssential(detail);
      return true;
    } catch (_) {
      _errorMessage = 'checklistGenerateFailed';
      return false;
    } finally {
      _isGeneratingPlan = false;
      notifyListeners();
    }
  }

  Future<void> updatePlan() async {
    await generateChecklistPlan();
  }

  Future<ChecklistDetail> _withWeatherEssential(ChecklistDetail detail) async {
    final t = await AppLocalizations.delegate.load(
      _normalizeLocale(_currentLocale),
    );

    final latitude = detail.latitude;
    final longitude = detail.longitude;
    final startDate = detail.startDate;
    final endDate = detail.endDate;

    final TripWeatherSummary summary;
    if (latitude == null ||
        longitude == null ||
        startDate == null ||
        endDate == null) {
      summary = TripWeatherSummary.unavailable(reasonCode: 'missing_input');
    } else {
      summary = await weatherRemoteDataSource.getTripWeatherSummary(
        latitude: latitude,
        longitude: longitude,
        startDate: startDate,
        endDate: endDate,
        languageCode: _languageCodeForWeather(_currentLocale),
      );
    }

    final weatherCard = _buildWeatherEssential(summary: summary, t: t);
    final mergedEssentials = _mergeWeatherEssential(
      current: detail.essentials,
      weather: weatherCard,
    );
    return detail.copyWith(essentials: mergedEssentials);
  }

  ChecklistEssential _buildWeatherEssential({
    required TripWeatherSummary summary,
    required AppLocalizations t,
  }) {
    if (summary.isAvailable &&
        summary.minTemp != null &&
        summary.maxTemp != null) {
      final minTemp = summary.minTemp!.round();
      final maxTemp = summary.maxTemp!.round();
      if (summary.hasSnow) {
        return ChecklistEssential(
          iconType: 'snow',
          title: t.checklistEssentialWeatherTitle,
          mainText: t.checklistWeatherTempRangeWithCondition(
            minTemp,
            maxTemp,
            t.checklistWeatherConditionSnow,
          ),
          subText: t.checklistWeatherSnowExpected,
        );
      }
      if (summary.hasRain) {
        return ChecklistEssential(
          iconType: 'rain',
          title: t.checklistEssentialWeatherTitle,
          mainText: t.checklistWeatherTempRangeWithCondition(
            minTemp,
            maxTemp,
            t.checklistWeatherConditionRainy,
          ),
          subText: t.checklistWeatherRainExpected,
        );
      }
      return ChecklistEssential(
        iconType: 'clear',
        title: t.checklistEssentialWeatherTitle,
        mainText: t.checklistWeatherTempRange(minTemp, maxTemp),
        subText: t.checklistWeatherMostlyClear,
      );
    }

    final unavailableSubText = switch (summary.reasonCode) {
      'forecast_limit' => t.checklistWeatherUnavailableForecastLimit,
      'no_data' => t.checklistWeatherUnavailableNoData,
      'api_key_missing' => t.checklistWeatherUnavailableApiKeyMissing,
      'missing_input' => t.checklistWeatherUnavailableMissingInput,
      _ => t.checklistWeatherUnavailableLoadFailed,
    };

    return ChecklistEssential(
      iconType: 'cloud_off',
      title: t.checklistEssentialWeatherTitle,
      mainText: t.checklistWeatherUnavailableMain,
      subText: unavailableSubText,
    );
  }

  List<ChecklistEssential> _mergeWeatherEssential({
    required List<ChecklistEssential> current,
    required ChecklistEssential weather,
  }) {
    final others = current
        .where((item) => !_isWeatherEssential(item))
        .toList(growable: false);
    return <ChecklistEssential>[weather, ...others];
  }

  bool _isWeatherEssential(ChecklistEssential item) {
    final normalizedTitle = item.title.trim().toLowerCase().replaceAll(' ', '');
    final normalizedIcon = item.iconType.trim().toLowerCase();
    return normalizedTitle == 'weather' || normalizedIcon == 'weather';
  }

  Locale _normalizeLocale(Locale locale) {
    if (locale.languageCode.toLowerCase().startsWith('zh')) {
      return const Locale('zh');
    }
    return const Locale('en');
  }

  String _languageCodeForWeather(Locale locale) {
    if (locale.languageCode.toLowerCase().startsWith('zh')) {
      return 'zh_cn';
    }
    return 'en';
  }
}
