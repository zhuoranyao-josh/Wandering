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
    final hotelItems = _extractHotelItems(items);
    final timelineItems = _sortByTimeline(_excludeHotelItems(items));
    final daySections = _buildDaySections(
      timelineItems: timelineItems,
      hotelItems: hotelItems,
    );

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
        if (daySections.isEmpty)
          _buildEmptyState()
        else
          _buildTimelineList(
            context,
            daySections: daySections,
            hotelItems: hotelItems,
          ),
      ],
    );
  }

  Widget _buildTimelineList(
    BuildContext context, {
    required List<_DaySectionData> daySections,
    required List<ChecklistDetailItem> hotelItems,
  }) {
    final localeTag = Localizations.localeOf(context).toLanguageTag();
    final dayFormatter = DateFormat('MM-dd', localeTag);
    final yearFormatter = DateFormat('yyyy', localeTag);

    return Column(
      children: List<Widget>.generate(daySections.length, (index) {
        final daySection = daySections[index];
        final resolvedDate = _resolveTimelineDate(daySection.dayKey);

        final dateText = resolvedDate == null
            ? daySection.dayKey.toString().padLeft(2, '0')
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
                  child: Padding(
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
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      ...List<Widget>.generate(daySection.items.length, (
                        itemIndex,
                      ) {
                        final item = daySection.items[itemIndex];
                        return Padding(
                          padding: EdgeInsets.only(
                            bottom: itemIndex == daySection.items.length - 1
                                ? 0
                                : 12,
                          ),
                          child: ChecklistItemTile(
                            item: item,
                            onToggleCompleted: (_) =>
                                onToggleCompleted(item.id),
                            onTap: () => onItemTap?.call(item),
                          ),
                        );
                      }),
                      if (hotelItems.isNotEmpty) ...<Widget>[
                        if (daySection.items.isNotEmpty)
                          const SizedBox(height: 12),
                        _HotelOptionsCarousel(
                          items: hotelItems,
                          onToggleCompleted: onToggleCompleted,
                          onItemTap: onItemTap,
                        ),
                      ],
                    ],
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

  List<ChecklistDetailItem> _extractHotelItems(
    List<ChecklistDetailItem> source,
  ) {
    return source.where(_isHotelItem).toList(growable: false);
  }

  List<ChecklistDetailItem> _excludeHotelItems(
    List<ChecklistDetailItem> source,
  ) {
    return source.where((item) => !_isHotelItem(item)).toList(growable: false);
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

  List<_DaySectionData> _buildDaySections({
    required List<ChecklistDetailItem> timelineItems,
    required List<ChecklistDetailItem> hotelItems,
  }) {
    if (timelineItems.isEmpty) {
      // 仅有酒店候选时，仍然渲染一个 Day 区块承载横滑酒店模块。
      if (hotelItems.isEmpty) {
        return const <_DaySectionData>[];
      }
      return const <_DaySectionData>[
        _DaySectionData(dayKey: 1, items: <ChecklistDetailItem>[]),
      ];
    }

    final grouped = <int, List<ChecklistDetailItem>>{};
    for (final item in timelineItems) {
      final dayKey = _resolveTimelineDay(item);
      grouped.putIfAbsent(dayKey, () => <ChecklistDetailItem>[]).add(item);
    }
    return grouped.entries
        .map((entry) => _DaySectionData(dayKey: entry.key, items: entry.value))
        .toList(growable: false);
  }

  bool _isHotelItem(ChecklistDetailItem item) {
    final type = (item.type ?? '').trim().toLowerCase();
    final groupType = item.groupType.trim().toLowerCase();
    return type == 'hotel' || groupType == 'stay';
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

class _DaySectionData {
  const _DaySectionData({required this.dayKey, required this.items});

  final int dayKey;
  final List<ChecklistDetailItem> items;
}

class _HotelOptionsCarousel extends StatefulWidget {
  const _HotelOptionsCarousel({
    required this.items,
    required this.onToggleCompleted,
    required this.onItemTap,
  });

  final List<ChecklistDetailItem> items;
  final ValueChanged<String> onToggleCompleted;
  final ValueChanged<ChecklistDetailItem>? onItemTap;

  @override
  State<_HotelOptionsCarousel> createState() => _HotelOptionsCarouselState();
}

class _HotelOptionsCarouselState extends State<_HotelOptionsCarousel> {
  late final PageController _pageController = PageController(
    viewportFraction: 1.0,
  );

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 固定高度 + PageView 分页吸附，确保每次只切换一张且不露出下一张。
    return SizedBox(
      height: 176,
      child: PageView.builder(
        controller: _pageController,
        pageSnapping: true,
        physics: const PageScrollPhysics(),
        itemCount: widget.items.length,
        itemBuilder: (context, index) {
          final hotel = widget.items[index];
          return Align(
            alignment: Alignment.topCenter,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                ChecklistItemTile(
                  item: hotel,
                  onToggleCompleted: (_) => widget.onToggleCompleted(hotel.id),
                  onTap: () => widget.onItemTap?.call(hotel),
                ),
                // 页码跟随当前卡片内容位置，始终和卡片底部保持固定距离。
                const SizedBox(height: 6),
                IgnorePointer(
                  child: Text(
                    '${index + 1}/${widget.items.length}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: Color(0xFF9CA3AF),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
