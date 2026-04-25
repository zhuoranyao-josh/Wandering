import 'package:flutter/material.dart';

import '../../domain/entities/checklist_detail.dart';
import 'checklist_item_tile.dart';

class ChecklistItemsSection extends StatelessWidget {
  const ChecklistItemsSection({
    super.key,
    required this.sectionTitle,
    required this.noItemsTitle,
    required this.noItemsHint,
    required this.transportationLabel,
    required this.stayLabel,
    required this.foodActivitiesLabel,
    required this.items,
    required this.onToggleCompleted,
    this.onItemTap,
  });

  final String sectionTitle;
  final String noItemsTitle;
  final String noItemsHint;
  final String transportationLabel;
  final String stayLabel;
  final String foodActivitiesLabel;
  final List<ChecklistDetailItem> items;
  final ValueChanged<String> onToggleCompleted;
  final ValueChanged<ChecklistDetailItem>? onItemTap;

  @override
  Widget build(BuildContext context) {
    final groupedItems = _groupItemsByType(items);
    final visibleGroups = groupedItems.entries
        .where((entry) => entry.value.isNotEmpty)
        .toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          sectionTitle.toUpperCase(),
          style: const TextStyle(
            fontSize: 15,
            letterSpacing: 1.8,
            color: Color(0xFF9CA3AF),
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        if (visibleGroups.isEmpty)
          _buildEmptyState()
        else
          _buildGroups(visibleGroups),
      ],
    );
  }

  Widget _buildGroups(
    List<MapEntry<String, List<ChecklistDetailItem>>> groups,
  ) {
    return Column(
      children: groups
          .map(
            (group) => Padding(
              padding: const EdgeInsets.only(bottom: 22),
              child: _ChecklistGroupBlock(
                title: group.key,
                items: group.value,
                onToggleCompleted: onToggleCompleted,
                onItemTap: onItemTap,
              ),
            ),
          )
          .toList(growable: false),
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

  Map<String, List<ChecklistDetailItem>> _groupItemsByType(
    List<ChecklistDetailItem> source,
  ) {
    final groups = <String, List<ChecklistDetailItem>>{
      transportationLabel: <ChecklistDetailItem>[],
      stayLabel: <ChecklistDetailItem>[],
      foodActivitiesLabel: <ChecklistDetailItem>[],
    };

    for (final item in source) {
      final normalized = item.groupType.trim().toLowerCase();
      if (normalized.contains('transport')) {
        groups[transportationLabel]!.add(item);
        continue;
      }
      if (normalized == 'stay' ||
          normalized.contains('hotel') ||
          normalized.contains('accommodation')) {
        groups[stayLabel]!.add(item);
        continue;
      }
      if (normalized.contains('food') || normalized.contains('activity')) {
        groups[foodActivitiesLabel]!.add(item);
        continue;
      }

      // 未识别分组先并入 Food & Activities，避免条目丢失。
      groups[foodActivitiesLabel]!.add(item);
    }

    return groups;
  }
}

class _ChecklistGroupBlock extends StatelessWidget {
  const _ChecklistGroupBlock({
    required this.title,
    required this.items,
    required this.onToggleCompleted,
    this.onItemTap,
  });

  final String title;
  final List<ChecklistDetailItem> items;
  final ValueChanged<String> onToggleCompleted;
  final ValueChanged<ChecklistDetailItem>? onItemTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            fontSize: 15.5,
            color: Color(0xFF9CA3AF),
            letterSpacing: 0.9,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Column(
          children: items
              .map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ChecklistItemTile(
                    item: item,
                    onToggleCompleted: (_) => onToggleCompleted(item.id),
                    onTap: () => onItemTap?.call(item),
                  ),
                ),
              )
              .toList(growable: false),
        ),
      ],
    );
  }
}
