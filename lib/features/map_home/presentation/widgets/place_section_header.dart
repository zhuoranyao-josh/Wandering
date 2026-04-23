import 'package:flutter/material.dart';

class PlaceSectionHeader extends StatelessWidget {
  const PlaceSectionHeader({
    super.key,
    required this.title,
    this.actionText,
    this.onActionTap,
  });

  final String title;
  final String? actionText;
  final VoidCallback? onActionTap;

  @override
  Widget build(BuildContext context) {
    final normalizedTitle = title.trim();
    final normalizedAction = actionText?.trim() ?? '';

    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            normalizedTitle.toUpperCase(),
            style: const TextStyle(
              fontSize: 12,
              letterSpacing: 1.1,
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        if (normalizedAction.isNotEmpty)
          TextButton(
            onPressed: onActionTap,
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF111827),
              visualDensity: VisualDensity.compact,
              textStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            child: Text(normalizedAction),
          ),
      ],
    );
  }
}
