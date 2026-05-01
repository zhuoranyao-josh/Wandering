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
            // 适度增加高度，优先给文本换行空间，减少过早省略。
            mainAxisExtent: 150,
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
    final isWeatherCard = _isWeatherCard(item);

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
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: isWeatherCard ? 12.5 : 12.5,
                color: const Color(0xFF2563EB),
                fontWeight: FontWeight.w700,
                letterSpacing: isWeatherCard ? 0.7 : 0.7,
                height: isWeatherCard ? 1.3 : 1.2,
              ),
            ),
            SizedBox(height: isWeatherCard ? 5 : 6),
            Text(
              mainText,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: isWeatherCard ? 16 : 13.5,
                color: const Color(0xFF111827),
                fontWeight: FontWeight.w600,
                height: isWeatherCard ? 1.25 : 1.2,
              ),
            ),
            if (subText.isNotEmpty) ...<Widget>[
              SizedBox(height: isWeatherCard ? 1 : 6),
              Text(
                subText,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: isWeatherCard ? 14 : 12.5,
                  color: const Color(0xFF6B7280),
                  fontWeight: FontWeight.w500,
                  height: isWeatherCard ? 1.4 : 1.2,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  bool _isWeatherCard(ChecklistEssential source) {
    final normalizedTitle = source.title.trim().toLowerCase().replaceAll(
      ' ',
      '',
    );
    final normalizedIconType = source.iconType.trim().toLowerCase().replaceAll(
      ' ',
      '',
    );
    return normalizedTitle == 'weather' ||
        normalizedIconType == 'weather' ||
        normalizedIconType == 'rain' ||
        normalizedIconType == 'snow' ||
        normalizedIconType == 'clear' ||
        normalizedIconType == 'cloud_off';
  }
}
