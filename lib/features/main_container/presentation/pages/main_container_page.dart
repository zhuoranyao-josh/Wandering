import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MainContainerPage extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  // 底部导航栏整体高度。
  final double navBarHeight;

  // 底部导航栏左右内边距。
  final double navBarHorizontalPadding;

  // 普通导航按钮可点击范围（命中区域）大小。
  final double itemTapTargetSize;

  // 中间按钮可点击范围（命中区域）大小。
  final double centerTapTargetSize;

  // 普通导航按钮图标视觉大小。
  final double iconVisualSize;

  // 中间按钮图标视觉大小。
  final double centerIconVisualSize;

  // 中间按钮视觉大小（圆角方块本身）。
  final double centerButtonVisualSize;

  // 中间按钮圆角大小。
  final double centerButtonBorderRadius;

  // 底部文案字号。
  final double labelFontSize;

  const MainContainerPage({
    super.key,
    required this.navigationShell,
    this.navBarHeight = 76,
    this.navBarHorizontalPadding = 14,
    this.itemTapTargetSize = 76,
    this.centerTapTargetSize = 76,
    this.iconVisualSize = 28,
    this.centerIconVisualSize = 30,
    this.centerButtonVisualSize = 58,
    this.centerButtonBorderRadius = 18,
    this.labelFontSize = 11,
  });

  void _onTapTab(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedColor = Theme.of(context).colorScheme.primary;
    const unselectedColor = Colors.black45;

    Widget buildIconButton({
      required int index,
      required IconData icon,
      required String label,
      bool isCenter = false,
    }) {
      final isSelected = navigationShell.currentIndex == index;
      final color = isSelected ? selectedColor : unselectedColor;

      if (isCenter) {
        return SizedBox(
          height: centerTapTargetSize,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _onTapTab(index),
            child: Center(
              child: Container(
                width: centerButtonVisualSize,
                height: centerButtonVisualSize,
                decoration: BoxDecoration(
                  color: isSelected ? selectedColor : Colors.white,
                  borderRadius: BorderRadius.circular(centerButtonBorderRadius),
                  border: Border.all(color: color.withValues(alpha: 0.5)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x22000000),
                      blurRadius: 14,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  icon,
                  color: isSelected ? Colors.white : color,
                  size: centerIconVisualSize,
                ),
              ),
            ),
          ),
        );
      }

      return SizedBox(
        height: itemTapTargetSize,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _onTapTab(index),
          child: Center(
            child: Icon(icon, color: color, size: iconVisualSize),
          ),
        ),
      );
    }

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          height: navBarHeight,
          padding: EdgeInsets.symmetric(horizontal: navBarHorizontalPadding),
          decoration: const BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Color(0x18000000),
                blurRadius: 8,
                offset: Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Spacer(flex: 2),
                    buildIconButton(
                      index: 0,
                      icon: Icons.home_outlined,
                      label: '',
                    ),
                    const Spacer(flex: 3),
                    buildIconButton(
                      index: 1,
                      icon: Icons.grid_view_rounded,
                      label: '',
                    ),
                    const Spacer(flex: 3),
                  ],
                ),
              ),
              buildIconButton(
                index: 2,
                icon: Icons.map_rounded,
                label: '',
                isCenter: true,
              ),
              Expanded(
                child: Row(
                  children: [
                    const Spacer(flex: 3),
                    buildIconButton(
                      index: 3,
                      icon: Icons.chat_bubble_outline,
                      label: '',
                    ),
                    const Spacer(flex: 3),
                    buildIconButton(
                      index: 4,
                      icon: Icons.person_outline,
                      label: '',
                    ),
                    const Spacer(flex: 2),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
