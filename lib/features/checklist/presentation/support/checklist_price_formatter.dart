import 'package:intl/intl.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/checklist_detail.dart';

class ChecklistPriceDisplay {
  const ChecklistPriceDisplay({
    required this.primaryText,
    this.secondaryText,
  });

  final String primaryText;
  final String? secondaryText;

  bool get isEmpty =>
      primaryText.trim().isEmpty && (secondaryText ?? '').trim().isEmpty;
}

class ChecklistPriceFormatter {
  static ChecklistPriceDisplay build({
    required ChecklistDetailItem item,
    required AppLocalizations? t,
  }) {
    final currencySymbol = _resolveCurrencySymbol(item.currency);
    final unitText = _resolveUnitText(item.costUnit, t);
    final structuredRange = _selectStructuredRange(item);
    final legacyRange = structuredRange == null ? _selectLegacyRange(item) : null;
    final range = structuredRange ?? legacyRange;

    if (range == null) {
      return ChecklistPriceDisplay(
        primaryText: t?.checklistPriceUnavailable ?? 'Price unavailable',
      );
    }

    final primaryAmount = range.average;
    if (primaryAmount == null) {
      return ChecklistPriceDisplay(
        primaryText: t?.checklistPriceUnavailable ?? 'Price unavailable',
      );
    }

    final primaryText = _buildPrimaryText(
      amount: primaryAmount,
      currencySymbol: currencySymbol,
      unitText: unitText,
      t: t,
    );
    final secondaryText = range.hasVisibleRange
        ? _buildRangeText(
            min: range.min!,
            max: range.max!,
            currencySymbol: currencySymbol,
          )
        : null;

    return ChecklistPriceDisplay(
      primaryText: primaryText,
      secondaryText: secondaryText,
    );
  }

  static String _buildPrimaryText({
    required double amount,
    required String currencySymbol,
    required String unitText,
    required AppLocalizations? t,
  }) {
    final aboutText = t?.checklistPriceAbout ?? 'About';
    final formattedAmount = _formatAmount(amount);
    final unitSuffix = unitText.isNotEmpty ? ' / $unitText' : '';
    return '$aboutText $currencySymbol$formattedAmount$unitSuffix';
  }

  static String _buildRangeText({
    required double min,
    required double max,
    required String currencySymbol,
  }) {
    final minText = _formatAmount(min);
    final maxText = _formatAmount(max);
    return '$currencySymbol$minText \u2013 $currencySymbol$maxText';
  }

  static _PriceRange? _selectStructuredRange(ChecklistDetailItem item) {
    final min = item.estimatedCostMin;
    final max = item.estimatedCostMax;
    if (min == null && max == null) {
      return null;
    }
    return _PriceRange(min: min, max: max);
  }

  static _PriceRange? _selectLegacyRange(ChecklistDetailItem item) {
    final min = item.estimatedPriceMin;
    final max = item.estimatedPriceMax;
    if (min == null && max == null) {
      return null;
    }
    return _PriceRange(min: min, max: max);
  }

  static String _resolveUnitText(String? costUnit, AppLocalizations? t) {
    switch ((costUnit ?? '').trim().toLowerCase()) {
      case 'per_person':
        return t?.checklistPriceUnitPerson ?? 'person';
      case 'per_meal':
        return t?.checklistPriceUnitMeal ?? 'meal';
      case 'per_ticket':
        return t?.checklistPriceUnitTicket ?? 'ticket';
      case 'per_night':
        return t?.checklistPriceUnitNight ?? 'night';
      default:
        return '';
    }
  }

  static String _resolveCurrencySymbol(String? currencyCode) {
    switch ((currencyCode ?? '').trim().toUpperCase()) {
      case 'CNY':
      case 'JPY':
        return '\u00A5';
      case 'USD':
        return '\$';
      case 'EUR':
        return '\u20AC';
      case 'GBP':
        return '\u00A3';
      default:
        final code = (currencyCode ?? '').trim();
        return code.isNotEmpty ? '$code ' : '\u00A5';
    }
  }

  static String _formatAmount(double value) {
    return NumberFormat.decimalPattern().format(value);
  }
}

class _PriceRange {
  const _PriceRange({
    required this.min,
    required this.max,
  });

  final double? min;
  final double? max;

  double? get average {
    final minValue = min;
    final maxValue = max;
    if (minValue != null && maxValue != null) {
      return (minValue + maxValue) / 2;
    }
    return minValue ?? maxValue;
  }

  bool get hasVisibleRange => min != null && max != null && min != max;
}
