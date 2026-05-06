import 'package:flutter/material.dart';

import '../../domain/entities/checklist_detail.dart';

class ChecklistBudgetSplitCard extends StatelessWidget {
  const ChecklistBudgetSplitCard({
    super.key,
    required this.title,
    required this.flightLabel,
    required this.hotelLabel,
    required this.foodLabel,
    required this.otherLabel,
    required this.adjustLabel,
    required this.notSetLabel,
    required this.totalBudget,
    required this.currencySymbol,
    this.budgetSplit,
    this.onAdjustTap,
  });

  final String title;
  final String flightLabel;
  final String hotelLabel;
  final String foodLabel;
  final String otherLabel;
  final String adjustLabel;
  final String notSetLabel;
  final double? totalBudget;
  final String? currencySymbol;
  final ChecklistBudgetSplit? budgetSplit;
  final VoidCallback? onAdjustTap;

  @override
  Widget build(BuildContext context) {
    final allocation = (budgetSplit ?? const ChecklistBudgetSplit())
        .resolveAllocation(
          totalBudget: totalBudget,
          currencySymbol: currencySymbol,
        );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 11),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  _SplitInlineText(
                    label: flightLabel,
                    value: '${allocation.flightPercent.round()}%',
                  ),
                  const SizedBox(height: 4),
                  _SplitInlineText(
                    label: hotelLabel,
                    value: '${allocation.hotelPercent.round()}%',
                  ),
                  const SizedBox(height: 4),
                  _SplitInlineText(
                    label: foodLabel,
                    value: '${allocation.foodPercent.round()}%',
                  ),
                  const SizedBox(height: 4),
                  _SplitInlineText(
                    label: otherLabel,
                    value: '${allocation.otherPercent.round()}%',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    title.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF111827),
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: onAdjustTap,
                  style: TextButton.styleFrom(
                    minimumSize: const Size(0, 30),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                      side: const BorderSide(color: Color(0xFFD1D5DB)),
                    ),
                  ),
                  child: Text(
                    adjustLabel,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF374151),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SplitInlineText extends StatelessWidget {
  const _SplitInlineText({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              height: 1.15,
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            height: 1.15,
            color: Color(0xFF111827),
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
