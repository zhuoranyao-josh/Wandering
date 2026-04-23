import 'package:flutter/material.dart';

class InfoChipsRow extends StatelessWidget {
  const InfoChipsRow({super.key, this.tagline, this.chips = const <String>[]});

  final String? tagline;
  final List<String> chips;

  @override
  Widget build(BuildContext context) {
    final trimmedTagline = tagline?.trim() ?? '';
    final chipValues = chips
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (trimmedTagline.isNotEmpty)
          Text(
            trimmedTagline,
            style: const TextStyle(
              fontSize: 17,
              height: 1.45,
              fontWeight: FontWeight.w500,
              color: Color(0xFF1F2937),
              fontStyle: FontStyle.italic,
            ),
          )
        else
          const SizedBox.shrink(),
        if (trimmedTagline.isNotEmpty) const SizedBox(height: 14),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: chipValues.isEmpty
                ? const <Widget>[
                    _ChipPlaceholder(),
                    SizedBox(width: 8),
                    _ChipPlaceholder(),
                  ]
                : chipValues
                      .map(
                        (value) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _InfoChip(label: value),
                        ),
                      )
                      .toList(growable: false),
          ),
        ),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Color(0xFF1F2937),
        ),
      ),
    );
  }
}

class _ChipPlaceholder extends StatelessWidget {
  const _ChipPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 86,
      height: 30,
      decoration: BoxDecoration(
        color: const Color(0xFFE5E7EB),
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}
