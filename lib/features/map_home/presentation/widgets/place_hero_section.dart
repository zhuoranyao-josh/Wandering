import 'package:flutter/material.dart';

class PlaceHeroSection extends StatelessWidget {
  const PlaceHeroSection({
    super.key,
    required this.onBack,
    required this.backTooltip,
    this.imageUrl,
    this.country,
    this.placeName,
    this.locationLine,
    this.showLocationLine = false,
    this.heightFactor = 0.38,
  });

  static const double _minHeight = 260;
  static const double _maxHeight = 420;

  final VoidCallback onBack;
  final String backTooltip;
  final String? imageUrl;
  final String? country;
  final String? placeName;
  final String? locationLine;
  final bool showLocationLine;
  final double heightFactor;

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    final heroHeight = (screenHeight * heightFactor)
        .clamp(_minHeight, _maxHeight)
        .toDouble();

    final countryText = country?.trim() ?? '';
    final nameText = placeName?.trim() ?? '';
    final locationText = locationLine?.trim() ?? '';

    return SizedBox(
      height: heroHeight,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          _buildHeroImage(),
          const DecoratedBox(
            // 渐变遮罩用于保证浅色图片上文字依然可读。
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[Color(0x3A000000), Color(0xB3000000)],
              ),
            ),
          ),
          SafeArea(
            minimum: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Align(
              alignment: Alignment.topLeft,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onBack,
                  borderRadius: BorderRadius.circular(22),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0x8A000000),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white.withValues(alpha: 0.95),
                      size: 18,
                      semanticLabel: backTooltip,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  if (countryText.isNotEmpty)
                    Text(
                      countryText.toUpperCase(),
                      style: const TextStyle(
                        color: Color(0xFFF3F4F6),
                        fontSize: 11,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w700,
                      ),
                    )
                  else
                    const _PlaceholderLine(width: 84, height: 10),
                  const SizedBox(height: 8),
                  if (nameText.isNotEmpty)
                    Text(
                      nameText,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 34,
                        height: 1.1,
                        fontWeight: FontWeight.w800,
                      ),
                    )
                  else
                    const _PlaceholderLine(width: 180, height: 28),
                  if (showLocationLine) ...<Widget>[
                    const SizedBox(height: 10),
                    if (locationText.isNotEmpty)
                      Text(
                        locationText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFFE5E7EB),
                          fontSize: 14,
                          height: 1.25,
                          fontWeight: FontWeight.w500,
                        ),
                      )
                    else
                      const _PlaceholderLine(width: 128, height: 14),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroImage() {
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
    return const DecoratedBox(
      decoration: BoxDecoration(
        color: Color(0xFFD1D5DB),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFFE5E7EB), Color(0xFF9CA3AF)],
        ),
      ),
    );
  }
}

class _PlaceholderLine extends StatelessWidget {
  const _PlaceholderLine({required this.width, required this.height});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0x52FFFFFF),
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}
