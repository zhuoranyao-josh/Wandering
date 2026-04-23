import 'package:flutter/material.dart';

class ExperienceCard extends StatelessWidget {
  const ExperienceCard({super.key, this.badge, this.title, this.onTap});

  final String? badge;
  final String? title;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final badgeText = badge?.trim() ?? '';
    final titleText = title?.trim() ?? '';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          width: 182,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              if (badgeText.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    badgeText,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF4B5563),
                    ),
                  ),
                )
              else
                Container(
                  width: 68,
                  height: 20,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD1D5DB),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              const Spacer(),
              if (titleText.isNotEmpty)
                Text(
                  titleText,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.3,
                    color: Color(0xFF111827),
                    fontWeight: FontWeight.w700,
                  ),
                )
              else
                const _TitlePlaceholder(),
            ],
          ),
        ),
      ),
    );
  }
}

class _TitlePlaceholder extends StatelessWidget {
  const _TitlePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: 132,
          height: 14,
          decoration: BoxDecoration(
            color: const Color(0xFFD1D5DB),
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 94,
          height: 14,
          decoration: BoxDecoration(
            color: const Color(0xFFD1D5DB),
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ],
    );
  }
}
