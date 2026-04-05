import 'dart:io';

import 'package:flutter/material.dart';

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
        backgroundImage: NetworkImage(imageUrl!),
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
}
