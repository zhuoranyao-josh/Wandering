import 'package:flutter/material.dart';

import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_network_image.dart';

class PlacePreviewCard extends StatelessWidget {
  const PlacePreviewCard({
    super.key,
    required this.title,
    this.description,
    this.imageUrl,
    this.imageAssetPath,
    this.primaryButtonText,
    this.primaryButtonLoading = false,
    required this.onClose,
    this.onPrimaryPressed,
  });

  final String title;
  final String? description;
  final String? imageUrl;
  final String? imageAssetPath;
  final String? primaryButtonText;
  final bool primaryButtonLoading;
  final VoidCallback onClose;
  final VoidCallback? onPrimaryPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x26000000),
            blurRadius: 24,
            offset: Offset(0, 16),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111827),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: onClose,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.close,
                        size: 18,
                        color: Color(0xFF374151),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (_hasDescription) ...[
              const SizedBox(height: 8),
              Text(
                description!.trim(),
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.55,
                  color: Color(0xFF4B5563),
                ),
              ),
            ],
            if (_hasImage) ...[
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: AspectRatio(
                  // 预览卡封面统一为 16:9，和视频/横图素材比例更一致。
                  aspectRatio: 16 / 9,
                  child: _buildCoverImage(),
                ),
              ),
            ],
            if (primaryButtonText != null) ...[
              const SizedBox(height: 16),
              AppButton(
                text: primaryButtonText!,
                onPressed: onPrimaryPressed,
                // 创建 checklist 时保留按钮位置，避免卡片切到“无按钮版本”造成叠层错觉。
                isLoading: primaryButtonLoading,
              ),
            ],
          ],
        ),
      ),
    );
  }

  bool get _hasDescription => (description?.trim().isNotEmpty ?? false);

  bool get _hasImage =>
      (imageUrl?.trim().isNotEmpty ?? false) ||
      (imageAssetPath?.trim().isNotEmpty ?? false);

  Widget _buildCoverImage() {
    final trimmedImageUrl = imageUrl?.trim() ?? '';
    final trimmedImageAssetPath = imageAssetPath?.trim() ?? '';

    if (trimmedImageUrl.startsWith('http://') ||
        trimmedImageUrl.startsWith('https://')) {
      // Firestore 默认走网络图；加载失败时退回纯色占位，避免卡片直接空白。
      return AppNetworkImage(
        imageUrl: trimmedImageUrl,
        pageName: 'map.placePreviewCard',
        fit: BoxFit.cover,
        alignment: Alignment.topCenter,
        placeholderBuilder: (context) => _buildFallbackImage(),
        errorBuilder: (context, error) => _buildFallbackImage(),
      );
    }
    if (trimmedImageAssetPath.isNotEmpty) {
      return Image.asset(
        trimmedImageAssetPath,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildFallbackImage(),
      );
    }

    return _buildFallbackImage();
  }

  Widget _buildFallbackImage() {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFFF59E0B), Color(0xFFFB7185)],
        ),
      ),
      child: Center(child: Icon(Icons.public, size: 40, color: Colors.white)),
    );
  }
}
