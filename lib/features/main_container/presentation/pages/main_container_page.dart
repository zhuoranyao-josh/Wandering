import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MainContainerPage extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  final double navBarHeight;
  final double navBarHorizontalPadding;
  final double itemTapTargetSize;
  final double centerTapTargetSize;
  final double iconVisualSize;
  final double centerIconVisualSize;
  final double centerButtonVisualSize;
  final double centerButtonBorderRadius;

  // 调试开关：true 时高亮显示点击热区，方便观察范围。
  final bool showTapLayerDebug;

  const MainContainerPage({
    super.key,
    required this.navigationShell,
    this.navBarHeight = 76,
    this.navBarHorizontalPadding = 14,
    this.itemTapTargetSize = 48,
    this.centerTapTargetSize = 78,
    this.iconVisualSize = 28,
    this.centerIconVisualSize = 30,
    this.centerButtonVisualSize = 58,
    this.centerButtonBorderRadius = 18,
    this.showTapLayerDebug = false,
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

    Widget buildVisualIcon({
      required int index,
      required IconData icon,
      bool isCenter = false,
    }) {
      final isSelected = navigationShell.currentIndex == index;
      final color = isSelected ? selectedColor : unselectedColor;

      if (isCenter) {
        return Center(
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
        );
      }

      return Center(
        child: Icon(icon, color: color, size: iconVisualSize),
      );
    }

    Widget buildTapTarget({required int index, required double size}) {
      return Center(
        child: SizedBox(
          width: size,
          height: size,
          // 点击层只负责命中测试和 onTap，不负责视觉图标展示。
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _onTapTab(index),
            child: DecoratedBox(
              decoration: showTapLayerDebug
                  ? BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.12),
                      border: Border.all(
                        color: Colors.blue.withValues(alpha: 0.6),
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    )
                  : const BoxDecoration(),
              child: const SizedBox.expand(),
            ),
          ),
        ),
      );
    }

    Widget buildVisualLayer() {
      // 视觉层：保持 Spacer 留白和图标位置，只管“看起来”。
      return IgnorePointer(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Row(
                children: [
                  const Spacer(flex: 2),
                  buildVisualIcon(index: 0, icon: Icons.home_outlined),
                  const Spacer(flex: 3),
                  buildVisualIcon(index: 1, icon: Icons.grid_view_rounded),
                  const Spacer(flex: 3),
                ],
              ),
            ),
            buildVisualIcon(index: 2, icon: Icons.map_rounded, isCenter: true),
            Expanded(
              child: Row(
                children: [
                  const Spacer(flex: 3),
                  buildVisualIcon(index: 3, icon: Icons.chat_bubble_outline),
                  const Spacer(flex: 3),
                  buildVisualIcon(index: 4, icon: Icons.person_outline),
                  const Spacer(flex: 2),
                ],
              ),
            ),
          ],
        ),
      );
    }

    Widget buildTapLayer() {
      // 点击层：按同样结构叠一层透明热区，扩大可点击范围。
      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Row(
              children: [
                const Spacer(flex: 2),
                buildTapTarget(index: 0, size: itemTapTargetSize),
                const Spacer(flex: 3),
                buildTapTarget(index: 1, size: itemTapTargetSize),
                const Spacer(flex: 3),
              ],
            ),
          ),
          buildTapTarget(index: 2, size: centerTapTargetSize),
          Expanded(
            child: Row(
              children: [
                const Spacer(flex: 3),
                buildTapTarget(index: 3, size: itemTapTargetSize),
                const Spacer(flex: 3),
                buildTapTarget(index: 4, size: itemTapTargetSize),
                const Spacer(flex: 2),
              ],
            ),
          ),
        ],
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
          child: Stack(
            fit: StackFit.expand,
            children: [buildVisualLayer(), buildTapLayer()],
          ),
        ),
      ),
    );
  }
}
