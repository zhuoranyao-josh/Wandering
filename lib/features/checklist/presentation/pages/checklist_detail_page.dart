import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/app_router.dart';
import '../../../../core/di/service_locator.dart';
import '../../domain/entities/checklist_detail.dart';
import '../../../../l10n/app_localizations.dart';
import '../controllers/checklist_detail_controller.dart';
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

class _ChecklistDetailPageState extends State<ChecklistDetailPage> {
  static const double _horizontalPadding = 16;
  static const double _sectionSpacing = 24;

  late final ChecklistDetailController _controller =
      ServiceLocator.createChecklistDetailController();
  String? _lastErrorKey;
  Locale? _lastLocale;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_handleControllerChange);
    _controller.loadChecklistDetail(widget.checklistId);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final currentLocale = Localizations.localeOf(context);
    if (_lastLocale == currentLocale) {
      return;
    }
    _lastLocale = currentLocale;
    _controller.updateLocale(currentLocale);
  }

  @override
  void dispose() {
    _controller.removeListener(_handleControllerChange);
    _controller.dispose();
    super.dispose();
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

    final message = key == 'checklistLoadFailed'
        ? t.checklistLoadFailed
        : key == 'checklistGenerateFailed'
        ? t.checklistGenerateFailed
        : t.errorUnknown;
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
            onPressed: () {},
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

          if (_controller.errorMessage != null) {
            return _buildErrorState(t);
          }

          final detail = _controller.checklistDetail;
          if (detail == null) {
            return _buildNotFoundState(t);
          }

          final displayEssentials = _buildTravelEssentials(detail, t);
          final displayProTip = _buildDisplayProTip(detail, t);
          final visibleChecklistItems = _buildVisibleChecklistItems(
            detail.items,
          );
          final showProTip = !displayProTip.isEmpty;
          final hasEssentials = displayEssentials.isNotEmpty;
          final isReadyToPlan =
              detail.basicInfoCompleted || detail.isBasicInfoComplete;

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
                  destination: detail.destination,
                  startDate: detail.startDate,
                  endDate: detail.endDate,
                  tripDays: detail.tripDays,
                  travelerCount: detail.travelerCount,
                ),
                const SizedBox(height: 12),
                if (!isReadyToPlan)
                  _PlanningPromptCard(
                    title: t.checklistPlanningPromptTitle,
                    message: t.checklistPlanningPromptMessage,
                    buttonLabel: t.checklistStartPlanning,
                    onTap: () => context.push(
                      AppRouter.checklistWizard(widget.checklistId),
                    ),
                  ),
                if (_hasTravelStyleInfo(detail))
                  _TravelStyleSummaryCard(
                    t: t,
                    preferences: detail.preferences,
                    pace: detail.pace,
                    accommodationPreference: detail.accommodationPreference,
                  ),
                const SizedBox(height: _sectionSpacing),
                ChecklistBudgetOverviewSection(
                  totalBudgetLabel: t.checklistTotalBudget,
                  setBudgetLabel: t.checklistSetBudget,
                  editLabel: t.checklistEdit,
                  budgetSplitLabel: t.checklistSplit,
                  transportLabel: t.checklistTransport,
                  stayLabel: t.checklistStay,
                  foodActivitiesLabel: t.checklistFoodActivities,
                  adjustLabel: t.checklistAdjust,
                  notSetLabel: t.checklistNotSet,
                  totalBudget: detail.totalBudget,
                  currencySymbol: detail.currencySymbol,
                  budgetSplit: detail.budgetSplit,
                  // 预算编辑与分配调整后续再接弹窗，这次先保留点击位。
                  onEditTap: () {},
                  onAdjustTap: () {},
                ),
                if (hasEssentials) ...<Widget>[
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
                  onItemTap: (_) {},
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
                final detail = _controller.checklistDetail;
                final isReadyToPlan =
                    detail?.basicInfoCompleted == true ||
                    detail?.isBasicInfoComplete == true;
                final buttonLabel = isReadyToPlan
                    ? t.checklistGeneratePlan
                    : t.checklistStartPlanning;

                return ElevatedButton(
                  onPressed: _controller.isGeneratingPlan
                      ? null
                      : () async {
                          if (!isReadyToPlan) {
                            context.push(
                              AppRouter.checklistWizard(widget.checklistId),
                            );
                            return;
                          }
                          await _controller.generateChecklistPlan();
                        },
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: const Color(0xFF10131E),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
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
                          buttonLabel,
                          style: const TextStyle(
                            fontSize: 19.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
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
              t.checklistLoadFailed,
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
    final normalizedMap = <String, ChecklistEssential>{};
    for (final item in detail.essentials) {
      final key = item.title.trim().toLowerCase().replaceAll(' ', '');
      if (item.mainText.trim().isEmpty) {
        continue;
      }
      normalizedMap[key] = item;
    }

    final weatherFromData = normalizedMap['weather'];
    final weatherCard =
        weatherFromData ??
        ChecklistEssential(
          iconType: 'weather',
          title: t.checklistEssentialWeatherTitle,
          mainText: t.checklistEssentialWeatherMockValue,
          subText: t.checklistEssentialWeatherMockDescription,
        );

    final keys = <String>['tradeoff', 'strategy', 'tips'];
    final hasStructuredAiSummary = keys.every(normalizedMap.containsKey);
    if (hasStructuredAiSummary) {
      return <ChecklistEssential>[
        weatherCard,
        normalizedMap['tradeoff']!,
        normalizedMap['strategy']!,
        normalizedMap['tips']!,
      ];
    }

    // 先用 UI mock 占位，后续 AI 接入后可直接替换为真实摘要。
    return <ChecklistEssential>[
      weatherCard,
      ChecklistEssential(
        iconType: 'tradeoff',
        title: t.checklistEssentialTradeOffTitle,
        mainText: t.checklistEssentialTradeOffMockValue,
        subText: t.checklistEssentialTradeOffMockDescription,
      ),
      ChecklistEssential(
        iconType: 'strategy',
        title: t.checklistEssentialStrategyTitle,
        mainText: t.checklistEssentialStrategyMockValue,
        subText: t.checklistEssentialStrategyMockDescription,
      ),
      ChecklistEssential(
        iconType: 'tips',
        title: t.checklistEssentialTipsTitle,
        mainText: t.checklistEssentialTipsMockValue,
        subText: t.checklistEssentialTipsMockDescription,
      ),
    ];
  }

  ChecklistProTip _buildDisplayProTip(
    ChecklistDetail detail,
    AppLocalizations t,
  ) {
    final current = detail.proTip;
    if (current != null && !current.isEmpty) {
      return current;
    }

    return ChecklistProTip(
      tipTitle: t.checklistProTipMockTitle,
      tipDescription: t.checklistProTipMockDescription,
    );
  }

  List<ChecklistDetailItem> _buildVisibleChecklistItems(
    List<ChecklistDetailItem> items,
  ) {
    return items
        .where((item) {
          final normalizedType = (item.type ?? '').trim().toLowerCase();
          // Weather / Essentials / Budget 改在上方独立信息区展示，避免和机酒条目挤在一起。
          return normalizedType != 'weather' &&
              normalizedType != 'essentials' &&
              normalizedType != 'budget';
        })
        .toList(growable: false);
  }
}

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
        // 涓よ鏍囩浣滀负涓€涓暣浣撶粺涓€妯悜婊氬姩銆?
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
      case 'convenient':
        return t.journeyWizardAccommodationConvenient;
      case 'comfortable':
        return t.journeyWizardAccommodationComfortable;
      case 'premium':
        return t.journeyWizardAccommodationPremium;
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
