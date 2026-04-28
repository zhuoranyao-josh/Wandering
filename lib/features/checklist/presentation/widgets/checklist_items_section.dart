import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/checklist_detail.dart';
import 'checklist_item_tile.dart';

class ChecklistItemsSection extends StatelessWidget {
  const ChecklistItemsSection({
    super.key,
    required this.sectionTitle,
    required this.noItemsTitle,
    required this.noItemsHint,
    required this.items,
    required this.onToggleCompleted,
    this.startDate,
    this.onItemTap,
  });

  final String sectionTitle;
  final String noItemsTitle;
  final String noItemsHint;
  final List<ChecklistDetailItem> items;
  final ValueChanged<String> onToggleCompleted;
  final DateTime? startDate;
  final ValueChanged<ChecklistDetailItem>? onItemTap;

  @override
  Widget build(BuildContext context) {
    final timelineItems = _sortByTimeline(items);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          sectionTitle.toUpperCase(),
          style: const TextStyle(
            fontSize: 13,
            letterSpacing: 1.6,
            color: Color(0xFF9CA3AF),
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        if (timelineItems.isEmpty)
          _buildEmptyState()
        else
          _buildTimelineList(context, timelineItems),
      ],
    );
  }

  Widget _buildTimelineList(
    BuildContext context,
    List<ChecklistDetailItem> source,
  ) {
    final localeTag = Localizations.localeOf(context).toLanguageTag();
    final dayFormatter = DateFormat('MM-dd', localeTag);
    final yearFormatter = DateFormat('yyyy', localeTag);

    return Column(
      children: List<Widget>.generate(source.length, (index) {
        final item = source[index];
        final dayKey = _resolveTimelineDay(item);
        final previousDayKey = index == 0
            ? -1
            : _resolveTimelineDay(source[index - 1]);
        final showDate = index == 0 || dayKey != previousDayKey;
        final resolvedDate = _resolveTimelineDate(dayKey);

        final dateText = resolvedDate == null
            ? dayKey.toString().padLeft(2, '0')
            : dayFormatter.format(resolvedDate);
        final yearText = resolvedDate == null
            ? ''
            : yearFormatter.format(resolvedDate);

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Transform.translate(
            // 轻微左移时间轴，同时让右侧卡片获得更多横向空间。
            offset: const Offset(-4, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                SizedBox(
                  width: 50,
                  child: showDate
                      ? Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: <Widget>[
                              Text(
                                dateText,
                                style: const TextStyle(
                                  fontSize: 14,
                                  height: 1,
                                  color: Color(0xFF2A2F38),
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              if (yearText.isNotEmpty) ...<Widget>[
                                const SizedBox(height: 4),
                                Text(
                                  yearText,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    height: 1,
                                    color: Color(0xFFA1A1AA),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: ChecklistItemTile(
                    item: item,
                    onToggleCompleted: (_) => onToggleCompleted(item.id),
                    onTap: () => onItemTap?.call(item),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FA),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            noItemsTitle,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF111827),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            noItemsHint,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  List<ChecklistDetailItem> _sortByTimeline(List<ChecklistDetailItem> source) {
    final sorted = source.toList(growable: false);
    sorted.sort((left, right) {
      final leftDay = _resolveTimelineDay(left);
      final rightDay = _resolveTimelineDay(right);
      if (leftDay != rightDay) {
        return leftDay.compareTo(rightDay);
      }

      final leftOrder = left.displayOrder ?? 0;
      final rightOrder = right.displayOrder ?? 0;
      if (leftOrder != rightOrder) {
        return leftOrder.compareTo(rightOrder);
      }
      return left.id.compareTo(right.id);
    });
    return sorted;
  }

  int _resolveTimelineDay(ChecklistDetailItem item) {
    final dayIndex = item.dayIndex;
    if (dayIndex != null && dayIndex > 0) {
      return dayIndex;
    }

    // 按展示顺序推断天数，保证没有 dayIndex 的条目也能进入时间轴。
    final order = item.displayOrder ?? 0;
    if (order <= 20) return 1;
    if (order <= 40) return 2;
    if (order <= 60) return 3;
    if (order <= 80) return 4;
    return 5;
  }

  DateTime? _resolveTimelineDate(int dayKey) {
    if (startDate == null) {
      return null;
    }
    final safeDay = dayKey <= 0 ? 1 : dayKey;
    return DateTime(
      startDate!.year,
      startDate!.month,
      startDate!.day + safeDay - 1,
    );
  }
}
