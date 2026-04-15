import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../l10n/app_localizations.dart';

class ActivityDateFormatter {
  static String formatEventDateRange({
    required DateTime? startAt,
    required DateTime? endAt,
    required String localeTag,
    required AppLocalizations t,
  }) {
    final startText = startAt != null
        ? formatDateTime(dateTime: startAt, localeTag: localeTag)
        : null;
    final endText = endAt != null
        ? formatDateTime(dateTime: endAt, localeTag: localeTag)
        : null;

    // 一直营业型活动：开始和结束时间都为空。
    if (startAt == null && endAt == null) {
      return t.activityAlwaysOpen;
    }

    // 有开始时间、没有结束时间：从某日开始长期开放。
    if (startAt != null && endAt == null) {
      return t.activityLongTermOpenFrom(startText!);
    }

    // 没有开始时间、只有结束时间：兼容异常但可展示的数据。
    if (startAt == null && endAt != null) {
      return t.activityOpenUntil(endText!);
    }

    final timeFormatter = DateFormat('HH:mm', localeTag);
    final sameDay =
        startAt!.year == endAt!.year &&
        startAt.month == endAt.month &&
        startAt.day == endAt.day;

    if (sameDay) {
      return '$startText - ${timeFormatter.format(endAt)}';
    }

    return '$startText - $endText';
  }

  static String formatDateTime({
    required DateTime dateTime,
    required String localeTag,
  }) {
    final dateFormatter = DateFormat('y.MM.dd', localeTag);
    final timeFormatter = DateFormat('HH:mm', localeTag);
    return '${dateFormatter.format(dateTime)} ${timeFormatter.format(dateTime)}';
  }

  static String formatDateFilter({
    required DateTimeRange dateRange,
    required String localeTag,
  }) {
    final formatter = DateFormat('y.MM.dd', localeTag);
    final startText = formatter.format(dateRange.start);
    final endText = formatter.format(dateRange.end);

    if (_isSameDay(dateRange.start, dateRange.end)) {
      return startText;
    }
    return '$startText - $endText';
  }

  static bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
