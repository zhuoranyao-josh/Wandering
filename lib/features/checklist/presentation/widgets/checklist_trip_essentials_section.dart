import 'package:flutter/material.dart';

import '../../domain/entities/checklist_detail.dart';

class ChecklistTripEssentialsSection extends StatelessWidget {
  const ChecklistTripEssentialsSection({
    super.key,
    required this.title,
    required this.essentials,
  });

  final String title;
  final List<ChecklistEssential> essentials;

  @override
  Widget build(BuildContext context) {
    final displayItems = essentials.take(4).toList(growable: false);
    if (displayItems.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            fontSize: 13.5,
            letterSpacing: 1.8,
            color: Color(0xFF9CA3AF),
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: displayItems.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            // 固定卡片高度，避免摘要文案稍长时把内容挤坏。
            mainAxisExtent: 140,
          ),
          itemBuilder: (context, index) {
            return _EssentialCard(item: displayItems[index]);
          },
        ),
      ],
    );
  }
}

class _EssentialCard extends StatelessWidget {
  const _EssentialCard({required this.item});

  final ChecklistEssential item;

  @override
  Widget build(BuildContext context) {
    final mainText = item.mainText.trim();
    final subText = item.subText?.trim() ?? '';

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE9EDF5)),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x0A111827),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              item.title.trim().toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12.5,
                color: Color(0xFF2563EB),
                fontWeight: FontWeight.w700,
                letterSpacing: 0.7,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              mainText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF111827),
                fontWeight: FontWeight.w600,
              ),
            ),
            if (subText.isNotEmpty) ...<Widget>[
              const SizedBox(height: 4),
              Text(
                subText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF6B7280),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
