import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/app_router.dart';
import '../../../../core/di/service_locator.dart';
import '../../domain/entities/checklist_detail.dart';
import '../../domain/entities/checklist_plan_progress.dart';
import '../../../../l10n/app_localizations.dart';
import '../controllers/checklist_detail_controller.dart';
import '../widgets/checklist_adjust_budget_split_sheet.dart';
import '../widgets/checklist_budget_overview_section.dart';
import '../widgets/checklist_header_section.dart';
import '../widgets/checklist_items_section.dart';
import '../widgets/checklist_pro_tip_card.dart';
import '../widgets/checklist_trip_essentials_section.dart';

class ChecklistDetailPage extends StatefulWidget {
  const ChecklistDetailPage({super.key, required this.checklistId});

  final String checklistId;

  @override
  State<ChecklistDetailPage> createState() => _ChecklistDetailPageState();
}

class _ChecklistDetailPageState extends State<ChecklistDetailPage>
    with RouteAware {
  static const double _horizontalPadding = 16;
  static const double _sectionSpacing = 24;

  late final ChecklistDetailController _controller =
      ServiceLocator.createChecklistDetailController();
  String? _lastErrorKey;
  Locale? _lastLocale;
  PageRoute<dynamic>? _pageRoute;
  bool _isPlanProgressDialogVisible = false;
  Stopwatch? _generateUiRenderStopwatch;
  bool _awaitingFirstGeneratedRender = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_handleControllerChange);
    _controller.loadChecklistDetail(widget.checklistId, forceRefresh: true);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute<dynamic> && route != _pageRoute) {
      if (_pageRoute != null) {
        AppRouter.routeObserver.unsubscribe(this);
      }
      _pageRoute = route;
      AppRouter.routeObserver.subscribe(this, route);
    }

    final currentLocale = Localizations.localeOf(context);
    if (_lastLocale == currentLocale) {
      return;
    }
    _lastLocale = currentLocale;
    _controller.updateLocale(currentLocale);
  }

  @override
  void didUpdateWidget(covariant ChecklistDetailPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.checklistId != widget.checklistId) {
      _controller.loadChecklistDetail(widget.checklistId, forceRefresh: true);
    }
  }

  @override
  void dispose() {
    if (_pageRoute != null) {
      AppRouter.routeObserver.unsubscribe(this);
    }
    _controller.removeListener(_handleControllerChange);
    _controller.dispose();
    super.dispose();
  }

  @override
  void didPopNext() {
    // 从 Wizard/其他子页面返回时，强制刷新详情，避免停留旧数据。
    _reloadDetailAfterWizard();
  }

  void _handleControllerChange() {
    final key = _controller.errorMessage;
    if (!mounted || key == null || key == _lastErrorKey) {
      return;
    }
    _lastErrorKey = key;

    final t = AppLocalizations.of(context);
    if (t == null) {
      return;
    }

    final message = _resolveErrorMessage(t, key);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    if (t == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF2F3F6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        centerTitle: true,
        title: Text(
          t.checklistTripChecklist,
          style: const TextStyle(
            fontSize: 19.5,
            fontWeight: FontWeight.w700,
            color: Color(0xFF111827),
          ),
        ),
        leading: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: IconButton(
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              }
            },
            icon: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: Color(0xFFF4F5F7),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 18,
                color: Color(0xFF111827),
              ),
            ),
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () async {
              debugPrint('[ChecklistEdit] wizard edit opened');
              await _openWizardForPlanning(isEditMode: true);
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            child: Text(
              t.checklistEdit,
              style: const TextStyle(
                fontSize: 17,
                color: Color(0xFF2F62EC),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          if (_controller.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_controller.errorMessage != null &&
              _controller.checklistDetail == null) {
            return _buildErrorState(t);
          }

          final detail = _controller.checklistDetail;
          if (detail == null) {
            return _buildNotFoundState(t);
          }

          _logFirstRenderAfterGenerated(detail);

          final displayEssentials = _buildTravelEssentials(detail, t);
          final displayProTip = _buildDisplayProTip(detail);
          final visibleChecklistItems = _buildVisibleChecklistItems(
            detail.items,
          );
          final showProTip = !displayProTip.isEmpty;
          final hasEssentials = displayEssentials.isNotEmpty;
          final isReadyToPlan = _controller.isReadyToPlan;
          final hasInputChanges = _controller.hasInputChanges;
          final shouldShowPlanningSummary = isReadyToPlan;

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              _horizontalPadding,
              18,
              _horizontalPadding,
              96,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // 页面结构：头部信息 -> 规划提示/风格摘要 -> 预算 -> Essentials -> Pro Tip -> Checklist。
                ChecklistHeaderSection(
                  destination: detail.resolvedDestinationName,
                  startDate: detail.startDate,
                  endDate: detail.endDate,
                  tripDays: detail.tripDays,
                  travelerCount: detail.travelerCount,
                ),
                if ((_controller.errorMessage ?? '')
                    .trim()
                    .isNotEmpty) ...<Widget>[
                  const SizedBox(height: 12),
                  _InlineErrorBanner(
                    message: _resolveErrorMessage(t, _controller.errorMessage!),
                  ),
                ],
                const SizedBox(height: 12),
                if (!isReadyToPlan)
                  _PlanningPromptCard(
                    title: t.checklistPlanningPromptTitle,
                    message: t.checklistPlanningPromptMessage,
                    buttonLabel: t.checklistStartPlanning,
                    onTap: () async {
                      await _openWizardForPlanning();
                    },
                  ),
                if (hasInputChanges) ...<Widget>[
                  const SizedBox(height: 12),
                  _InputChangedHintBanner(
                    message: t.checklistTripSettingsChangedHint,
                  ),
                ],
                if (_hasTravelStyleInfo(detail))
                  _TravelStyleSummaryCard(
                    t: t,
                    preferences: detail.preferences,
                    pace: detail.pace,
                    accommodationPreference: detail.accommodationPreference,
                  ),
                // 只有完成 Wizard 基础信息后，才展示预算与旅行要点摘要。
                if (shouldShowPlanningSummary) ...<Widget>[
                  const SizedBox(height: _sectionSpacing),
                  ChecklistBudgetOverviewSection(
                    totalBudgetLabel: t.checklistTotalBudget,
                    setBudgetLabel: t.checklistSetBudget,
                    editLabel: t.checklistEdit,
                    budgetSplitLabel: t.checklistSplit,
                    flightLabel: t.checklistFlight,
                    hotelLabel: t.checklistHotel,
                    foodLabel: t.checklistFood,
                    otherLabel: t.checklistOther,
                    adjustLabel: t.checklistAdjust,
                    notSetLabel: t.checklistNotSet,
                    totalBudget: detail.totalBudget,
                    currency: detail.currency,
                    currencySymbol: detail.currencySymbol,
                    budgetSplit: detail.budgetSplit,
                    onEditTap: () => _openBudgetEditDialog(detail, t),
                    onAdjustTap: () => _openAdjustBudgetSplitSheet(detail, t),
                  ),
                ],
                if (shouldShowPlanningSummary && hasEssentials) ...<Widget>[
                  const SizedBox(height: _sectionSpacing),
                  ChecklistTripEssentialsSection(
                    title: t.checklistTripEssentials,
                    essentials: displayEssentials,
                  ),
                ],
                if (showProTip) ...<Widget>[
                  const SizedBox(height: _sectionSpacing),
                  ChecklistProTipCard(
                    tagLabel: t.checklistProTip,
                    tipTitle: displayProTip.tipTitle?.trim() ?? '',
                    tipDescription: displayProTip.tipDescription?.trim() ?? '',
                  ),
                ],
                const SizedBox(height: _sectionSpacing),
                ChecklistItemsSection(
                  sectionTitle: t.checklistChecklist,
                  noItemsTitle: t.checklistNoItemsYet,
                  noItemsHint: t.checklistGenerateSuggestionsHint,
                  items: visibleChecklistItems,
                  startDate: detail.startDate,
                  onToggleCompleted: _controller.toggleItemCompleted,
                  onItemTap: _handleChecklistItemTap,
                ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
          child: SizedBox(
            height: 52,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final hasGeneratedPlan = _controller.hasGeneratedPlan;
                final hasInputChanges = _controller.hasInputChanges;
                final isReadyToPlan = _controller.isReadyToPlan;
                final saveEnabled =
                    !_controller.isGeneratingPlan &&
                    (!hasGeneratedPlan || !hasInputChanges);
                final updateEnabled =
                    !_controller.isGeneratingPlan &&
                    (hasGeneratedPlan ? hasInputChanges : true);
                final updateLabel = hasGeneratedPlan
                    ? t.checklistUpdatePlan
                    : t.checklistGeneratePlan;

                return Row(
                  children: <Widget>[
                    Expanded(
                      child: ElevatedButton(
                        onPressed: saveEnabled
                            ? () async {
                                if (!isReadyToPlan) {
                                  await _openWizardForPlanning(
                                    isEditMode: true,
                                  );
                                  return;
                                }
                                final success = await _controller.savePlan();
                                if (!mounted || !success) {
                                  return;
                                }
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          elevation: 0,
                          backgroundColor: const Color(0xFF10131E),
                          disabledBackgroundColor: const Color(0xFF9CA3AF),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          t.checklistSavePlan,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: updateEnabled
                            ? () async {
                                if (!hasGeneratedPlan) {
                                  await _handleGeneratePlanPressed();
                                  return;
                                }
                                if (!isReadyToPlan) {
                                  await _openWizardForPlanning();
                                  return;
                                }
                                _logGeneratePlanState(
                                  _controller.checklistDetail,
                                );
                                debugPrint(
                                  '[ChecklistPlan] start generation from detail',
                                );
                                if (!mounted) {
                                  return;
                                }
                                await _openPlanProgressDialogAndUpdate();
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          elevation: 0,
                          backgroundColor: const Color(0xFF10131E),
                          disabledBackgroundColor: const Color(0xFF9CA3AF),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: _controller.isGeneratingPlan
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.4,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                updateLabel,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(AppLocalizations t) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              _resolveErrorMessage(
                t,
                _controller.errorMessage ?? 'checklistLoadFailed',
              ),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF374151),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _controller.retry,
              child: Text(t.checklistRetry),
            ),
          ],
        ),
      ),
    );
  }

  String _resolveErrorMessage(AppLocalizations t, String key) {
    if (key == 'checklistLoadFailed') {
      return t.checklistLoadFailed;
    }
    if (key == 'checklistGenerateFailed') {
      return t.checklistGenerateFailed;
    }
    if (key == 'checklistSaveFailed') {
      return t.journeyWizardSaveFailed;
    }
    if (key.trim().isEmpty) {
      return t.errorUnknown;
    }
    return key;
  }

  Future<void> _reloadDetailAfterWizard() async {
    debugPrint(
      '[ChecklistDetail] reload after wizard checklistId=${widget.checklistId}',
    );
    await _controller.refreshChecklistDetail(
      checklistId: widget.checklistId,
      forceRefresh: true,
    );
    debugPrint(
      '[ChecklistDetail] basicInfoCompleted='
      '${_controller.checklistDetail?.basicInfoCompleted}',
    );
  }

  Future<void> _openWizardForPlanning({bool isEditMode = false}) async {
    await context.push(
      AppRouter.checklistWizard(widget.checklistId, isEditMode: isEditMode),
    );
    if (!mounted) {
      return;
    }
    await _reloadDetailAfterWizard();
  }

  Future<void> _handleGeneratePlanPressed() async {
    // 生成前主动拉取最新详情，避免 Wizard 刚保存后按钮仍读取旧状态。
    await _controller.refreshChecklistDetail(
      checklistId: widget.checklistId,
      forceRefresh: true,
    );
    if (!mounted) {
      return;
    }

    final detail = _controller.checklistDetail;
    _logGeneratePlanState(detail);
    final isReadyToPlan =
        detail != null &&
        (detail.basicInfoCompleted || detail.isBasicInfoComplete);
    if (!isReadyToPlan) {
      debugPrint(
        '[ChecklistPlan] redirect to wizard reason=basicInfoIncomplete',
      );
      await _openWizardForPlanning();
      return;
    }

    debugPrint('[ChecklistPlan] start generation from detail');
    await _openPlanProgressDialogAndGenerate();
  }

  void _logGeneratePlanState(ChecklistDetail? detail) {
    debugPrint(
      '[ChecklistPlan] generate clicked basicInfoCompleted='
      '${detail?.basicInfoCompleted}',
    );
    final missingFields = _collectMissingPlanningFields(detail);
    if (missingFields.isNotEmpty) {
      debugPrint(
        '[ChecklistPlan] missing required fields=${missingFields.join(', ')}',
      );
    }
  }

  List<String> _collectMissingPlanningFields(ChecklistDetail? detail) {
    if (detail == null) {
      return const <String>['detail'];
    }
    final missingFields = <String>[];
    if (!detail.hasValidDestination &&
        detail.resolvedDestinationName.trim().isEmpty) {
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
    if ((detail.totalBudget ?? 0) <= 0) {
      missingFields.add('totalBudget');
    }
    if ((detail.currency?.trim().isNotEmpty ?? false) == false) {
      missingFields.add('currency');
    }
    if ((detail.travelerCount ?? 0) <= 0) {
      missingFields.add('travelerCount');
    }
    if ((detail.pace?.trim().isNotEmpty ?? false) == false) {
      missingFields.add('pace');
    }
    if ((detail.accommodationPreference?.trim().isNotEmpty ?? false) == false) {
      missingFields.add('accommodationPreference');
    }
    if (detail.preferences.isEmpty) {
      missingFields.add('preferences');
    }
    return missingFields;
  }

  Future<void> _openPlanProgressDialogAndGenerate() async {
    await _openPlanProgressDialog(
      execute: _controller.generateChecklistPlan,
      markCompleted: true,
    );
  }

  Future<void> _openPlanProgressDialogAndUpdate() async {
    await _openPlanProgressDialog(
      execute: _controller.updatePlanWithEditableInput,
      markCompleted: false,
    );
  }

  Future<void> _openPlanProgressDialog({
    required Future<bool> Function() execute,
    required bool markCompleted,
  }) async {
    if (!mounted || _isPlanProgressDialogVisible) {
      return;
    }

    _isPlanProgressDialogVisible = true;
    _markGenerationStartForUiRender();
    final dialogFuture = showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return PopScope(
          canPop: !_controller.isGeneratingPlan,
          child: Dialog(
            insetPadding: const EdgeInsets.symmetric(horizontal: 24),
            backgroundColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final t = AppLocalizations.of(context);
                final detail = _controller.checklistDetail;
                if (t == null || detail == null) {
                  return const Padding(
                    padding: EdgeInsets.all(20),
                    child: SizedBox(
                      height: 96,
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  );
                }

                final isFailed = _isPlanProgressFailed(detail);
                return ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: 420,
                    maxHeight: MediaQuery.of(context).size.height * 0.62,
                  ),
                  child: _PlanGenerationProgressCard(
                    title: _resolvePlanProgressTitle(t, detail),
                    message: _resolvePlanProgressMessage(t, detail),
                    progressPercent: _controller.progressPercent,
                    progressLabel: _resolvePlanProgressLabel(t),
                    isGenerating: _controller.isGeneratingPlan,
                    isFailed: isFailed,
                    retryLabel: t.checklistRetry,
                    cancelLabel: t.cancel,
                    onCancel: _controller.isGeneratingPlan
                        ? () {
                            _controller.cancelPlanGeneration();
                            if (dialogContext.mounted) {
                              Navigator.of(dialogContext).pop();
                            }
                          }
                        : null,
                    onRetry: isFailed && !_controller.isGeneratingPlan
                        ? () async {
                            _markGenerationStartForUiRender();
                            final success = await execute();
                            if (!mounted || !success) {
                              return;
                            }
                            if (markCompleted) {
                              _markGenerationCompletedAwaitingRender();
                            }
                            if (dialogContext.mounted) {
                              Navigator.of(dialogContext).pop();
                            }
                          }
                        : null,
                  ),
                );
              },
            ),
          ),
        );
      },
    );
    dialogFuture.whenComplete(() {
      _isPlanProgressDialogVisible = false;
    });

    final success = await execute();
    if (success && mounted) {
      if (markCompleted) {
        _markGenerationCompletedAwaitingRender();
      }
      Navigator.of(context, rootNavigator: true).pop();
    }
    await dialogFuture;
  }

  Future<void> _openBudgetEditDialog(
    ChecklistDetail detail,
    AppLocalizations t,
  ) async {
    debugPrint('[ChecklistEdit] budget edit opened');
    FocusScope.of(context).unfocus();
    final result = await showModalBottomSheet<_BudgetEditResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        return _BudgetEditSheet(
          t: t,
          initialTotalBudget: detail.totalBudget,
          initialCurrency: detail.currency,
        );
      },
    );

    if (!mounted || result == null) {
      return;
    }
    _controller.updateEditableBudget(
      totalBudget: result.totalBudget,
      currency: result.currency,
    );
  }

  Future<void> _openAdjustBudgetSplitSheet(
    ChecklistDetail detail,
    AppLocalizations t,
  ) async {
    final result = await showModalBottomSheet<ChecklistBudgetSplit>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        return ChecklistAdjustBudgetSplitSheet(
          title: t.checklistAdjustBudgetSplitTitle,
          flexibleBudgetHint: t.checklistAdjustBudgetSplitHint,
          saveLabel: t.save,
          cancelLabel: t.cancel,
          flightLabel: t.checklistFlight,
          hotelLabel: t.checklistHotel,
          foodLabel: t.checklistFood,
          otherLabel: t.checklistOther,
          notSetLabel: t.checklistNotSet,
          totalBudget: detail.totalBudget,
          currency: (detail.currency ?? '').trim(),
          currencySymbol: (detail.currencySymbol ?? '').trim(),
          budgetSplit: detail.budgetSplit,
        );
      },
    );
    if (!mounted || result == null) {
      return;
    }
    await _controller.updateBudgetSplit(split: result);
  }

  void _markGenerationStartForUiRender() {
    _generateUiRenderStopwatch = Stopwatch()..start();
    _awaitingFirstGeneratedRender = false;
  }

  void _markGenerationCompletedAwaitingRender() {
    _awaitingFirstGeneratedRender = true;
  }

  void _logFirstRenderAfterGenerated(ChecklistDetail detail) {
    if (!_awaitingFirstGeneratedRender) {
      return;
    }
    final planningStatus = (detail.planningStatus ?? '').trim().toLowerCase();
    if (planningStatus != 'completed') {
      return;
    }
    _awaitingFirstGeneratedRender = false;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final stopwatch = _generateUiRenderStopwatch;
      if (stopwatch == null) {
        return;
      }
      debugPrint(
        '[ChecklistPlan] first UI render after generated '
        'elapsed=${stopwatch.elapsedMilliseconds}ms',
      );
      _generateUiRenderStopwatch = null;
    });
  }

  bool _isPlanProgressFailed(ChecklistDetail detail) {
    if (_controller.progressStep == ChecklistPlanProgressStep.failed) {
      return true;
    }
    final planningStatus = (detail.planningStatus ?? '').trim().toLowerCase();
    return planningStatus == 'failed';
  }

  String _resolvePlanProgressLabel(AppLocalizations t) {
    final percent = (_controller.progressPercent * 100).clamp(0, 100).round();
    return t.checklistPlanProgressPercent(percent);
  }

  String _resolvePlanProgressTitle(AppLocalizations t, ChecklistDetail detail) {
    final step = _controller.progressStep;
    if (step == null &&
        (detail.planningStatus ?? '').trim().toLowerCase() == 'generating') {
      return t.checklistPlanProgressStillGeneratingTitle;
    }
    switch (step) {
      case ChecklistPlanProgressStep.preparingTripInformation:
        return t.checklistPlanProgressPreparingTitle;
      case ChecklistPlanProgressStep.analyzingBudget:
        return t.checklistPlanProgressAnalyzingBudgetTitle;
      case ChecklistPlanProgressStep.generatingAiTravelPlan:
        return t.checklistPlanProgressGeneratingAiTitle;
      case ChecklistPlanProgressStep.findingFlightSuggestions:
        return t.checklistPlanProgressFindingFlightsTitle;
      case ChecklistPlanProgressStep.findingHotels:
        return t.checklistPlanProgressFindingHotelsTitle;
      case ChecklistPlanProgressStep.findingRestaurants:
        return t.checklistPlanProgressFindingRestaurantsTitle;
      case ChecklistPlanProgressStep.findingActivities:
        return t.checklistPlanProgressFindingActivitiesTitle;
      case ChecklistPlanProgressStep.savingChecklist:
        return t.checklistPlanProgressSavingTitle;
      case ChecklistPlanProgressStep.preparingCards:
        return t.checklistPlanProgressPreparingCardsTitle;
      case ChecklistPlanProgressStep.finalizingPlan:
        return t.checklistPlanProgressFinalizingTitle;
      case ChecklistPlanProgressStep.completed:
        return t.checklistPlanProgressCompletedTitle;
      case ChecklistPlanProgressStep.failed:
        return t.checklistPlanProgressFailedTitle;
      case null:
        return t.checklistPlanProgressPreparingTitle;
    }
  }

  String _resolvePlanProgressMessage(
    AppLocalizations t,
    ChecklistDetail detail,
  ) {
    final step = _controller.progressStep;
    final current = _controller.progressCurrentItemIndex;
    final total = _controller.progressTotalItemCount;
    final hasPartialFailures = _controller.progressHasPartialFailures;

    final baseMessage = switch (step) {
      ChecklistPlanProgressStep.preparingTripInformation =>
        t.checklistPlanProgressPreparingMessage,
      ChecklistPlanProgressStep.analyzingBudget =>
        t.checklistPlanProgressAnalyzingBudgetMessage,
      ChecklistPlanProgressStep.generatingAiTravelPlan =>
        t.checklistPlanProgressGeneratingAiMessage,
      ChecklistPlanProgressStep.findingFlightSuggestions =>
        t.checklistPlanProgressFindingFlightsMessage,
      ChecklistPlanProgressStep.findingHotels =>
        (current != null && total != null && total > 0)
            ? t.checklistPlanProgressFindingHotelsCount(current, total)
            : t.checklistPlanProgressFindingHotelsMessage,
      ChecklistPlanProgressStep.findingRestaurants =>
        (current != null && total != null && total > 0)
            ? t.checklistPlanProgressFindingRestaurantsCount(current, total)
            : t.checklistPlanProgressFindingRestaurantsMessage,
      ChecklistPlanProgressStep.findingActivities =>
        (current != null && total != null && total > 0)
            ? t.checklistPlanProgressFindingActivitiesCount(current, total)
            : t.checklistPlanProgressFindingActivitiesMessage,
      ChecklistPlanProgressStep.savingChecklist =>
        t.checklistPlanProgressSavingMessage,
      ChecklistPlanProgressStep.preparingCards =>
        t.checklistPlanProgressPreparingCardsMessage,
      ChecklistPlanProgressStep.finalizingPlan =>
        t.checklistPlanProgressFinalizingMessage,
      ChecklistPlanProgressStep.completed =>
        t.checklistPlanProgressCompletedMessage,
      ChecklistPlanProgressStep.failed => _resolveErrorMessage(
        t,
        _controller.errorMessage ?? 'checklistGenerateFailed',
      ),
      null =>
        (detail.planningStatus ?? '').trim().toLowerCase() == 'generating'
            ? t.checklistPlanProgressStillGeneratingMessage
            : t.checklistPlanProgressPreparingMessage,
    };

    if (hasPartialFailures &&
        step != ChecklistPlanProgressStep.failed &&
        step != ChecklistPlanProgressStep.completed) {
      return '$baseMessage\n${t.checklistPlanProgressPartialEnrichMessage}';
    }
    return baseMessage;
  }

  Widget _buildNotFoundState(AppLocalizations t) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          t.checklistNotFound,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF6B7280),
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  bool _hasTravelStyleInfo(ChecklistDetail detail) {
    final hasPreferences = detail.preferences.isNotEmpty;
    final hasPace = (detail.pace?.trim().isNotEmpty ?? false);
    final hasAccommodation =
        (detail.accommodationPreference?.trim().isNotEmpty ?? false);
    return hasPreferences || hasPace || hasAccommodation;
  }

  List<ChecklistEssential> _buildTravelEssentials(
    ChecklistDetail detail,
    AppLocalizations t,
  ) {
    // 四宫格标题固定，AI 只负责填充正文，避免标题随模型输出漂移。
    final slots = <_EssentialSlot, ChecklistEssential>{};
    for (final item in detail.essentials) {
      final slot = _resolveEssentialSlot(item);
      if (slot == null || slots.containsKey(slot)) {
        continue;
      }
      slots[slot] = item;
    }

    ChecklistEssential compose({
      required _EssentialSlot slot,
      required String fixedTitle,
      required String fallbackIconType,
    }) {
      final source = slots[slot];
      return ChecklistEssential(
        iconType: source?.iconType.trim().isNotEmpty == true
            ? source!.iconType
            : fallbackIconType,
        title: fixedTitle,
        mainText: source?.mainText.trim() ?? '',
        subText: source?.subText?.trim(),
      );
    }

    return <ChecklistEssential>[
      compose(
        slot: _EssentialSlot.weather,
        fixedTitle: t.checklistEssentialWeatherTitle,
        fallbackIconType: 'weather',
      ),
      compose(
        slot: _EssentialSlot.tradeOff,
        fixedTitle: t.checklistEssentialTradeOffTitle,
        fallbackIconType: 'trade_off',
      ),
      compose(
        slot: _EssentialSlot.strategy,
        fixedTitle: t.checklistEssentialStrategyTitle,
        fallbackIconType: 'strategy',
      ),
      compose(
        slot: _EssentialSlot.tips,
        fixedTitle: t.checklistEssentialTipsTitle,
        fallbackIconType: 'tips',
      ),
    ];
  }

  _EssentialSlot? _resolveEssentialSlot(ChecklistEssential item) {
    final typeCandidate = _normalizeEssentialToken(item.iconType);
    final titleCandidate = _normalizeEssentialToken(item.title);
    final candidates = <String>[typeCandidate, titleCandidate];

    for (final token in candidates) {
      if (token.contains('weather')) {
        return _EssentialSlot.weather;
      }
      if (token.contains('tradeoff') || token.contains('trade_off')) {
        return _EssentialSlot.tradeOff;
      }
      if (token.contains('strategy')) {
        return _EssentialSlot.strategy;
      }
      if (token.contains('tips') || token == 'tip') {
        return _EssentialSlot.tips;
      }
    }
    return null;
  }

  String _normalizeEssentialToken(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9_]'), '');
  }

  ChecklistProTip _buildDisplayProTip(ChecklistDetail detail) {
    final current = detail.proTip;
    if (current != null && !current.isEmpty) {
      return current;
    }
    return const ChecklistProTip();
  }

  List<ChecklistDetailItem> _buildVisibleChecklistItems(
    List<ChecklistDetailItem> items,
  ) {
    return items
        .where((item) {
          final normalizedType = (item.type ?? '').trim().toLowerCase();
          // Weather / Essentials / Budget 在上方独立信息区展示，避免和条目卡片混排。
          return normalizedType != 'weather' &&
              normalizedType != 'essentials' &&
              normalizedType != 'budget';
        })
        .toList(growable: false);
  }

  Future<void> _handleChecklistItemTap(ChecklistDetailItem item) async {
    // 仅航班卡支持外链跳转，其他类型维持现有交互。
    final normalizedType = (item.type ?? '').trim().toLowerCase();
    if (normalizedType != 'flight') {
      return;
    }
    final rawUrl = (item.externalUrl ?? item.googleFlightsUrl ?? '').trim();
    if (rawUrl.isEmpty) {
      return;
    }
    final uri = Uri.tryParse(rawUrl);
    if (uri == null) {
      return;
    }
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

enum _EssentialSlot { weather, tradeOff, strategy, tips }

class _PlanningPromptCard extends StatelessWidget {
  const _PlanningPromptCard({
    required this.title,
    required this.message,
    required this.buttonLabel,
    required this.onTap,
  });

  final String title;
  final String message;
  final String buttonLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: const TextStyle(
              fontSize: 13,
              height: 1.4,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 38,
            child: ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: const Color(0xFF111827),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(buttonLabel),
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineErrorBanner extends StatelessWidget {
  const _InlineErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Text(
        message,
        style: const TextStyle(
          fontSize: 13,
          height: 1.4,
          color: Color(0xFFB91C1C),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _InputChangedHintBanner extends StatelessWidget {
  const _InputChangedHintBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Text(
        message,
        style: const TextStyle(
          fontSize: 13,
          height: 1.4,
          color: Color(0xFF1D4ED8),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _PlanGenerationProgressCard extends StatelessWidget {
  const _PlanGenerationProgressCard({
    required this.title,
    required this.message,
    required this.progressPercent,
    required this.progressLabel,
    required this.isGenerating,
    required this.isFailed,
    required this.retryLabel,
    required this.cancelLabel,
    this.onRetry,
    this.onCancel,
  });

  final String title;
  final String message;
  final double progressPercent;
  final String progressLabel;
  final bool isGenerating;
  final bool isFailed;
  final String retryLabel;
  final String cancelLabel;
  final VoidCallback? onRetry;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final clampedProgress = progressPercent.clamp(0.0, 1.0).toDouble();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isFailed ? const Color(0xFFFECACA) : const Color(0xFFE5E7EB),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                if (isGenerating)
                  const Padding(
                    padding: EdgeInsets.only(top: 1.5),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: Color(0xFF2F62EC),
                      ),
                    ),
                  ),
                if (isGenerating) const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isFailed
                          ? const Color(0xFFB91C1C)
                          : const Color(0xFF111827),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(
                fontSize: 12.5,
                height: 1.35,
                color: isFailed
                    ? const Color(0xFFB91C1C)
                    : const Color(0xFF667085),
              ),
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                minHeight: 6,
                value: isFailed ? null : clampedProgress,
                backgroundColor: const Color(0xFFE5E7EB),
                valueColor: AlwaysStoppedAnimation<Color>(
                  isFailed ? const Color(0xFFEF4444) : const Color(0xFF2F62EC),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              progressLabel,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF6B7280),
              ),
            ),
            if (isGenerating || (isFailed && onRetry != null)) ...<Widget>[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  if (isGenerating && onCancel != null)
                    TextButton(
                      onPressed: onCancel,
                      style: TextButton.styleFrom(
                        minimumSize: Size.zero,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(cancelLabel),
                    ),
                  if (isFailed && onRetry != null)
                    TextButton(
                      onPressed: onRetry,
                      style: TextButton.styleFrom(
                        minimumSize: Size.zero,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(retryLabel),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TravelStyleSummaryCard extends StatelessWidget {
  const _TravelStyleSummaryCard({
    required this.t,
    required this.preferences,
    this.pace,
    this.accommodationPreference,
  });

  final AppLocalizations t;
  final List<String> preferences;
  final String? pace;
  final String? accommodationPreference;

  @override
  Widget build(BuildContext context) {
    final preferenceChipText = _buildPreferenceChipText();
    final paceChipText = _buildLabeledChipText(
      label: t.journeyWizardPace,
      value: _mapPaceLabel(pace?.trim() ?? ''),
    );
    final accommodationChipText = _buildLabeledChipText(
      label: t.checklistAccommodationLabel,
      value: _mapAccommodationLabel(accommodationPreference?.trim() ?? ''),
    );

    if (preferenceChipText == null &&
        paceChipText == null &&
        accommodationChipText == null) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        // 娑撱倛顢戦弽鍥╊劮娴ｆ粈璐熸稉鈧稉顏呮殻娴ｆ挾绮烘稉鈧Ο顏勬倻濠婃艾濮╅妴?
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              t.checklistTravelStyleTitle,
              style: const TextStyle(
                fontSize: 12,
                letterSpacing: 0.4,
                fontWeight: FontWeight.w700,
                color: Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 8),
            if (preferenceChipText != null)
              Row(children: <Widget>[_StyleChip(text: preferenceChipText)]),
            if (paceChipText != null ||
                accommodationChipText != null) ...<Widget>[
              if (preferenceChipText != null) const SizedBox(height: 8),
              Row(
                children: <Widget>[
                  if (paceChipText != null) _StyleChip(text: paceChipText),
                  if (paceChipText != null && accommodationChipText != null)
                    const SizedBox(width: 8),
                  if (accommodationChipText != null)
                    _StyleChip(text: accommodationChipText),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String? _buildPreferenceChipText() {
    final normalized = preferences
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
    if (normalized.isEmpty) {
      return null;
    }

    return _buildLabeledChipText(
      label: t.journeyWizardPreferences,
      value: normalized.map(_mapPreferenceLabel).join(' | '),
    );
  }

  String? _buildLabeledChipText({required String label, String? value}) {
    final trimmedValue = value?.trim() ?? '';
    if (trimmedValue.isEmpty) {
      return null;
    }
    return '$label: $trimmedValue';
  }

  String _mapPreferenceLabel(String key) {
    switch (key) {
      case 'food':
        return t.journeyWizardPreferenceFood;
      case 'shopping':
        return t.journeyWizardPreferenceShopping;
      case 'culture':
        return t.journeyWizardPreferenceCulture;
      case 'nature':
        return t.journeyWizardPreferenceNature;
      case 'museum':
        return t.journeyWizardPreferenceMuseum;
      case 'anime':
        return t.journeyWizardPreferenceAnime;
      case 'nightlife':
        return t.journeyWizardPreferenceNightlife;
      case 'family':
        return t.journeyWizardPreferenceFamily;
      case 'photography':
        return t.journeyWizardPreferencePhotography;
      case 'relaxation':
        return t.journeyWizardPreferenceRelaxation;
      default:
        return key;
    }
  }

  String? _mapPaceLabel(String key) {
    if (key.isEmpty) {
      return null;
    }
    switch (key) {
      case 'relaxed':
        return t.journeyWizardPaceRelaxed;
      case 'balanced':
        return t.journeyWizardPaceBalanced;
      case 'intensive':
        return t.journeyWizardPaceIntensive;
      default:
        return key;
    }
  }

  String? _mapAccommodationLabel(String key) {
    if (key.isEmpty) {
      return null;
    }
    switch (key) {
      case 'budget':
        return t.journeyWizardAccommodationBudget;
      case 'luxury':
        return t.journeyWizardAccommodationLuxury;
      case 'convenient':
        return t.journeyWizardAccommodationComfortable;
      case 'comfortable':
        return t.journeyWizardAccommodationComfortable;
      case 'premium':
        return t.journeyWizardAccommodationLuxury;
      default:
        return key;
    }
  }
}

class _StyleChip extends StatelessWidget {
  const _StyleChip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        softWrap: false,
        style: const TextStyle(
          fontSize: 12,
          color: Color(0xFF111827),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _BudgetEditSheet extends StatefulWidget {
  const _BudgetEditSheet({
    required this.t,
    required this.initialTotalBudget,
    required this.initialCurrency,
  });

  final AppLocalizations t;
  final double? initialTotalBudget;
  final String? initialCurrency;

  @override
  State<_BudgetEditSheet> createState() => _BudgetEditSheetState();
}

class _BudgetEditSheetState extends State<_BudgetEditSheet> {
  static const List<String> _currencyOptions = <String>[
    'CNY',
    'USD',
    'EUR',
    'JPY',
  ];

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _textController = TextEditingController(
    text: widget.initialTotalBudget == null
        ? ''
        : widget.initialTotalBudget!.toStringAsFixed(
            widget.initialTotalBudget! % 1 == 0 ? 0 : 2,
          ),
  );
  late String _selectedCurrency = _resolveInitialCurrency();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final safeBottom = MediaQuery.of(context).padding.bottom;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.62,
          child: Column(
            children: <Widget>[
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Center(
                          child: Container(
                            width: 44,
                            height: 4,
                            decoration: BoxDecoration(
                              color: const Color(0xFFD1D5DB),
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: Text(
                                widget.t.checklistTotalBudget,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF111827),
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: _close,
                              icon: const Icon(
                                Icons.close_rounded,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // 输入框状态由弹层自己持有，避免关闭动画期间父页面提前释放 controller。
                        _BudgetEditorFieldCard(
                          label: widget.t.journeyWizardTotalBudget,
                          child: TextFormField(
                            controller: _textController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            autofocus: true,
                            decoration: _inputDecoration(
                              hintText: widget.t.journeyWizardTotalBudgetHint,
                            ),
                            validator: (value) {
                              final parsed = double.tryParse(
                                (value ?? '').trim(),
                              );
                              if (parsed == null || parsed <= 0) {
                                return widget
                                    .t
                                    .journeyWizardErrorBudgetRequired;
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(height: 14),
                        _BudgetEditorFieldCard(
                          label: widget.t.journeyWizardCurrency,
                          child: DropdownButtonFormField<String>(
                            initialValue: _selectedCurrency,
                            decoration: _inputDecoration(),
                            items: _currencyOptions
                                .map(
                                  (currencyCode) => DropdownMenuItem<String>(
                                    value: currencyCode,
                                    child: Text(currencyCode),
                                  ),
                                )
                                .toList(growable: false),
                            onChanged: (value) {
                              setState(() {
                                _selectedCurrency = (value ?? 'CNY').trim();
                              });
                            },
                            validator: (value) {
                              if ((value ?? '').trim().isEmpty) {
                                return widget
                                    .t
                                    .journeyWizardErrorCurrencyRequired;
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.fromLTRB(20, 12, 20, 16 + safeBottom),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
                ),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _close,
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(50),
                          side: const BorderSide(color: Color(0xFFD1D5DB)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(widget.t.cancel),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _save,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(50),
                          elevation: 0,
                          backgroundColor: const Color(0xFF10131E),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          widget.t.save,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _resolveInitialCurrency() {
    final normalized = (widget.initialCurrency ?? '').trim().toUpperCase();
    return _currencyOptions.contains(normalized) ? normalized : 'CNY';
  }

  InputDecoration _inputDecoration({String? hintText}) {
    return InputDecoration(
      hintText: hintText,
      isDense: true,
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      enabledBorder: _fieldBorder(const Color(0xFFE5E7EB)),
      focusedBorder: _fieldBorder(const Color(0xFF2F62EC), width: 1.4),
      errorBorder: _fieldBorder(const Color(0xFFEF4444)),
      focusedErrorBorder: _fieldBorder(const Color(0xFFEF4444), width: 1.4),
    );
  }

  OutlineInputBorder _fieldBorder(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  Future<void> _close() async {
    FocusManager.instance.primaryFocus?.unfocus();
    // 先让输入焦点和键盘完成解绑，再关闭弹层，避免 TextField 依赖树还未清理就被销毁。
    await Future<void>.delayed(Duration.zero);
    if (!mounted) {
      return;
    }
    Navigator.of(context).pop();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    final parsed = double.tryParse(_textController.text.trim());
    if (parsed == null || parsed <= 0) {
      return;
    }
    // 保存同样等待焦点释放完成，减少 bottom sheet 关闭动画期间的生命周期冲突。
    await Future<void>.delayed(Duration.zero);
    if (!mounted) {
      return;
    }
    Navigator.of(
      context,
    ).pop(_BudgetEditResult(totalBudget: parsed, currency: _selectedCurrency));
  }
}

class _BudgetEditResult {
  const _BudgetEditResult({required this.totalBudget, required this.currency});

  final double totalBudget;
  final String currency;
}

class _BudgetEditorFieldCard extends StatelessWidget {
  const _BudgetEditorFieldCard({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x0A111827),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}
