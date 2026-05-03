import 'package:flutter/widgets.dart';

import '../../../../core/config/gemini_config.dart';
import '../../../../core/config/google_places_config.dart';
import '../../../../core/error/app_exception.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/datasources/weather_remote_data_source.dart';
import '../../domain/entities/checklist_detail.dart';
import '../../domain/entities/checklist_plan_progress.dart';
import '../../domain/entities/trip_weather_summary.dart';
import '../../domain/entities/journey_basic_info_input.dart';
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
  int _sessionSeed = 0;
  int? _activeSessionId;
  final Set<int> _cancelledSessionIds = <int>{};
  _ChecklistEditableInput? _baselineInput;
  _ChecklistEditableInput? _editableInput;
  bool _hasInputChanges = false;

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
  bool get hasInputChanges => _hasInputChanges;
  bool get hasGeneratedPlan {
    final detail = _checklistDetail;
    if (detail == null) {
      return false;
    }
    final planningStatus = (detail.planningStatus ?? '').trim().toLowerCase();
    return planningStatus == 'completed' || detail.items.isNotEmpty;
  }

  bool get isReadyToPlan {
    final detail = _checklistDetail;
    if (detail == null) {
      return false;
    }
    return detail.basicInfoCompleted || detail.isBasicInfoComplete;
  }

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
        _baselineInput = null;
        _editableInput = null;
        _hasInputChanges = false;
        _resetProgressState();
      } else {
        _checklistDetail = await _withWeatherEssential(detail);
        _initializeEditableInput(_checklistDetail!, resetBaseline: true);
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

  void updateEditableBudget({required double? totalBudget, String? currency}) {
    final detail = _checklistDetail;
    if (detail == null) {
      return;
    }
    final currentEditable =
        _editableInput ?? _ChecklistEditableInput.fromDetail(detail);
    _editableInput = currentEditable.copyWith(
      totalBudget: totalBudget,
      currency: currency ?? currentEditable.currency,
    );
    _checklistDetail = detail.copyWith(
      totalBudget: totalBudget,
      currency: (currency ?? detail.currency)?.trim(),
      currencySymbol: (currency ?? detail.currencySymbol)?.trim(),
    );
    _recomputeInputChanges();
    debugPrint(
      '[ChecklistEdit] input changed hasInputChanges=$_hasInputChanges',
    );
    notifyListeners();
  }

  Future<bool> savePlan() async {
    final detail = _checklistDetail;
    if (_currentChecklistId.isEmpty || detail == null) {
      return false;
    }

    debugPrint('[ChecklistEdit] save plan started');
    if (hasGeneratedPlan && !_hasInputChanges) {
      debugPrint('[ChecklistEdit] save plan completed');
      return true;
    }

    final input = _buildJourneyBasicInfoInput();
    if (input == null) {
      _errorMessage = 'checklistSaveFailed';
      notifyListeners();
      return false;
    }

    try {
      await repository.saveJourneyBasicInfo(
        checklistId: _currentChecklistId,
        input: input,
      );
      await loadChecklistDetail(_currentChecklistId, forceRefresh: true);
      debugPrint('[ChecklistEdit] save plan completed');
      return true;
    } catch (_) {
      _errorMessage = 'checklistSaveFailed';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updatePlanWithEditableInput() async {
    final detail = _checklistDetail;
    if (_currentChecklistId.isEmpty || detail == null) {
      return false;
    }
    final input = _buildJourneyBasicInfoInput();
    if (input == null) {
      _errorMessage = 'checklistSaveFailed';
      notifyListeners();
      return false;
    }

    debugPrint('[ChecklistEdit] update plan started');
    try {
      await repository.saveJourneyBasicInfo(
        checklistId: _currentChecklistId,
        input: input,
      );
    } catch (error) {
      debugPrint('[ChecklistEdit] update plan failed error=$error');
      _errorMessage = 'checklistSaveFailed';
      notifyListeners();
      return false;
    }

    final success = await generateChecklistPlan();
    if (success) {
      final latest = _checklistDetail;
      if (latest != null) {
        _initializeEditableInput(latest, resetBaseline: true);
      }
      debugPrint('[ChecklistEdit] update plan completed');
      return true;
    }

    debugPrint(
      '[ChecklistEdit] update plan failed error=${_errorMessage ?? 'unknown'}',
    );
    return false;
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

    final sessionId = ++_sessionSeed;
    _activeSessionId = sessionId;
    _cancelledSessionIds.remove(sessionId);
    _setButtonGeneratingState(true);
    _log('generate started sessionId=$sessionId');
    _log('checklistId=$_currentChecklistId');
    _log('detail loaded=${_checklistDetail != null}');
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
          if (_isSessionCancelled(sessionId)) {
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
        shouldCancel: () => _isSessionCancelled(sessionId),
      );
      if (_isSessionCancelled(sessionId)) {
        _log('ignored result because cancelled sessionId=$sessionId');
        return false;
      }
      _log('repository.generateChecklistPlan finished');
      final stateUpdateStopwatch = Stopwatch()..start();
      _setProgressState(
        step: ChecklistPlanProgressStep.preparingCards,
        progressPercent: 0.99,
      );
      _checklistDetail = await _withWeatherEssential(generatedDetail);
      _initializeEditableInput(_checklistDetail!, resetBaseline: true);
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
      _log('generate finished sessionId=$sessionId');
      _refreshDetailInBackground(_currentChecklistId);
      return true;
    } catch (error) {
      if (_isSessionCancelled(sessionId) ||
          (error is AppException &&
              error.code == 'checklist_generate_cancelled')) {
        _log('generate cancelled sessionId=$sessionId');
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
      _log('generate failed sessionId=$sessionId');
      return false;
    } finally {
      final isActiveSession = _activeSessionId == sessionId;
      if (isActiveSession) {
        _setButtonGeneratingState(false);
        _activeSessionId = null;
        notifyListeners();
      } else {
        _log('ignored result because cancelled sessionId=$sessionId');
      }
      _cancelledSessionIds.remove(sessionId);
    }
  }

  Future<void> updatePlan() async {
    _log('updatePlan called');
    await generateChecklistPlan();
  }

  void cancelPlanGeneration() {
    final sessionId = _activeSessionId;
    if (!_isGeneratingPlan || sessionId == null) {
      return;
    }
    _cancelledSessionIds.add(sessionId);
    _log('cancel requested sessionId=$sessionId');
    _activeSessionId = null;
    _setButtonGeneratingState(false);
    _resetProgressState();
    final detail = _checklistDetail;
    if (detail != null) {
      final currentStatus = (detail.planningStatus ?? '').trim().toLowerCase();
      if (currentStatus == 'generating') {
        _checklistDetail = detail.copyWith(planningStatus: 'readyToPlan');
      }
      _log(
        'cancel applied planningStatus=${_checklistDetail?.planningStatus ?? 'readyToPlan'}',
      );
    } else {
      _log('cancel applied planningStatus=readyToPlan');
    }
    notifyListeners();
  }

  bool _isSessionCancelled(int sessionId) {
    return _cancelledSessionIds.contains(sessionId) ||
        _activeSessionId != sessionId;
  }

  void _setButtonGeneratingState(bool value) {
    if (_isGeneratingPlan == value) {
      return;
    }
    _isGeneratingPlan = value;
    _log('button loading state changed isGenerating=$_isGeneratingPlan');
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
        _initializeEditableInput(weatherMerged, resetBaseline: true);
        notifyListeners();
      } catch (error) {
        _log('background reload failed error=$error');
      }
    });
  }

  void _initializeEditableInput(
    ChecklistDetail detail, {
    required bool resetBaseline,
  }) {
    final snapshot = _ChecklistEditableInput.fromDetail(detail);
    _editableInput = snapshot;
    if (resetBaseline) {
      _baselineInput = snapshot;
    }
    _recomputeInputChanges();
  }

  void _recomputeInputChanges() {
    final baseline = _baselineInput;
    final editable = _editableInput;
    if (baseline == null || editable == null) {
      _hasInputChanges = false;
      return;
    }
    final inputChanged = !editable.equalsForPlanning(baseline);
    final detail = _checklistDetail;
    if (detail == null) {
      _hasInputChanges = inputChanged;
      return;
    }
    final planningStatus = (detail.planningStatus ?? '').trim().toLowerCase();
    final hasStaleGeneratedPlan =
        planningStatus == 'readytoplan' && detail.items.isNotEmpty;
    _hasInputChanges = inputChanged || hasStaleGeneratedPlan;
  }

  JourneyBasicInfoInput? _buildJourneyBasicInfoInput() {
    final editable = _editableInput;
    if (editable == null) {
      return null;
    }
    final departureCity = editable.departureCity.trim();
    final currency = editable.currency.trim();
    final startDate = editable.startDate;
    final endDate = editable.endDate;
    final totalBudget = editable.totalBudget;
    if (departureCity.isEmpty ||
        startDate == null ||
        endDate == null ||
        endDate.isBefore(startDate) ||
        editable.travelerCount <= 0 ||
        (totalBudget ?? 0) <= 0 ||
        currency.isEmpty ||
        editable.preferences.isEmpty ||
        editable.pace.trim().isEmpty ||
        editable.accommodationPreference.trim().isEmpty) {
      return null;
    }

    final tripDays = endDate.difference(startDate).inDays + 1;
    final nightCount = endDate.difference(startDate).inDays;
    return JourneyBasicInfoInput(
      departureCity: departureCity,
      departureCountry: editable.departureCountry,
      departureLatitude: editable.departureLatitude,
      departureLongitude: editable.departureLongitude,
      departureSource: editable.departureSource,
      startDate: startDate,
      endDate: endDate,
      tripDays: tripDays,
      nightCount: nightCount,
      travelerCount: editable.travelerCount,
      totalBudget: totalBudget!,
      currency: currency,
      preferences: editable.preferences.toList(growable: false),
      pace: editable.pace,
      accommodationPreference: editable.accommodationPreference,
      basicInfoCompleted: true,
    );
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

class _ChecklistEditableInput {
  const _ChecklistEditableInput({
    required this.departureCity,
    required this.departureCountry,
    required this.departureLatitude,
    required this.departureLongitude,
    required this.departureSource,
    required this.startDate,
    required this.endDate,
    required this.travelerCount,
    required this.totalBudget,
    required this.currency,
    required this.preferences,
    required this.pace,
    required this.accommodationPreference,
  });

  factory _ChecklistEditableInput.fromDetail(ChecklistDetail detail) {
    return _ChecklistEditableInput(
      departureCity: detail.departureCity?.trim() ?? '',
      departureCountry: null,
      departureLatitude: null,
      departureLongitude: null,
      departureSource: 'manual',
      startDate: detail.startDate,
      endDate: detail.endDate,
      travelerCount: detail.travelerCount ?? 0,
      totalBudget: detail.totalBudget,
      currency: (detail.currency ?? detail.currencySymbol ?? '').trim(),
      preferences: detail.preferences
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toSet(),
      pace: detail.pace?.trim() ?? '',
      accommodationPreference: detail.accommodationPreference?.trim() ?? '',
    );
  }

  final String departureCity;
  final String? departureCountry;
  final double? departureLatitude;
  final double? departureLongitude;
  final String? departureSource;
  final DateTime? startDate;
  final DateTime? endDate;
  final int travelerCount;
  final double? totalBudget;
  final String currency;
  final Set<String> preferences;
  final String pace;
  final String accommodationPreference;

  _ChecklistEditableInput copyWith({
    String? departureCity,
    String? departureCountry,
    double? departureLatitude,
    double? departureLongitude,
    String? departureSource,
    DateTime? startDate,
    DateTime? endDate,
    int? travelerCount,
    double? totalBudget,
    String? currency,
    Set<String>? preferences,
    String? pace,
    String? accommodationPreference,
  }) {
    return _ChecklistEditableInput(
      departureCity: departureCity ?? this.departureCity,
      departureCountry: departureCountry ?? this.departureCountry,
      departureLatitude: departureLatitude ?? this.departureLatitude,
      departureLongitude: departureLongitude ?? this.departureLongitude,
      departureSource: departureSource ?? this.departureSource,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      travelerCount: travelerCount ?? this.travelerCount,
      totalBudget: totalBudget ?? this.totalBudget,
      currency: currency ?? this.currency,
      preferences: preferences ?? this.preferences,
      pace: pace ?? this.pace,
      accommodationPreference:
          accommodationPreference ?? this.accommodationPreference,
    );
  }

  bool equalsForPlanning(_ChecklistEditableInput other) {
    return departureCity.trim() == other.departureCity.trim() &&
        _sameDate(startDate, other.startDate) &&
        _sameDate(endDate, other.endDate) &&
        travelerCount == other.travelerCount &&
        _sameDouble(totalBudget, other.totalBudget) &&
        currency.trim().toUpperCase() == other.currency.trim().toUpperCase() &&
        _samePreferenceSet(preferences, other.preferences) &&
        pace.trim().toLowerCase() == other.pace.trim().toLowerCase() &&
        accommodationPreference.trim().toLowerCase() ==
            other.accommodationPreference.trim().toLowerCase();
  }

  bool _sameDate(DateTime? left, DateTime? right) {
    if (left == null || right == null) {
      return left == right;
    }
    return left.year == right.year &&
        left.month == right.month &&
        left.day == right.day;
  }

  bool _sameDouble(double? left, double? right) {
    if (left == null || right == null) {
      return left == right;
    }
    return (left - right).abs() < 0.0001;
  }

  bool _samePreferenceSet(Set<String> left, Set<String> right) {
    if (left.length != right.length) {
      return false;
    }
    for (final item in left) {
      if (!right.contains(item)) {
        return false;
      }
    }
    return true;
  }
}
