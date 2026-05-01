import 'package:flutter/widgets.dart';

import '../../../../core/config/gemini_config.dart';
import '../../../../core/config/google_places_config.dart';
import '../../../../core/error/app_exception.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/datasources/weather_remote_data_source.dart';
import '../../domain/entities/checklist_detail.dart';
import '../../domain/entities/checklist_plan_progress.dart';
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
  ChecklistPlanProgressStep? _progressStep;
  double _progressPercent = 0;
  int? _progressCurrentItemIndex;
  int? _progressTotalItemCount;
  bool _progressHasPartialFailures = false;
  String? _progressErrorCode;
  String? _progressMessageCode;
  String _currentChecklistId = '';
  Locale _currentLocale = WidgetsBinding.instance.platformDispatcher.locale;
  bool _planCancellationRequested = false;

  bool get isLoading => _isLoading;
  bool get isGeneratingPlan => _isGeneratingPlan;
  String? get errorMessage => _errorMessage;
  ChecklistDetail? get checklistDetail => _checklistDetail;
  ChecklistPlanProgressStep? get progressStep => _progressStep;
  double get progressPercent => _progressPercent;
  int? get progressCurrentItemIndex => _progressCurrentItemIndex;
  int? get progressTotalItemCount => _progressTotalItemCount;
  bool get progressHasPartialFailures => _progressHasPartialFailures;
  String? get progressErrorCode => _progressErrorCode;
  String? get progressMessageCode => _progressMessageCode;

  void _log(String message) {
    debugPrint('[ChecklistPlan] $message');
  }

  void _setProgressState({
    required ChecklistPlanProgressStep step,
    required double progressPercent,
    int? currentItemIndex,
    int? totalItemCount,
    bool hasPartialFailures = false,
    String? errorCode,
    String? messageCode,
  }) {
    _progressStep = step;
    _progressPercent = progressPercent.clamp(0, 1);
    _progressCurrentItemIndex = currentItemIndex;
    _progressTotalItemCount = totalItemCount;
    _progressHasPartialFailures =
        hasPartialFailures || _progressHasPartialFailures;
    _progressErrorCode = errorCode;
    _progressMessageCode = messageCode;
    debugPrint(
      '[ChecklistPlanProgress] step=$step '
      'progress=${(_progressPercent * 100).toStringAsFixed(0)} '
      'current=$currentItemIndex total=$totalItemCount',
    );
    notifyListeners();
  }

  void _resetProgressState() {
    _progressStep = null;
    _progressPercent = 0;
    _progressCurrentItemIndex = null;
    _progressTotalItemCount = null;
    _progressHasPartialFailures = false;
    _progressErrorCode = null;
    _progressMessageCode = null;
  }

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

  Future<void> loadChecklistDetail(
    String checklistId, {
    bool forceRefresh = false,
  }) async {
    final trimmedChecklistId = checklistId.trim();
    _currentChecklistId = trimmedChecklistId;
    debugPrint(
      '[ChecklistDetail] refresh started checklistId=$trimmedChecklistId',
    );
    if (trimmedChecklistId.isEmpty) {
      _checklistDetail = null;
      _errorMessage = null;
      debugPrint(
        '[ChecklistDetail] refresh completed '
        'basicInfoCompleted=null planningStatus=null items=0',
      );
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    // 当前仓库未引入内存缓存；forceRefresh 预留为后续绕过缓存入口。
    if (forceRefresh) {
      _checklistDetail = null;
    }
    notifyListeners();
    try {
      final detail = await repository.getChecklistDetail(trimmedChecklistId);
      if (detail == null) {
        _checklistDetail = null;
        _resetProgressState();
      } else {
        _checklistDetail = await _withWeatherEssential(detail);
        final planningStatus = (_checklistDetail?.planningStatus ?? '')
            .trim()
            .toLowerCase();
        if (!_isGeneratingPlan && planningStatus == 'generating') {
          _setProgressState(
            step: ChecklistPlanProgressStep.generatingAiTravelPlan,
            progressPercent: 0.35,
          );
        } else if (planningStatus == 'completed') {
          _resetProgressState();
        } else if (planningStatus == 'failed' && !_isGeneratingPlan) {
          _progressStep = ChecklistPlanProgressStep.failed;
          _progressPercent = 1;
          _progressErrorCode = 'checklistGenerateFailed';
        }
      }
      debugPrint(
        '[ChecklistDetail] refresh completed '
        'basicInfoCompleted=${_checklistDetail?.basicInfoCompleted} '
        'planningStatus=${_checklistDetail?.planningStatus ?? 'null'} '
        'items=${_checklistDetail?.items.length ?? 0}',
      );
    } catch (_) {
      _errorMessage = 'checklistLoadFailed';
      debugPrint(
        '[ChecklistDetail] refresh completed '
        'basicInfoCompleted=null planningStatus=null items=0',
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> retry() async {
    if (_currentChecklistId.isEmpty) {
      return;
    }
    await loadChecklistDetail(_currentChecklistId, forceRefresh: true);
  }

  Future<void> refreshChecklistDetail({
    String? checklistId,
    bool forceRefresh = true,
  }) async {
    final target = (checklistId ?? _currentChecklistId).trim();
    if (target.isEmpty) {
      return;
    }
    await loadChecklistDetail(target, forceRefresh: forceRefresh);
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
    _log('generate started');
    _log('checklistId=$_currentChecklistId');
    _log('detail loaded=${_checklistDetail != null}');
    if (_currentChecklistId.isEmpty || _isGeneratingPlan) {
      _log(
        'generate aborted emptyChecklistId=${_currentChecklistId.isEmpty} '
        'isGeneratingPlan=$_isGeneratingPlan',
      );
      return false;
    }

    final detail = _checklistDetail;
    if (detail == null) {
      _errorMessage = 'checklistGenerateFailed';
      _setProgressState(
        step: ChecklistPlanProgressStep.failed,
        progressPercent: 1,
        errorCode: 'detail_not_loaded',
      );
      _log('generate failed detail not loaded');
      notifyListeners();
      return false;
    }

    final missingFields = _collectMissingPlanningFields(detail);
    if (missingFields.isNotEmpty) {
      for (final field in missingFields) {
        _log('missing required field=$field');
      }
      _errorMessage = 'checklistGenerateFailed';
      _setProgressState(
        step: ChecklistPlanProgressStep.failed,
        progressPercent: 1,
        errorCode: 'missing_required_fields',
      );
      notifyListeners();
      return false;
    }

    final trimmedGeminiKey = geminiApiKey.trim();
    if (trimmedGeminiKey.isEmpty) {
      _log('Gemini key missing');
    } else {
      _log('Gemini key exists length=${trimmedGeminiKey.length}');
    }
    final trimmedPlacesKey = googlePlacesApiKey.trim();
    if (trimmedPlacesKey.isEmpty) {
      _log('Google Places key missing');
    } else {
      _log('Google Places key exists length=${trimmedPlacesKey.length}');
    }

    _isGeneratingPlan = true;
    _planCancellationRequested = false;
    _errorMessage = null;
    _resetProgressState();
    _setProgressState(
      step: ChecklistPlanProgressStep.preparingTripInformation,
      progressPercent: 0.05,
    );
    _log('planningStatus current=${detail.planningStatus ?? 'null'}');
    notifyListeners();
    try {
      final generatedDetail = await repository.generateChecklistPlan(
        _currentChecklistId,
        onProgress: (progress) {
          if (_planCancellationRequested) {
            return;
          }
          _setProgressState(
            step: progress.step,
            progressPercent: progress.progressPercent,
            currentItemIndex: progress.currentItemIndex,
            totalItemCount: progress.totalItemCount,
            hasPartialFailures: progress.hasPartialFailures,
            errorCode: progress.errorCode,
            messageCode: progress.messageCode,
          );
        },
        shouldCancel: () => _planCancellationRequested,
      );
      if (_planCancellationRequested) {
        _log('generate cancelled before local state update');
        return false;
      }
      _log('repository.generateChecklistPlan finished');
      final stateUpdateStopwatch = Stopwatch()..start();
      _setProgressState(
        step: ChecklistPlanProgressStep.preparingCards,
        progressPercent: 0.99,
      );
      _checklistDetail = await _withWeatherEssential(generatedDetail);
      _log(
        'planningStatus changed -> ${_checklistDetail?.planningStatus ?? 'null'}',
      );
      _log(
        'ui refresh planningStatus=${_checklistDetail?.planningStatus ?? 'null'} '
        'items=${_checklistDetail?.items.length ?? 0} '
        'essentials=${_checklistDetail?.essentials.length ?? 0} '
        'hasProTip=${_checklistDetail?.proTip?.isEmpty == false}',
      );

      if ((_checklistDetail?.planningStatus ?? '').trim().toLowerCase() ==
          'failed') {
        _errorMessage =
            'Plan generation failed. Check required fields and API logs.';
        _setProgressState(
          step: ChecklistPlanProgressStep.failed,
          progressPercent: 1,
          errorCode: 'checklistGenerateFailed',
        );
        _log('generate finished with failed planningStatus');
        return false;
      }

      _log(
        'state update completed elapsed='
        '${stateUpdateStopwatch.elapsedMilliseconds}ms',
      );
      _setProgressState(
        step: ChecklistPlanProgressStep.finalizingPlan,
        progressPercent: 0.995,
      );
      _setProgressState(
        step: ChecklistPlanProgressStep.completed,
        progressPercent: 1,
      );
      debugPrint('[ChecklistPlanProgress] completed');
      _refreshDetailInBackground(_currentChecklistId);
      return true;
    } catch (error) {
      if (error is AppException &&
          error.code == 'checklist_generate_cancelled') {
        _log('generate cancelled by user');
        return false;
      }
      _errorMessage = 'checklistGenerateFailed';
      _setProgressState(
        step: ChecklistPlanProgressStep.failed,
        progressPercent: 1,
        errorCode: 'checklistGenerateFailed',
      );
      _log('generate exception=$_errorMessage');
      try {
        final refreshedDetail = await repository.getChecklistDetail(
          _currentChecklistId,
        );
        if (refreshedDetail != null) {
          _checklistDetail = await _withWeatherEssential(refreshedDetail);
          _log(
            'ui refresh after failure planningStatus='
            '${_checklistDetail?.planningStatus ?? 'null'} '
            'items=${_checklistDetail?.items.length ?? 0} '
            'essentials=${_checklistDetail?.essentials.length ?? 0} '
            'hasProTip=${_checklistDetail?.proTip?.isEmpty == false}',
          );
        }
      } catch (refreshError) {
        _log('refresh after failure error=$refreshError');
      }
      return false;
    } finally {
      _isGeneratingPlan = false;
      _planCancellationRequested = false;
      notifyListeners();
    }
  }

  Future<void> updatePlan() async {
    _log('updatePlan called');
    await generateChecklistPlan();
  }

  void cancelPlanGeneration() {
    if (!_isGeneratingPlan) {
      return;
    }
    _planCancellationRequested = true;
    _log('cancel generation requested');
  }

  void _refreshDetailInBackground(String checklistId) {
    Future<void>(() async {
      try {
        final reloadStopwatch = Stopwatch()..start();
        _log('reload detail started');
        final refreshedDetail = await repository.getChecklistDetail(
          checklistId,
        );
        _log(
          'reload detail completed elapsed='
          '${reloadStopwatch.elapsedMilliseconds}ms',
        );
        if (refreshedDetail == null) {
          return;
        }
        final weatherMerged = await _withWeatherEssential(refreshedDetail);
        if (_currentChecklistId.trim() != checklistId.trim()) {
          return;
        }
        _checklistDetail = weatherMerged;
        notifyListeners();
      } catch (error) {
        _log('background reload failed error=$error');
      }
    });
  }

  List<String> _collectMissingPlanningFields(ChecklistDetail detail) {
    final missingFields = <String>[];
    if (detail.destination.trim().isEmpty) {
      missingFields.add('destination');
    }
    if ((detail.departureCity?.trim().isNotEmpty ?? false) == false) {
      missingFields.add('departureCity');
    }
    if (detail.startDate == null) {
      missingFields.add('startDate');
    }
    if (detail.endDate == null) {
      missingFields.add('endDate');
    }
    if ((detail.tripDays ?? 0) <= 0) {
      missingFields.add('tripDays');
    }
    if (detail.nightCount == null) {
      missingFields.add('nightCount');
    }
    if ((detail.travelerCount ?? 0) <= 0) {
      missingFields.add('travelerCount');
    }
    if ((detail.totalBudget ?? 0) <= 0) {
      missingFields.add('totalBudget');
    }
    if ((detail.currency?.trim().isNotEmpty ?? false) == false) {
      missingFields.add('currency');
    }
    if (detail.resolvedLatitude == null) {
      missingFields.add('latitude');
    }
    if (detail.resolvedLongitude == null) {
      missingFields.add('longitude');
    }
    return missingFields;
  }

  Future<ChecklistDetail> _withWeatherEssential(ChecklistDetail detail) async {
    final t = await AppLocalizations.delegate.load(
      _normalizeLocale(_currentLocale),
    );

    final latitude = detail.resolvedLatitude;
    final longitude = detail.resolvedLongitude;
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
      final humidityLine = summary.humidityPercent == null
          ? null
          : '💧${summary.humidityPercent!}%';
      if (summary.hasSnow) {
        return ChecklistEssential(
          iconType: 'snow',
          title: t.checklistEssentialWeatherTitle,
          mainText: t.checklistWeatherTempRange(minTemp, maxTemp),
          // 天气卡按多行展示：状态 -> 湿度 -> 预警提示。
          subText: _joinWeatherLines(<String>[
            t.checklistWeatherConditionSnow,
            if (humidityLine != null) humidityLine,
            t.checklistWeatherSnowExpected,
          ]),
        );
      }
      if (summary.hasRain) {
        return ChecklistEssential(
          iconType: 'rain',
          title: t.checklistEssentialWeatherTitle,
          mainText: t.checklistWeatherTempRange(minTemp, maxTemp),
          // 天气卡按多行展示：状态 -> 湿度 -> 预警提示。
          subText: _joinWeatherLines(<String>[
            t.checklistWeatherConditionRainy,
            if (humidityLine != null) humidityLine,
            t.checklistWeatherRainExpected,
          ]),
        );
      }
      return ChecklistEssential(
        iconType: 'clear',
        title: t.checklistEssentialWeatherTitle,
        mainText: t.checklistWeatherTempRange(minTemp, maxTemp),
        subText: _joinWeatherLines(<String>[
          t.checklistWeatherMostlyClear,
          if (humidityLine != null) humidityLine,
        ]),
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

  String _joinWeatherLines(List<String> lines) {
    return lines
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .join('\n');
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
