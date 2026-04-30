import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../core/widgets/app_network_image.dart';

class AvatarPicker extends StatelessWidget {
  final String? imagePath;
  final String? imageUrl;
  final VoidCallback onTap;

  const AvatarPicker({
    super.key,
    required this.imagePath,
    required this.imageUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Widget avatarChild;

    if (imagePath != null && imagePath!.isNotEmpty) {
      avatarChild = CircleAvatar(
        radius: 46,
        backgroundImage: FileImage(File(imagePath!)),
      );
    } else if (imageUrl != null && imageUrl!.isNotEmpty) {
      avatarChild = CircleAvatar(
        radius: 46,
        backgroundColor: const Color(0xFFE5E7EB),
        child: ClipOval(
          child: SizedBox.expand(
            child: AppNetworkImage(
              imageUrl: imageUrl!,
              pageName: 'profile.avatarPicker',
              fit: BoxFit.cover,
              placeholderBuilder: (context) => _buildFallbackAvatar(),
              errorBuilder: (context, error) => _buildFallbackAvatar(),
            ),
          ),
        ),
      );
    } else {
      avatarChild = const CircleAvatar(
        radius: 46,
        child: Icon(Icons.person, size: 40),
      );
    }

    return Column(
      children: [
        GestureDetector(onTap: onTap, child: avatarChild),
        const SizedBox(height: 8),
        const Text('Tap to choose avatar'),
      ],
    );
  }

  Widget _buildFallbackAvatar() {
    return const Center(child: Icon(Icons.person, size: 40));
  }
}
