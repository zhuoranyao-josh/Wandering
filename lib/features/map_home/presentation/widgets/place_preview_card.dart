import 'package:flutter/material.dart';

import '../../../../core/widgets/app_button.dart';

class PlacePreviewCard extends StatelessWidget {
  const PlacePreviewCard({
    super.key,
    required this.title,
    required this.description,
    required this.imageAssetPath,
    required this.buttonText,
    required this.onPressed,
  });

  final String title;
  final String description;
  final String imageAssetPath;
  final String buttonText;
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
            Text(
              title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Color(0xFF111827),
              ),
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
                child: Image.asset(imageAssetPath, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: 16),
            AppButton(text: buttonText, onPressed: onPressed),
          ],
        ),
      ),
    );
  }
}
