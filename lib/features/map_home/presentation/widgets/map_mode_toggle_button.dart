import 'package:flutter/material.dart';

import 'map_icon_action_button.dart';

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
    return MapIconActionButton(
      tooltip: tooltip,
      enabled: enabled,
      onPressed: onPressed,
      icon: isNightMode ? Icons.wb_sunny_outlined : Icons.nights_stay_outlined,
    );
  }
}
