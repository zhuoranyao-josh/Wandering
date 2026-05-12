import 'package:flutter/material.dart';

class ExperienceCard extends StatelessWidget {
  const ExperienceCard({
    super.key,
    this.badge,
    this.featureName,
    this.title,
    this.description,
    this.onTap,
  });

  final String? badge;
  final String? featureName;
  final String? title;
  final String? description;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final badgeText = badge?.trim() ?? '';
    final featureNameText = featureName?.trim() ?? '';
    final titleText = title?.trim() ?? '';
    final descriptionText = description?.trim() ?? '';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          width: 182,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              if (badgeText.isNotEmpty)
                _ExperienceBadge(text: badgeText)
              else
                Container(
                  width: 68,
                  height: 20,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD1D5DB),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              const SizedBox(height: 8),
              Expanded(
                child: featureNameText.isNotEmpty
                    ? Text(
                        featureNameText,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 17,
                          height: 1.08,
                          color: Color(0xFF111827),
                          fontWeight: FontWeight.w800,
                        ),
                      )
                    : const _FeatureNamePlaceholder(),
              ),
              if (titleText.isNotEmpty)
                Text(
                  titleText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13.5,
                    height: 1.25,
                    color: Color(0xFF111827),
                    fontWeight: FontWeight.w700,
                  ),
                )
              else
                const _TitlePlaceholder(),
              if (descriptionText.isNotEmpty) ...<Widget>[
                const SizedBox(height: 3),
                Text(
                  descriptionText,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11.5,
                    height: 1.22,
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ExperienceBadge extends StatelessWidget {
  const _ExperienceBadge({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: const Color(0xFF2563EB),
              shape: BoxShape.circle,
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.34),
                  blurRadius: 7,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Text(
            text.toUpperCase(),
            style: const TextStyle(
              fontSize: 10,
              letterSpacing: 0.8,
              fontWeight: FontWeight.w800,
              color: Color(0xFF334155),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureNamePlaceholder extends StatelessWidget {
  const _FeatureNamePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: 136,
          height: 16,
          decoration: BoxDecoration(
            color: const Color(0xFFD1D5DB),
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 104,
          height: 16,
          decoration: BoxDecoration(
            color: const Color(0xFFD1D5DB),
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ],
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
          width: 112,
          height: 12,
          decoration: BoxDecoration(
            color: const Color(0xFFD1D5DB),
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ],
    );
  }
}
