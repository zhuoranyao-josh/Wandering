import 'package:flutter/material.dart';

import '../../../../core/widgets/app_network_image.dart';

class StayCard extends StatelessWidget {
  const StayCard({
    super.key,
    this.imageUrl,
    this.badge,
    this.name,
    this.priceRange,
    this.onTap,
  });

  final String? imageUrl;
  final String? badge;
  final String? name;
  final String? priceRange;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final badgeText = badge?.trim() ?? '';
    final nameText = name?.trim() ?? '';
    final priceText = priceRange?.trim() ?? '';

    return SizedBox(
      width: 246,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Ink(
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(18),
                  ),
                  child: SizedBox(
                    // 酒店卡片适度加高，减少封面图在 cover 下的纵向裁切。
                    height: 164,
                    width: double.infinity,
                    child: Stack(
                      fit: StackFit.expand,
                      children: <Widget>[
                        _buildImage(),
                        if (badgeText.isNotEmpty)
                          Positioned(
                            top: 10,
                            left: 10,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xC7000000),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                badgeText,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      if (nameText.isNotEmpty)
                        Text(
                          nameText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF111827),
                          ),
                        )
                      else
                        _buildPlaceholderLine(142),
                      if (priceText.isNotEmpty) ...<Widget>[
                        const SizedBox(height: 8),
                        Text(
                          priceText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF6B7280),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImage() {
    final value = imageUrl?.trim() ?? '';
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return AppNetworkImage(
        imageUrl: value,
        pageName: 'map.stayCard',
        fit: BoxFit.cover,
        alignment: Alignment.topCenter,
        placeholderBuilder: (context) => _buildFallback(),
        errorBuilder: (context, error) => _buildFallback(),
      );
    }
    if (value.isNotEmpty) {
      return Image.asset(
        value,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildFallback(),
      );
    }
    return _buildFallback();
  }

  Widget _buildFallback() {
    return const DecoratedBox(
      decoration: BoxDecoration(color: Color(0xFFE5E7EB)),
    );
  }

  Widget _buildPlaceholderLine(double width) {
    return Container(
      width: width,
      height: 14,
      decoration: BoxDecoration(
        color: const Color(0xFFD1D5DB),
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}
