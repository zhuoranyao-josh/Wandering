import 'package:flutter/material.dart';

import '../../../../core/widgets/app_button.dart';

class PlacePreviewCard extends StatelessWidget {
  const PlacePreviewCard({
    super.key,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.buttonText,
    required this.onClose,
    required this.onPressed,
  });

  final String title;
  final String description;
  final String imageUrl;
  final String buttonText;
  final VoidCallback onClose;
  final VoidCallback onPressed;

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
            const SizedBox(height: 8),
            Text(
              description,
              style: const TextStyle(
                fontSize: 13,
                height: 1.55,
                color: Color(0xFF4B5563),
              ),
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: _buildCoverImage(),
              ),
            ),
            const SizedBox(height: 16),
            AppButton(text: buttonText, onPressed: onPressed),
          ],
        ),
      ),
    );
  }

  Widget _buildCoverImage() {
    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      // Firestore 默认走网络图；加载失败时退回纯色占位，避免卡片直接空白。
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildFallbackImage(),
        loadingBuilder: (context, child, progress) {
          if (progress == null) {
            return child;
          }
          return _buildFallbackImage();
        },
      );
    }
    if (imageUrl.isNotEmpty) {
      return Image.asset(
        imageUrl,
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
