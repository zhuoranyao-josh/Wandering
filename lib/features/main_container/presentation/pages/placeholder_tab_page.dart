import 'package:flutter/material.dart';

class PlaceholderTabPage extends StatelessWidget {
  final String title;

  const PlaceholderTabPage({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            color: Colors.black54,
          ),
        ),
      ),
    );
  }
}
