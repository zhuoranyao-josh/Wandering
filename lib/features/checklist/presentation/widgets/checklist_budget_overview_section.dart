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
    required this.transportLabel,
    required this.stayLabel,
    required this.foodActivitiesLabel,
    required this.adjustLabel,
    required this.notSetLabel,
    this.totalBudget,
    this.currencySymbol,
    this.budgetSplit,
    this.onEditTap,
    this.onAdjustTap,
  });

  final String totalBudgetLabel;
  final String setBudgetLabel;
  final String editLabel;
  final String budgetSplitLabel;
  final String transportLabel;
  final String stayLabel;
  final String foodActivitiesLabel;
  final String adjustLabel;
  final String notSetLabel;
  final double? totalBudget;
  final String? currencySymbol;
  final ChecklistBudgetSplit? budgetSplit;
  final VoidCallback? onEditTap;
  final VoidCallback? onAdjustTap;

  @override
  Widget build(BuildContext context) {
    // 棰勭畻鍖哄煙閲囩敤鍙屽崱骞舵帓甯冨眬锛屽乏鍙冲崱鐗囩瓑楂樸€?
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
              currencySymbol: currencySymbol,
              onEditTap: onEditTap,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ChecklistBudgetSplitCard(
              title: budgetSplitLabel,
              transportLabel: transportLabel,
              stayLabel: stayLabel,
              foodActivitiesLabel: foodActivitiesLabel,
              adjustLabel: adjustLabel,
              notSetLabel: notSetLabel,
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
    this.currencySymbol,
    this.onEditTap,
  });

  final String title;
  final String setBudgetLabel;
  final String editLabel;
  final double? totalBudget;
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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    title.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF2D5BEB),
                      letterSpacing: 0.6,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: onEditTap,
                  style: TextButton.styleFrom(
                    minimumSize: const Size(0, 34),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    backgroundColor: const Color(0xFFDCE7FF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  child: Text(
                    editLabel,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF2D5BEB),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              _buildBudgetText(context),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: totalBudget == null ? 24 : 30,
                color: totalBudget == null
                    ? const Color(0xFF9CA3AF)
                    : const Color(0xFF111827),
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }

  String _buildBudgetText(BuildContext context) {
    if (totalBudget == null) {
      return setBudgetLabel;
    }
    final formatter = NumberFormat.decimalPattern(
      Localizations.localeOf(context).toLanguageTag(),
    );
    final symbol = (currencySymbol ?? '').trim();
    return '$symbol${formatter.format(totalBudget)}';
  }
}
