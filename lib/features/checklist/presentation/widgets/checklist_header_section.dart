import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../l10n/app_localizations.dart';

class ChecklistHeaderSection extends StatelessWidget {
  const ChecklistHeaderSection({
    super.key,
    required this.destination,
    this.startDate,
    this.endDate,
    this.tripDays,
    this.travelerCount,
  });

  final String destination;
  final DateTime? startDate;
  final DateTime? endDate;
  final int? tripDays;
  final int? travelerCount;

  @override
  Widget build(BuildContext context) {
    final metaText = _buildMetaText(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          destination.trim().isEmpty ? '-' : destination.trim(),
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: const Color(0xFF111827),
          ),
        ),
        if (metaText != null) ...<Widget>[
          const SizedBox(height: 8),
          Text(
            metaText,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Color(0xFF6B7280),
            ),
          ),
        ],
      ],
    );
  }

  String? _buildMetaText(BuildContext context) {
    final t = AppLocalizations.of(context);
    final dateText = _buildDateRange(context);
    final resolvedTripDays = _resolveTripDays();
    final details = <String>[];

    if (resolvedTripDays != null && resolvedTripDays > 0) {
      details.add(
        t?.checklistTripDaysValue(resolvedTripDays) ?? '$resolvedTripDays days',
      );
    }

    if (travelerCount != null && travelerCount! > 0) {
      details.add(
        t?.checklistTravelerCountValue(travelerCount!) ??
            '${travelerCount!} travelers',
      );
    }

    if (dateText == null && details.isEmpty) {
      return null;
    }
    if (dateText == null) {
      return details.join(' | ');
    }
    if (details.isEmpty) {
      return dateText;
    }
    return '$dateText  ${details.join(' | ')}';
  }

  String? _buildDateRange(BuildContext context) {
    // 日期仅在起止时间都存在时展示，避免出现半截文案。
    if (startDate == null || endDate == null) {
      return null;
    }
    final localeName = Localizations.localeOf(context).toLanguageTag();
    final formatter = DateFormat.MMMd(localeName);
    return '${formatter.format(startDate!)} - ${formatter.format(endDate!)}';
  }

  int? _resolveTripDays() {
    if (tripDays != null && tripDays! > 0) {
      return tripDays;
    }
    if (startDate == null || endDate == null) {
      return null;
    }
    if (endDate!.isBefore(startDate!)) {
      return null;
    }
    return endDate!.difference(startDate!).inDays + 1;
  }
}
