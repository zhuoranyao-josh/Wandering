import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/entities/checklist_detail.dart';

class ChecklistBudgetSplitCard extends StatelessWidget {
  const ChecklistBudgetSplitCard({
    super.key,
    required this.title,
    required this.transportLabel,
    required this.stayLabel,
    required this.foodActivitiesLabel,
    required this.adjustLabel,
    required this.notSetLabel,
    this.budgetSplit,
    this.onAdjustTap,
  });

  final String title;
  final String transportLabel;
  final String stayLabel;
  final String foodActivitiesLabel;
  final String adjustLabel;
  final String notSetLabel;
  final ChecklistBudgetSplit? budgetSplit;
  final VoidCallback? onAdjustTap;

  @override
  Widget build(BuildContext context) {
    final ratios = _NormalizedRatios.fromSplit(budgetSplit);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: Row(
                children: <Widget>[
                  SizedBox(
                    width: 86,
                    height: 86,
                    child: ratios.hasData
                        ? CustomPaint(painter: _SplitPiePainter(ratios: ratios))
                        : Center(
                            child: Text(
                              notSetLabel,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF9CA3AF),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ratios.hasData
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              _SplitInlineText(
                                label: stayLabel,
                                value: '${ratios.stay.round()}%',
                              ),
                              const SizedBox(height: 4),
                              _SplitInlineText(
                                label: transportLabel,
                                value: '${ratios.transport.round()}%',
                              ),
                              const SizedBox(height: 4),
                              _SplitInlineText(
                                label: foodActivitiesLabel,
                                value: '${ratios.foodActivities.round()}%',
                              ),
                            ],
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    title.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF111827),
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: onAdjustTap,
                  style: TextButton.styleFrom(
                    minimumSize: const Size(0, 34),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                      side: const BorderSide(color: Color(0xFFD1D5DB)),
                    ),
                  ),
                  child: Text(
                    adjustLabel,
                    style: const TextStyle(
                      fontSize: 13,
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
            '$label:',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF111827),
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _SplitPiePainter extends CustomPainter {
  const _SplitPiePainter({required this.ratios});

  static const Color transportColor = Color(0xFF5A8BEA);
  static const Color stayColor = Color(0xFF4672DD);
  static const Color foodActivitiesColor = Color(0xFF98BDF2);

  final _NormalizedRatios ratios;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    final outerRect = Rect.fromCircle(center: center, radius: radius);
    final paint = Paint()..style = PaintingStyle.fill;

    final sweepAngles = <double>[
      ratios.transport / 100 * 2 * math.pi,
      ratios.stay / 100 * 2 * math.pi,
      ratios.foodActivities / 100 * 2 * math.pi,
    ];
    final colors = <Color>[transportColor, stayColor, foodActivitiesColor];

    var startAngle = -math.pi / 2;
    for (var i = 0; i < sweepAngles.length; i++) {
      paint.color = colors[i];
      canvas.drawArc(outerRect, startAngle, sweepAngles[i], true, paint);
      startAngle += sweepAngles[i];
    }

    final holePaint = Paint()..color = const Color(0xFFF7F8FC);
    canvas.drawCircle(center, radius * 0.46, holePaint);
  }

  @override
  bool shouldRepaint(covariant _SplitPiePainter oldDelegate) {
    return oldDelegate.ratios != ratios;
  }
}

class _NormalizedRatios {
  const _NormalizedRatios({
    required this.transport,
    required this.stay,
    required this.foodActivities,
    required this.hasData,
  });

  final double transport;
  final double stay;
  final double foodActivities;
  final bool hasData;

  factory _NormalizedRatios.fromSplit(ChecklistBudgetSplit? split) {
    if (split == null || !split.hasAnyValue) {
      return const _NormalizedRatios(
        transport: 0,
        stay: 0,
        foodActivities: 0,
        hasData: false,
      );
    }

    final rawTransport = split.transportRatio ?? 0;
    final rawStay = split.stayRatio ?? 0;
    final rawFoodActivities = split.foodActivityRatio ?? 0;
    final rawSum = rawTransport + rawStay + rawFoodActivities;
    if (rawSum <= 0) {
      return const _NormalizedRatios(
        transport: 0,
        stay: 0,
        foodActivities: 0,
        hasData: false,
      );
    }

    // 鍏煎 0~1 鍜?0~100 涓ょ杈撳叆锛岀粺涓€鏄犲皠涓虹櫨鍒嗘瘮灞曠ず銆?
    final useFraction = rawSum <= 1.2;
    final factor = useFraction ? 100.0 : 1.0;
    final sum = (rawTransport + rawStay + rawFoodActivities) * factor;
    if (sum <= 0) {
      return const _NormalizedRatios(
        transport: 0,
        stay: 0,
        foodActivities: 0,
        hasData: false,
      );
    }

    return _NormalizedRatios(
      transport: rawTransport * factor / sum * 100,
      stay: rawStay * factor / sum * 100,
      foodActivities: rawFoodActivities * factor / sum * 100,
      hasData: true,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is _NormalizedRatios &&
        other.transport == transport &&
        other.stay == stay &&
        other.foodActivities == foodActivities &&
        other.hasData == hasData;
  }

  @override
  int get hashCode => Object.hash(transport, stay, foodActivities, hasData);
}
