import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/app_router.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../l10n/app_localizations.dart';
import '../controllers/journey_wizard_controller.dart';

class JourneyWizardPage extends StatefulWidget {
  const JourneyWizardPage({
    super.key,
    required this.checklistId,
    this.isEditMode = false,
  });

  final String checklistId;
  final bool isEditMode;

  @override
  State<JourneyWizardPage> createState() => _JourneyWizardPageState();
}

class _JourneyWizardPageState extends State<JourneyWizardPage> {
  late final JourneyWizardController _controller =
      ServiceLocator.createJourneyWizardController(
        checklistId: widget.checklistId,
      );
  final TextEditingController _departureCityController =
      TextEditingController();
  final TextEditingController _budgetController = TextEditingController();
  String? _lastErrorKey;
  bool _didSyncInitialInput = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_handleControllerChange);
    _controller.loadJourney();
  }

  @override
  void dispose() {
    _controller.removeListener(_handleControllerChange);
    _departureCityController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  void _handleControllerChange() {
    _syncInitialInputs();

    final errorKey = _controller.errorKey;
    if (!mounted || errorKey == null || errorKey == _lastErrorKey) {
      return;
    }

    _lastErrorKey = errorKey;
    final t = AppLocalizations.of(context);
    if (t == null) {
      return;
    }
    final message = _resolveErrorText(t, errorKey);
    if (message != null && message.isNotEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
    _controller.clearError();
  }

  void _syncInitialInputs() {
    if (_didSyncInitialInput || _controller.journey == null) {
      return;
    }
    _didSyncInitialInput = true;
    _departureCityController.text = _controller.departureCity;
    final budget = _controller.totalBudget;
    if (budget != null && budget > 0) {
      _budgetController.text = budget.toStringAsFixed(budget % 1 == 0 ? 0 : 2);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    if (t == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: Text(t.journeyWizardTitle),
      ),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          if (_controller.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_controller.notFound) {
            return _buildNotFoundState(t);
          }

          final journey = _controller.journey;
          if (journey == null) {
            return _buildErrorState(t);
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _buildDestinationHeader(t, journey.destination),
                const SizedBox(height: 16),
                _buildStepProgress(t),
                const SizedBox(height: 24),
                _buildStepContent(t),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          if (_controller.isLoading ||
              _controller.notFound ||
              _controller.journey == null) {
            return const SizedBox.shrink();
          }
          return _buildBottomActions(t);
        },
      ),
    );
  }

  Widget _buildDestinationHeader(AppLocalizations t, String destination) {
    final displayDestination = destination.trim().isEmpty
        ? t.journeyWizardUnknownDestination
        : destination.trim();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            t.journeyWizardTripTitle(displayDestination),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            t.journeyWizardPlanToDestination(displayDestination),
            style: const TextStyle(fontSize: 15, color: Color(0xFF4B5563)),
          ),
          const SizedBox(height: 4),
          Text(
            displayDestination,
            style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
          ),
        ],
      ),
    );
  }

  Widget _buildStepProgress(AppLocalizations t) {
    final step = _controller.currentStep + 1;
    final progress = step / 3;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          t.journeyWizardStepOf(step, 3),
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF6B7280),
          ),
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: const Color(0xFFE5E7EB),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
          ),
        ),
      ],
    );
  }

  Widget _buildStepContent(AppLocalizations t) {
    switch (_controller.currentStep) {
      case 0:
        return _buildTravelBasicsStep(t);
      case 1:
        return _buildBudgetStyleStep(t);
      case 2:
        return _buildReviewStep(t);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildTravelBasicsStep(AppLocalizations t) {
    final startDate = _controller.startDate;
    final endDate = _controller.endDate;
    final tripDays = _controller.tripDays;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          t.journeyWizardTravelBasics,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _departureCityController,
          decoration: InputDecoration(
            labelText: t.journeyWizardDepartureCity,
            hintText: t.journeyWizardDepartureCityHint,
            errorText: _resolveErrorText(
              t,
              _controller.fieldErrorKey('departureCity'),
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onChanged: _controller.setDepartureCity,
        ),
        const SizedBox(height: 12),
        _DateField(
          label: t.journeyWizardDateRange,
          valueText: _buildDateRangeText(context, startDate, endDate),
          onTap: () => _pickDateRange(context),
          errorText:
              _resolveErrorText(t, _controller.fieldErrorKey('startDate')) ??
              _resolveErrorText(t, _controller.fieldErrorKey('endDate')),
        ),
        if (tripDays != null) ...<Widget>[
          const SizedBox(height: 10),
          Text(
            t.journeyWizardTripDays(tripDays),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF4B5563),
            ),
          ),
        ],
        const SizedBox(height: 16),
        Text(
          t.journeyWizardTravelerCount,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFD1D5DB)),
          ),
          child: Row(
            children: <Widget>[
              IconButton(
                onPressed: _controller.decreaseTravelerCount,
                icon: const Icon(Icons.remove_circle_outline),
              ),
              Expanded(
                child: Text(
                  '${_controller.travelerCount}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
              ),
              IconButton(
                onPressed: _controller.increaseTravelerCount,
                icon: const Icon(Icons.add_circle_outline),
              ),
            ],
          ),
        ),
        if (_controller.fieldErrorKey('travelerCount') != null) ...<Widget>[
          const SizedBox(height: 8),
          Text(
            _resolveErrorText(t, _controller.fieldErrorKey('travelerCount')) ??
                '',
            style: const TextStyle(fontSize: 12, color: Color(0xFFDC2626)),
          ),
        ],
      ],
    );
  }

  Widget _buildBudgetStyleStep(AppLocalizations t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          t.journeyWizardBudgetStyle,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _budgetController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: t.journeyWizardTotalBudget,
            hintText: t.journeyWizardTotalBudgetHint,
            errorText: _resolveErrorText(
              t,
              _controller.fieldErrorKey('totalBudget'),
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onChanged: _controller.setTotalBudgetFromText,
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: _controller.currency,
          decoration: InputDecoration(
            labelText: t.journeyWizardCurrency,
            errorText: _resolveErrorText(
              t,
              _controller.fieldErrorKey('currency'),
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          items: const <DropdownMenuItem<String>>[
            DropdownMenuItem<String>(value: 'CNY', child: Text('CNY')),
            DropdownMenuItem<String>(value: 'USD', child: Text('USD')),
            DropdownMenuItem<String>(value: 'EUR', child: Text('EUR')),
            DropdownMenuItem<String>(value: 'JPY', child: Text('JPY')),
          ],
          onChanged: (value) {
            if (value == null) {
              return;
            }
            _controller.setCurrency(value);
          },
        ),
        const SizedBox(height: 20),
        _buildSectionLabel(t.journeyWizardPreferences),
        const SizedBox(height: 10),
        // 偏好使用多选 Chip，最多选择 5 项。
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: JourneyWizardController.preferenceOptions
              .map((option) {
                final selected = _controller.preferences.contains(option);
                return FilterChip(
                  selected: selected,
                  label: Text(_preferenceLabel(t, option)),
                  onSelected: (_) => _controller.togglePreference(option),
                );
              })
              .toList(growable: false),
        ),
        if (_controller.fieldErrorKey('preferences') != null) ...<Widget>[
          const SizedBox(height: 8),
          Text(
            _resolveErrorText(t, _controller.fieldErrorKey('preferences')) ??
                '',
            style: const TextStyle(fontSize: 12, color: Color(0xFFDC2626)),
          ),
        ],
        const SizedBox(height: 20),
        _buildSectionLabel(t.journeyWizardPace),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: JourneyWizardController.paceOptions
              .map((option) {
                final selected = _controller.pace == option;
                return ChoiceChip(
                  selected: selected,
                  label: Text(_paceLabel(t, option)),
                  onSelected: (_) => _controller.setPace(option),
                );
              })
              .toList(growable: false),
        ),
        const SizedBox(height: 20),
        _buildSectionLabel(t.journeyWizardAccommodationPreference),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: JourneyWizardController.accommodationOptions
              .map((option) {
                final selected = _controller.accommodationPreference == option;
                return ChoiceChip(
                  selected: selected,
                  label: Text(_accommodationLabel(t, option)),
                  onSelected: (_) =>
                      _controller.setAccommodationPreference(option),
                );
              })
              .toList(growable: false),
        ),
      ],
    );
  }

  Widget _buildReviewStep(AppLocalizations t) {
    final journey = _controller.journey;
    if (journey == null) {
      return const SizedBox.shrink();
    }
    final resolvedDestination = journey.resolvedDestinationName;
    final destination = resolvedDestination.isEmpty
        ? t.journeyWizardUnknownDestination
        : resolvedDestination;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          t.journeyWizardReview,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 16),
        _SummaryCard(
          rows: <_SummaryRowData>[
            _SummaryRowData(
              label: t.journeyWizardDestination,
              value: destination,
            ),
            _SummaryRowData(
              label: t.journeyWizardDepartureCity,
              value: _controller.departureCity.trim(),
            ),
            _SummaryRowData(
              label: t.journeyWizardDateRange,
              value: _buildDateRangeText(
                context,
                _controller.startDate,
                _controller.endDate,
              ),
            ),
            _SummaryRowData(
              label: t.journeyWizardTripDaysLabel,
              value: _controller.tripDays != null
                  ? '${_controller.tripDays}'
                  : '--',
            ),
            _SummaryRowData(
              label: t.journeyWizardTravelerCount,
              value: '${_controller.travelerCount}',
            ),
            _SummaryRowData(
              label: t.journeyWizardTotalBudget,
              value: _buildBudgetText(
                _controller.totalBudget,
                _controller.currency,
              ),
            ),
            _SummaryRowData(
              label: t.journeyWizardPreferences,
              value: _controller.preferences.isEmpty
                  ? '--'
                  : _controller.preferences
                        .map((item) => _preferenceLabel(t, item))
                        .join(', '),
            ),
            _SummaryRowData(
              label: t.journeyWizardPace,
              value: _paceLabel(t, _controller.pace),
            ),
            _SummaryRowData(
              label: t.journeyWizardAccommodationPreference,
              value: _accommodationLabel(
                t,
                _controller.accommodationPreference,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBottomActions(AppLocalizations t) {
    final step = _controller.currentStep;
    final isSaving = _controller.isSaving;
    final showBack = step > 0;
    final primaryLabel = step == 2
        ? t.journeyWizardStartAnalysis
        : t.journeyWizardContinue;

    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Row(
        children: <Widget>[
          if (showBack) ...<Widget>[
            Expanded(
              child: OutlinedButton(
                onPressed: isSaving ? null : _controller.previousStep,
                child: Text(t.journeyWizardBack),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            flex: showBack ? 2 : 1,
            child: ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      if (step < 2) {
                        _controller.nextStep();
                        return;
                      }
                      debugPrint('[ChecklistWizard] submit started');
                      final success = await _controller.saveJourneyBasicInfo();
                      if (!mounted || !success) {
                        return;
                      }
                      debugPrint(
                        '[ChecklistWizard] save completed '
                        'checklistId=${widget.checklistId}',
                      );
                      debugPrint(
                        '[ChecklistWizard] navigating to detail '
                        'checklistId=${widget.checklistId}',
                      );
                      if (widget.isEditMode) {
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.go(
                            AppRouter.checklistDetail(widget.checklistId),
                          );
                        }
                        return;
                      }
                      context.go(AppRouter.checklistDetail(widget.checklistId));
                    },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(primaryLabel),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotFoundState(AppLocalizations t) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              t.checklistNotFound,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _controller.retry,
              child: Text(t.checklistRetry),
            ),
          ],
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
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _controller.retry,
              child: Text(t.checklistRetry),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Color(0xFF111827),
      ),
    );
  }

  Future<void> _pickDateRange(BuildContext context) async {
    final now = DateTime.now();
    final initialStart = _controller.startDate ?? now;
    final rawInitialEnd = _controller.endDate ?? initialStart;
    final initialEnd = rawInitialEnd.isBefore(initialStart)
        ? initialStart
        : rawInitialEnd;
    final picked = await showDateRangePicker(
      context: context,
      firstDate: now.subtract(const Duration(days: 3650)),
      lastDate: now.add(const Duration(days: 3650)),
      initialDateRange: DateTimeRange(start: initialStart, end: initialEnd),
    );
    if (picked == null) {
      return;
    }
    _controller.setDateRange(startDate: picked.start, endDate: picked.end);
  }

  String _buildDateRangeText(
    BuildContext context,
    DateTime? start,
    DateTime? end,
  ) {
    if (start == null && end == null) {
      return '--';
    }
    final locale = Localizations.localeOf(context).toLanguageTag();
    final formatter = DateFormat.yMMMd(locale);
    if (start != null && end != null) {
      return '${formatter.format(start)} - ${formatter.format(end)}';
    }
    if (start != null) {
      return formatter.format(start);
    }
    return formatter.format(end!);
  }

  String _buildBudgetText(double? budget, String currency) {
    if (budget == null || budget <= 0) {
      return '--';
    }
    final normalized = budget % 1 == 0
        ? budget.toStringAsFixed(0)
        : budget.toStringAsFixed(2);
    return '$currency $normalized';
  }

  String _preferenceLabel(AppLocalizations t, String key) {
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

  String _paceLabel(AppLocalizations t, String key) {
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

  String _accommodationLabel(AppLocalizations t, String key) {
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

  String? _resolveErrorText(AppLocalizations t, String? errorKey) {
    switch (errorKey) {
      case 'checklistLoadFailed':
        return t.checklistLoadFailed;
      case 'checklistSaveFailed':
        return t.journeyWizardSaveFailed;
      case 'journeyWizardErrorDepartureCityRequired':
        return t.journeyWizardErrorDepartureCityRequired;
      case 'journeyWizardErrorStartDateRequired':
        return t.journeyWizardErrorStartDateRequired;
      case 'journeyWizardErrorEndDateRequired':
        return t.journeyWizardErrorEndDateRequired;
      case 'journeyWizardErrorEndDateBeforeStartDate':
        return t.journeyWizardErrorEndDateBeforeStartDate;
      case 'journeyWizardErrorTravelerCountMin':
        return t.journeyWizardErrorTravelerCountMin;
      case 'journeyWizardErrorTravelerCountMax':
        return t.journeyWizardErrorTravelerCountMax;
      case 'journeyWizardErrorBudgetRequired':
        return t.journeyWizardErrorBudgetRequired;
      case 'journeyWizardErrorCurrencyRequired':
        return t.journeyWizardErrorCurrencyRequired;
      case 'journeyWizardErrorPreferencesRequired':
        return t.journeyWizardErrorPreferencesRequired;
      case 'journeyWizardErrorPreferencesMax':
        return t.journeyWizardErrorPreferencesMax;
      case 'journeyWizardErrorPaceRequired':
        return t.journeyWizardErrorPaceRequired;
      case 'journeyWizardErrorAccommodationRequired':
        return t.journeyWizardErrorAccommodationRequired;
      default:
        return null;
    }
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.valueText,
    required this.onTap,
    this.errorText,
  });

  final String label;
  final String valueText;
  final VoidCallback onTap;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFD1D5DB)),
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    '$label: $valueText',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF111827),
                    ),
                  ),
                ),
                const Icon(Icons.calendar_today_outlined, size: 18),
              ],
            ),
          ),
        ),
        if (errorText != null && errorText!.trim().isNotEmpty) ...<Widget>[
          const SizedBox(height: 6),
          Text(
            errorText!,
            style: const TextStyle(fontSize: 12, color: Color(0xFFDC2626)),
          ),
        ],
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.rows});

  final List<_SummaryRowData> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: rows
            .map((row) => _SummaryRow(label: row.label, value: row.value))
            .toList(growable: false),
      ),
    );
  }
}

class _SummaryRowData {
  const _SummaryRowData({required this.label, required this.value});

  final String label;
  final String value;
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
            ),
          ),
          Expanded(
            child: Text(
              value.trim().isEmpty ? '--' : value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF111827),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
