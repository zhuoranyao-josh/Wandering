import 'package:flutter/material.dart';

class MapIconActionButton extends StatelessWidget {
  const MapIconActionButton({
    super.key,
    required this.tooltip,
    required this.onPressed,
    this.icon,
    this.child,
    this.enabled = true,
  }) : assert(icon != null || child != null);

  final String tooltip;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Widget? child;
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
            child: Center(
              child: child ?? Icon(icon, color: iconColor, size: 24),
            ),
          ),
        ),
      ),
    );
  }
}
