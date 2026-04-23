import 'package:flutter/material.dart';

class BilingualTextField extends StatelessWidget {
  const BilingualTextField({
    super.key,
    required this.label,
    required this.zhLabel,
    required this.enLabel,
    required this.zhController,
    required this.enController,
    this.zhHint,
    this.enHint,
  });

  final String label;
  final String zhLabel;
  final String enLabel;
  final TextEditingController zhController;
  final TextEditingController enController;
  final String? zhHint;
  final String? enHint;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: zhController,
          decoration: InputDecoration(
            labelText: zhLabel,
            hintText: zhHint,
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: enController,
          decoration: InputDecoration(
            labelText: enLabel,
            hintText: enHint,
            border: const OutlineInputBorder(),
          ),
        ),
      ],
    );
  }
}
