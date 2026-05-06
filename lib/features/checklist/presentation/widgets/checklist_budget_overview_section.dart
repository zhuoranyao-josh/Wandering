import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/checklist_detail.dart';
import 'checklist_budget_split_card.dart';

class ChecklistBudgetOverviewSection extends StatelessWidget {
  const ChecklistBudgetOverviewSection({
    super.key,
    required this.totalBudgetLabel,
    required this.setBudgetLabel,
    required this.editLabel,
    required this.budgetSplitLabel,
    required this.flightLabel,
    required this.hotelLabel,
    required this.foodLabel,
    required this.otherLabel,
    required this.adjustLabel,
    required this.notSetLabel,
    this.totalBudget,
    this.currency,
    this.currencySymbol,
    this.budgetSplit,
    this.onEditTap,
    this.onAdjustTap,
  });

  final String totalBudgetLabel;
  final String setBudgetLabel;
  final String editLabel;
  final String budgetSplitLabel;
  final String flightLabel;
  final String hotelLabel;
  final String foodLabel;
  final String otherLabel;
  final String adjustLabel;
  final String notSetLabel;
  final double? totalBudget;
  final String? currency;
  final String? currencySymbol;
  final ChecklistBudgetSplit? budgetSplit;
  final VoidCallback? onEditTap;
  final VoidCallback? onAdjustTap;

  @override
  Widget build(BuildContext context) {
    // 预算区域保持双卡并排，并通过更紧凑的内边距压低整体高度。
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Expanded(
            child: _TotalBudgetCard(
              title: totalBudgetLabel,
              setBudgetLabel: setBudgetLabel,
              editLabel: editLabel,
              totalBudget: totalBudget,
              currency: currency,
              currencySymbol: currencySymbol,
              onEditTap: onEditTap,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ChecklistBudgetSplitCard(
              title: budgetSplitLabel,
              flightLabel: flightLabel,
              hotelLabel: hotelLabel,
              foodLabel: foodLabel,
              otherLabel: otherLabel,
              adjustLabel: adjustLabel,
              notSetLabel: notSetLabel,
              totalBudget: totalBudget,
              currencySymbol: currencySymbol,
              budgetSplit: budgetSplit,
              onAdjustTap: onAdjustTap,
            ),
          ),
        ],
      ),
    );
  }
}

class _TotalBudgetCard extends StatelessWidget {
  const _TotalBudgetCard({
    required this.title,
    required this.setBudgetLabel,
    required this.editLabel,
    this.totalBudget,
    this.currency,
    this.currencySymbol,
    this.onEditTap,
  });

  final String title;
  final String setBudgetLabel;
  final String editLabel;
  final double? totalBudget;
  final String? currency;
  final String? currencySymbol;
  final VoidCallback? onEditTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFEFF3FF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD7E1FF)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: Text(
                    title.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF2D5BEB),
                      letterSpacing: 0.6,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: onEditTap,
                  style: TextButton.styleFrom(
                    minimumSize: const Size(0, 30),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    backgroundColor: const Color(0xFFDCE7FF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  child: Text(
                    editLabel,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF2D5BEB),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildBudgetValue(context),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetValue(BuildContext context) {
    if (totalBudget == null) {
      return Text(
        setBudgetLabel,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 22,
          color: Color(0xFF9CA3AF),
          fontWeight: FontWeight.w700,
        ),
      );
    }

    final display = _buildBudgetDisplay(context);
    return Text.rich(
      TextSpan(
        children: <InlineSpan>[
          TextSpan(
            text: display.amountText,
            style: const TextStyle(
              fontSize: 28,
              color: Color(0xFF111827),
              fontWeight: FontWeight.w700,
            ),
          ),
          if (display.currencyText.isNotEmpty)
            TextSpan(
              text: ' ${display.currencyText}',
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  _BudgetDisplayParts _buildBudgetDisplay(BuildContext context) {
    final formatter = NumberFormat.decimalPattern(
      Localizations.localeOf(context).toLanguageTag(),
    );
    final amountText = formatter.format(totalBudget);
    final symbol = (currencySymbol ?? '').trim();
    if (symbol.isNotEmpty) {
      return _BudgetDisplayParts(amountText: amountText, currencyText: symbol);
    }
    final currencyCode = (currency ?? '').trim();
    if (currencyCode.isNotEmpty) {
      return _BudgetDisplayParts(
        amountText: amountText,
        currencyText: currencyCode,
      );
    }
    return _BudgetDisplayParts(amountText: amountText, currencyText: '');
  }
}

class _BudgetDisplayParts {
  const _BudgetDisplayParts({
    required this.amountText,
    required this.currencyText,
  });

  final String amountText;
  final String currencyText;
}
