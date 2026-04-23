import 'package:flutter/material.dart';

class FlavorListItem extends StatelessWidget {
  const FlavorListItem({
    super.key,
    this.imageUrl,
    this.name,
    this.subtitle,
    this.onTap,
  });

  final String? imageUrl;
  final String? name;
  final String? subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final nameText = name?.trim() ?? '';
    final subtitleText = subtitle?.trim() ?? '';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: <Widget>[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(width: 70, height: 70, child: _buildImage()),
              ),
              const SizedBox(width: 12),
              Expanded(
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
                          color: Color(0xFF111827),
                          fontWeight: FontWeight.w700,
                        ),
                      )
                    else
                      _buildPlaceholderLine(120),
                    const SizedBox(height: 6),
                    if (subtitleText.isNotEmpty)
                      Text(
                        subtitleText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF6B7280),
                          fontWeight: FontWeight.w500,
                        ),
                      )
                    else
                      _buildPlaceholderLine(82, height: 12),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImage() {
    final value = imageUrl?.trim() ?? '';
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return Image.network(
        value,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildFallback(),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) {
            return child;
          }
          return _buildFallback();
        },
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
    return const ColoredBox(color: Color(0xFFE5E7EB));
  }

  Widget _buildPlaceholderLine(double width, {double height = 14}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFD1D5DB),
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}
