import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/widgets/app_network_image.dart';

class GalleryGrid extends StatelessWidget {
  const GalleryGrid({
    super.key,
    this.imageUrls = const <String>[],
    this.overflowCount = 0,
    this.onImageTap,
  });

  static const int _maxTiles = 9;

  final List<String> imageUrls;
  final int overflowCount;
  final ValueChanged<int>? onImageTap;

  @override
  Widget build(BuildContext context) {
    final cleanedUrls = imageUrls
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList(growable: false);

    if (cleanedUrls.isEmpty) {
      // 无图阶段也保留网格结构，避免页面出现突兀断层。
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        // 关闭默认媒体留白，保证网格紧贴 section 标题下方。
        padding: EdgeInsets.zero,
        itemCount: 6,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
        ),
        itemBuilder: (context, index) => const DecoratedBox(
          decoration: BoxDecoration(
            color: Color(0xFFE5E7EB),
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        ),
      );
    }

    final visibleCount = math.min(cleanedUrls.length, _maxTiles);
    final computedOverflow = cleanedUrls.length > _maxTiles
        ? cleanedUrls.length - _maxTiles
        : 0;
    final effectiveOverflow = math.max(overflowCount, computedOverflow);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      // 关闭默认媒体留白，保证网格紧贴 section 标题下方。
      padding: EdgeInsets.zero,
      itemCount: visibleCount,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemBuilder: (context, index) {
        final url = cleanedUrls[index];
        final isOverflowTile =
            effectiveOverflow > 0 && index == visibleCount - 1;

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onImageTap == null ? null : () => onImageTap!(index),
            borderRadius: BorderRadius.circular(12),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  _buildImage(url),
                  if (isOverflowTile)
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.48),
                      ),
                      child: Center(
                        child: Text(
                          '+$effectiveOverflow',
                          style: const TextStyle(
                            fontSize: 20,
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildImage(String imageUrl) {
    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      return AppNetworkImage(
        imageUrl: imageUrl,
        pageName: 'map.galleryGrid',
        fit: BoxFit.cover,
        placeholderBuilder: (context) => _buildFallback(),
        errorBuilder: (context, error) => _buildFallback(),
      );
    }
    return Image.asset(
      imageUrl,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => _buildFallback(),
    );
  }

  Widget _buildFallback() {
    return const ColoredBox(color: Color(0xFFD1D5DB));
  }
}
