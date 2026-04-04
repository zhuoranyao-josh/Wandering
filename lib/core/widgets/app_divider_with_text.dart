import 'package:flutter/material.dart';

class AppDividerWithText extends StatelessWidget {
  final String text;

  const AppDividerWithText({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(thickness: 1, color: Colors.black26)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            text,
            style: const TextStyle(color: Colors.black54, fontSize: 14),
          ),
        ),
        const Expanded(child: Divider(thickness: 1, color: Colors.black26)),
      ],
    );
  }
}
