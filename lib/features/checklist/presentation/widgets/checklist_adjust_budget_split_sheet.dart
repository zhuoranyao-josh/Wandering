import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/checklist_detail.dart';

class ChecklistAdjustBudgetSplitSheet extends StatefulWidget {
  const ChecklistAdjustBudgetSplitSheet({
    super.key,
    required this.title,
    required this.flexibleBudgetHint,
    required this.saveLabel,
    required this.cancelLabel,
    required this.flightLabel,
    required this.hotelLabel,
    required this.foodLabel,
    required this.otherLabel,
    required this.notSetLabel,
    required this.currency,
    required this.currencySymbol,
    this.totalBudget,
    this.budgetSplit,
  });

  final String title;
  final String flexibleBudgetHint;
  final String saveLabel;
  final String cancelLabel;
  final String flightLabel;
  final String hotelLabel;
  final String foodLabel;
  final String otherLabel;
  final String notSetLabel;
  final String currency;
  final String currencySymbol;
  final double? totalBudget;
  final ChecklistBudgetSplit? budgetSplit;

  @override
  State<ChecklistAdjustBudgetSplitSheet> createState() =>
      _ChecklistAdjustBudgetSplitSheetState();
}

class _ChecklistAdjustBudgetSplitSheetState
    extends State<ChecklistAdjustBudgetSplitSheet> {
  static const int _minPercent = 5;
  static const int _maxPercent = 85;

  late int _flightPercent;
  late int _hotelPercent;
  late int _foodPercent;
  late int _otherPercent;

  @override
  void initState() {
    super.initState();
    final allocation = (widget.budgetSplit ?? const ChecklistBudgetSplit())
        .resolveAllocation(
          totalBudget: widget.totalBudget,
          currencySymbol: widget.currency,
        );
    _flightPercent = allocation.flightPercent.round();
    _hotelPercent = allocation.hotelPercent.round();
    _foodPercent = allocation.foodPercent.round();
    _otherPercent = allocation.otherPercent.round();
    _normalizeRemainder(preferredCategory: _BudgetCategory.other);
  }

  @override
  Widget build(BuildContext context) {
    final allocation = _buildAllocation();
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final safeBottom = MediaQuery.of(context).padding.bottom;
    return SafeArea(
      top: false,
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.88,
        child: Column(
          children: <Widget>[
            // 主体区域允许滚动，避免 slider 和底部按钮发生 overflow。
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
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
                            widget.title,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF111827),
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(
                            Icons.close_rounded,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.flexibleBudgetHint,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF6B7280),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 22),
                    _BudgetDonutCard(
                      currencyLabel: widget.currencySymbol.isEmpty
                          ? widget.currency
                          : widget.currencySymbol,
                      totalBudgetText: _formatBudget(widget.totalBudget),
                      legendItems: <_BudgetLegendItem>[
                        _BudgetLegendItem(
                          label: widget.flightLabel,
                          color: const Color(0xFF2550D8),
                        ),
                        _BudgetLegendItem(
                          label: widget.hotelLabel,
                          color: const Color(0xFF4A78FF),
                        ),
                        _BudgetLegendItem(
                          label: widget.foodLabel,
                          color: const Color(0xFF7EA7FF),
                        ),
                        _BudgetLegendItem(
                          label: widget.otherLabel,
                          color: const Color(0xFFC7D8FF),
                        ),
                      ],
                      child: SizedBox(
                        width: 168,
                        height: 168,
                        child: CustomPaint(
                          painter: _BudgetDonutPainter(
                            flightPercent: _flightPercent,
                            hotelPercent: _hotelPercent,
                            foodPercent: _foodPercent,
                            otherPercent: _otherPercent,
                          ),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Text(
                                  widget.currencySymbol.isEmpty
                                      ? widget.currency
                                      : widget.currencySymbol,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF6B7280),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _formatBudget(widget.totalBudget),
                                  style: const TextStyle(
                                    fontSize: 22,
                                    color: Color(0xFF111827),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    _BudgetSplitSliderRow(
                      label: widget.flightLabel,
                      percent: _flightPercent,
                      amountText: _formatBudget(allocation.flightBudget),
                      accentColor: const Color(0xFF2550D8),
                      onChanged: (value) => _rebalanceBudget(
                        target: _BudgetCategory.flight,
                        rawValue: value,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _BudgetSplitSliderRow(
                      label: widget.hotelLabel,
                      percent: _hotelPercent,
                      amountText: _formatBudget(allocation.hotelBudget),
                      accentColor: const Color(0xFF4A78FF),
                      onChanged: (value) => _rebalanceBudget(
                        target: _BudgetCategory.hotel,
                        rawValue: value,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _BudgetSplitSliderRow(
                      label: widget.foodLabel,
                      percent: _foodPercent,
                      amountText: _formatBudget(allocation.foodBudget),
                      accentColor: const Color(0xFF7EA7FF),
                      onChanged: (value) => _rebalanceBudget(
                        target: _BudgetCategory.food,
                        rawValue: value,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _BudgetSplitSliderRow(
                      label: widget.otherLabel,
                      percent: _otherPercent,
                      amountText: _formatBudget(allocation.otherBudget),
                      accentColor: const Color(0xFFA9C2FF),
                      onChanged: (value) => _rebalanceBudget(
                        target: _BudgetCategory.other,
                        rawValue: value,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // 底部操作区固定，保证 Save / Cancel 始终可见。
            DecoratedBox(
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
              ),
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  14,
                  20,
                  16 + safeBottom + bottomInset,
                ),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(52),
                          side: const BorderSide(color: Color(0xFFD1D5DB)),
                          backgroundColor: const Color(0xFFF8FAFC),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: Text(widget.cancelLabel),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop(
                            allocation.toSplit(
                              currencyOverride: widget.currency,
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(52),
                          backgroundColor: const Color(0xFF111827),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: Text(widget.saveLabel),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _rebalanceBudget({
    required _BudgetCategory target,
    required double rawValue,
  }) {
    setState(() {
      // 按新的优先级从“弹性预算池”或“释放池”中顺序挪动比例。
      final values = <_BudgetCategory, int>{
        _BudgetCategory.flight: _flightPercent,
        _BudgetCategory.hotel: _hotelPercent,
        _BudgetCategory.food: _foodPercent,
        _BudgetCategory.other: _otherPercent,
      };
      final oldValue = values[target]!;
      final requestedValue = rawValue.round().clamp(_minPercent, _maxPercent);
      final delta = requestedValue - oldValue;
      if (delta == 0) {
        return;
      }

      if (delta > 0) {
        final priorities = _increasePriorities(target, values);
        var remaining = delta;
        for (final category in priorities) {
          if (remaining <= 0) {
            break;
          }
          final available = values[category]! - _minPercent;
          if (available <= 0) {
            continue;
          }
          final deduction = math.min(remaining, available);
          values[category] = values[category]! - deduction;
          remaining -= deduction;
        }
        final appliedIncrease = delta - remaining;
        values[target] = oldValue + appliedIncrease;
      } else {
        final priorities = _decreasePriorities(target, values);
        final releasable = math.min(oldValue - _minPercent, -delta);
        var remaining = releasable;
        for (final category in priorities) {
          if (remaining <= 0) {
            break;
          }
          final capacity = _maxPercent - values[category]!;
          if (capacity <= 0) {
            continue;
          }
          final addition = math.min(remaining, capacity);
          values[category] = values[category]! + addition;
          remaining -= addition;
        }
        final appliedDecrease = releasable - remaining;
        values[target] = oldValue - appliedDecrease;
      }

      _flightPercent = values[_BudgetCategory.flight]!;
      _hotelPercent = values[_BudgetCategory.hotel]!;
      _foodPercent = values[_BudgetCategory.food]!;
      _otherPercent = values[_BudgetCategory.other]!;
      _normalizeRemainder(preferredCategory: target);
    });
  }

  List<_BudgetCategory> _increasePriorities(
    _BudgetCategory target,
    Map<_BudgetCategory, int> values,
  ) {
    switch (target) {
      case _BudgetCategory.flight:
      case _BudgetCategory.hotel:
        return const <_BudgetCategory>[
          _BudgetCategory.other,
          _BudgetCategory.food,
        ];
      case _BudgetCategory.food:
        return <_BudgetCategory>[
          _BudgetCategory.other,
          if (values[_BudgetCategory.hotel]! >= values[_BudgetCategory.flight]!)
            _BudgetCategory.hotel
          else
            _BudgetCategory.flight,
          if (values[_BudgetCategory.hotel]! >= values[_BudgetCategory.flight]!)
            _BudgetCategory.flight
          else
            _BudgetCategory.hotel,
        ];
      case _BudgetCategory.other:
        return <_BudgetCategory>[
          _BudgetCategory.food,
          if (values[_BudgetCategory.hotel]! >= values[_BudgetCategory.flight]!)
            _BudgetCategory.hotel
          else
            _BudgetCategory.flight,
          if (values[_BudgetCategory.hotel]! >= values[_BudgetCategory.flight]!)
            _BudgetCategory.flight
          else
            _BudgetCategory.hotel,
        ];
    }
  }

  List<_BudgetCategory> _decreasePriorities(
    _BudgetCategory target,
    Map<_BudgetCategory, int> values,
  ) {
    switch (target) {
      case _BudgetCategory.flight:
      case _BudgetCategory.hotel:
        return const <_BudgetCategory>[
          _BudgetCategory.other,
          _BudgetCategory.food,
        ];
      case _BudgetCategory.food:
        return const <_BudgetCategory>[_BudgetCategory.other];
      case _BudgetCategory.other:
        return const <_BudgetCategory>[_BudgetCategory.food];
    }
  }

  void _normalizeRemainder({required _BudgetCategory preferredCategory}) {
    var total = _flightPercent + _hotelPercent + _foodPercent + _otherPercent;
    if (total == 100) {
      return;
    }

    final candidates = <_BudgetCategory>[
      _BudgetCategory.other,
      if (preferredCategory != _BudgetCategory.other) preferredCategory,
      ...<_BudgetCategory>[
        _BudgetCategory.flight,
        _BudgetCategory.hotel,
        _BudgetCategory.food,
      ].where(
        (category) =>
            category != _BudgetCategory.other && category != preferredCategory,
      ),
    ];

    for (final category in candidates) {
      final value = _valueFor(category);
      final adjusted = value + (100 - total);
      if (adjusted >= _minPercent && adjusted <= _maxPercent) {
        _setValueFor(category, adjusted);
        total = _flightPercent + _hotelPercent + _foodPercent + _otherPercent;
        if (total == 100) {
          return;
        }
      }
    }

    final maxCategory =
        <_BudgetCategory>[
          _BudgetCategory.flight,
          _BudgetCategory.hotel,
          _BudgetCategory.food,
          _BudgetCategory.other,
        ].reduce(
          (left, right) => _valueFor(left) >= _valueFor(right) ? left : right,
        );
    final fallbackValue = _valueFor(maxCategory) + (100 - total);
    if (fallbackValue >= _minPercent && fallbackValue <= _maxPercent) {
      _setValueFor(maxCategory, fallbackValue);
    }
  }

  int _valueFor(_BudgetCategory category) {
    return switch (category) {
      _BudgetCategory.flight => _flightPercent,
      _BudgetCategory.hotel => _hotelPercent,
      _BudgetCategory.food => _foodPercent,
      _BudgetCategory.other => _otherPercent,
    };
  }

  void _setValueFor(_BudgetCategory category, int value) {
    switch (category) {
      case _BudgetCategory.flight:
        _flightPercent = value;
        break;
      case _BudgetCategory.hotel:
        _hotelPercent = value;
        break;
      case _BudgetCategory.food:
        _foodPercent = value;
        break;
      case _BudgetCategory.other:
        _otherPercent = value;
        break;
    }
  }

  ChecklistBudgetAllocation _buildAllocation() {
    final safeBudget = widget.totalBudget != null && widget.totalBudget! > 0
        ? widget.totalBudget
        : null;
    return ChecklistBudgetAllocation(
      flightPercent: _flightPercent.toDouble(),
      hotelPercent: _hotelPercent.toDouble(),
      foodPercent: _foodPercent.toDouble(),
      otherPercent: _otherPercent.toDouble(),
      flightBudget: _computeBudget(safeBudget, _flightPercent),
      hotelBudget: _computeBudget(safeBudget, _hotelPercent),
      foodBudget: _computeBudget(safeBudget, _foodPercent),
      otherBudget: _computeBudget(safeBudget, _otherPercent),
      currency: widget.currency,
    );
  }

  double? _computeBudget(double? totalBudget, int percent) {
    if (totalBudget == null) {
      return null;
    }
    return totalBudget * percent / 100;
  }

  String _formatBudget(double? value) {
    if (value == null) {
      return widget.notSetLabel;
    }
    final formatter = NumberFormat.decimalPattern(
      Localizations.localeOf(context).toLanguageTag(),
    );
    final prefix = widget.currencySymbol.isNotEmpty
        ? widget.currencySymbol
        : widget.currency;
    return '$prefix${formatter.format(value.round())}';
  }
}

class _BudgetSplitSliderRow extends StatelessWidget {
  const _BudgetSplitSliderRow({
    required this.label,
    required this.percent,
    required this.amountText,
    required this.accentColor,
    required this.onChanged,
  });

  final String label;
  final int percent;
  final String amountText;
  final Color accentColor;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x0A0F172A),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF111827),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF3FF),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '$percent%',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: accentColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              amountText,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 6),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 4,
                activeTrackColor: accentColor,
                inactiveTrackColor: const Color(0xFFDCE7FF),
                thumbColor: accentColor,
                overlayColor: accentColor.withValues(alpha: 0.12),
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
              ),
              child: Slider(
                value: percent.toDouble(),
                min: 5,
                max: 85,
                divisions: 80,
                onChanged: onChanged,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BudgetDonutCard extends StatelessWidget {
  const _BudgetDonutCard({
    required this.currencyLabel,
    required this.totalBudgetText,
    required this.legendItems,
    required this.child,
  });

  final String currencyLabel;
  final String totalBudgetText;
  final List<_BudgetLegendItem> legendItems;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x0A0F172A),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
        child: Column(
          children: <Widget>[
            child,
            const SizedBox(height: 18),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 10,
              runSpacing: 10,
              children: legendItems
                  .map((item) => _BudgetLegendChip(item: item))
                  .toList(growable: false),
            ),
          ],
        ),
      ),
    );
  }
}

class _BudgetLegendChip extends StatelessWidget {
  const _BudgetLegendChip({required this.item});

  final _BudgetLegendItem item;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: item.color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              item.label,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF4B5563),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BudgetDonutPainter extends CustomPainter {
  const _BudgetDonutPainter({
    required this.flightPercent,
    required this.hotelPercent,
    required this.foodPercent,
    required this.otherPercent,
  });

  final int flightPercent;
  final int hotelPercent;
  final int foodPercent;
  final int otherPercent;

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = 20.0;
    final rect = Offset.zero & size;
    final arcRect = Rect.fromCircle(
      center: rect.center,
      radius: math.min(size.width, size.height) / 2 - strokeWidth / 2,
    );
    const startAngle = -math.pi / 2;
    final segments = <({int percent, Color color})>[
      (percent: flightPercent, color: const Color(0xFF2F62EC)),
      (percent: hotelPercent, color: const Color(0xFF5B8EFF)),
      (percent: foodPercent, color: const Color(0xFF8CB3FF)),
      (percent: otherPercent, color: const Color(0xFFC7D8FF)),
    ];

    var currentAngle = startAngle;
    for (final segment in segments) {
      final sweep = 2 * math.pi * (segment.percent / 100);
      final paint = Paint()
        ..color = segment.color
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = strokeWidth;
      canvas.drawArc(arcRect, currentAngle, sweep, false, paint);
      currentAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _BudgetDonutPainter oldDelegate) {
    return flightPercent != oldDelegate.flightPercent ||
        hotelPercent != oldDelegate.hotelPercent ||
        foodPercent != oldDelegate.foodPercent ||
        otherPercent != oldDelegate.otherPercent;
  }
}

class _BudgetLegendItem {
  const _BudgetLegendItem({required this.label, required this.color});

  final String label;
  final Color color;
}

enum _BudgetCategory { flight, hotel, food, other }
