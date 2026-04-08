import 'package:flutter/material.dart';

class MapModeToggleButton extends StatelessWidget {
  const MapModeToggleButton({
    super.key,
    required this.isNightMode,
    required this.tooltip,
    required this.onPressed,
    this.enabled = true,
  });

  final bool isNightMode;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final Color iconColor = enabled
        ? const Color(0xFF111827)
        : const Color(0xFF9CA3AF);

    return Material(
      color: Colors.white.withValues(alpha: 0.94),
      borderRadius: BorderRadius.circular(18),
      elevation: 6,
      shadowColor: const Color(0x33000000),
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: enabled ? onPressed : null,
          child: SizedBox(
            width: 52,
            height: 52,
            child: Icon(
              isNightMode
                  ? Icons.wb_sunny_outlined
                  : Icons.nights_stay_outlined,
              color: iconColor,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }
}
