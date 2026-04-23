import 'package:flutter/material.dart';

class CommunityCard extends StatelessWidget {
  const CommunityCard({
    super.key,
    this.imageUrl,
    this.avatarUrl,
    this.userName,
    this.caption,
    this.likeCount,
    this.onTap,
  });

  final String? imageUrl;
  final String? avatarUrl;
  final String? userName;
  final String? caption;
  final int? likeCount;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final trimmedUserName = userName?.trim() ?? '';
    final trimmedCaption = caption?.trim() ?? '';

    return SizedBox(
      width: 232,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Ink(
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(18),
                  ),
                  child: SizedBox(
                    height: 142,
                    width: double.infinity,
                    child: Stack(
                      fit: StackFit.expand,
                      children: <Widget>[
                        _buildImage(),
                        Positioned(
                          top: 10,
                          left: 10,
                          child: _UserOverlay(
                            avatarUrl: avatarUrl,
                            userName: trimmedUserName,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      if (trimmedCaption.isNotEmpty)
                        Text(
                          trimmedCaption,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.35,
                            color: Color(0xFF111827),
                            fontWeight: FontWeight.w600,
                          ),
                        )
                      else
                        _buildPlaceholderLine(170),
                      const SizedBox(height: 10),
                      Row(
                        children: <Widget>[
                          const Icon(
                            Icons.favorite_border_rounded,
                            size: 16,
                            color: Color(0xFF6B7280),
                          ),
                          const SizedBox(width: 6),
                          if (likeCount != null)
                            Text(
                              '$likeCount',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF6B7280),
                              ),
                            )
                          else
                            _buildPlaceholderLine(32, height: 12),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
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

class _UserOverlay extends StatelessWidget {
  const _UserOverlay({this.avatarUrl, required this.userName});

  final String? avatarUrl;
  final String userName;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 6, 9, 6),
      decoration: BoxDecoration(
        color: const Color(0xB3000000),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          ClipOval(
            child: SizedBox(width: 20, height: 20, child: _buildAvatar()),
          ),
          const SizedBox(width: 6),
          if (userName.isNotEmpty)
            Text(
              userName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            )
          else
            Container(
              width: 52,
              height: 10,
              decoration: BoxDecoration(
                color: const Color(0x59FFFFFF),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    final value = avatarUrl?.trim() ?? '';
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return Image.network(
        value,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _avatarFallback(),
      );
    }
    if (value.isNotEmpty) {
      return Image.asset(
        value,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _avatarFallback(),
      );
    }
    return _avatarFallback();
  }

  Widget _avatarFallback() {
    return const ColoredBox(color: Color(0xFFD1D5DB));
  }
}
