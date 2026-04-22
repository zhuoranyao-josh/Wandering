import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/widgets/common_image_viewer.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/post.dart';
import '../../domain/entities/post_image.dart';

class PostCard extends StatelessWidget {
  const PostCard({
    super.key,
    required this.post,
    required this.onTap,
    required this.onAvatarTap,
    this.onLikeTap,
    this.isLikeLoading = false,
  });

  final Post post;
  final VoidCallback onTap;
  final VoidCallback onAvatarTap;
  final VoidCallback? onLikeTap;
  final bool isLikeLoading;

  @override
  Widget build(BuildContext context) {
    final localeTag = Localizations.localeOf(context).toLanguageTag();
    final t = AppLocalizations.of(context);
    final postImages = post.images
        .where((image) => image.url.trim().isNotEmpty)
        .toList(growable: false);
    final hasImages = postImages.isNotEmpty;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: Color(0x120F172A),
                blurRadius: 18,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 卡片头部保留用户入口，便于直接跳到个人主页。
                Row(
                  children: [
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: onAvatarTap,
                      child: _PostAvatar(
                        name: post.authorName,
                        avatarUrl: post.authorAvatarUrl,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        post.authorName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ),
                  ],
                ),
                if (post.hasTitle) ...[
                  const SizedBox(height: 14),
                  Text(
                    post.title!,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF111827),
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  _buildExcerpt(post.content),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: Color(0xFF64748B),
                  ),
                ),
                if (hasImages) ...[
                  const SizedBox(height: 14),
                  // Feed 卡片里最多展示 9 张，避免图片过多把列表撑得太长。
                  _PostImageGrid(
                    images: postImages,
                    moreCountLabelBuilder: (count) =>
                        t?.communityImageMoreCount(count) ?? '+$count',
                    moreHintBuilder: (count) =>
                        t?.communityImageMoreHint(count) ?? '+$count',
                    onImageTap: (index) =>
                        _openImageViewer(context, initialIndex: index),
                    onMoreTap: onTap,
                  ),
                ],
                const SizedBox(height: 12),
                // 底部信息固定为左侧时间地点，右侧点赞与评论。
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Text(
                        _buildMetaLabel(post: post, localeTag: localeTag),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        _MetricChip(
                          icon: post.isLikedByCurrentUser
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          value: post.likeCount,
                          iconColor: post.isLikedByCurrentUser
                              ? const Color(0xFFDC2626)
                              : const Color(0xFF64748B),
                          textColor: post.isLikedByCurrentUser
                              ? const Color(0xFF991B1B)
                              : const Color(0xFF475569),
                          onTap: onLikeTap,
                          isLoading: isLikeLoading,
                        ),
                        const SizedBox(width: 10),
                        _MetricChip(
                          icon: Icons.mode_comment_outlined,
                          value: post.commentCount,
                          iconColor: const Color(0xFF64748B),
                          textColor: const Color(0xFF475569),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _buildExcerpt(String content) {
    return content.replaceAll('\n', ' ').trim();
  }

  String _buildMetaLabel({required Post post, required String localeTag}) {
    final timeText = DateFormat(
      'MM-dd HH:mm',
      localeTag,
    ).format(post.createdAt);
    final placeText = post.locationSummaryLabel?.trim();
    if (placeText == null || placeText.isEmpty) {
      return timeText;
    }
    return '$timeText · $placeText';
  }

  Future<void> _openImageViewer(BuildContext context, {int initialIndex = 0}) {
    final images = post.images
        .where((image) => image.url.trim().isNotEmpty)
        .map((image) => _toViewerItem(image.url))
        .toList(growable: false);
    return showCommonImageViewer(
      context: context,
      images: images,
      initialIndex: initialIndex,
    );
  }

  CommonImageViewerItem _toViewerItem(String imagePath) {
    final cleanPath = imagePath.trim();
    if (cleanPath.startsWith('assets/')) {
      return CommonImageViewerItem.asset(cleanPath);
    }
    return CommonImageViewerItem.network(cleanPath);
  }
}

class _PostImageGrid extends StatelessWidget {
  const _PostImageGrid({
    required this.images,
    required this.moreCountLabelBuilder,
    required this.moreHintBuilder,
    required this.onImageTap,
    required this.onMoreTap,
  });

  final List<PostImage> images;
  final String Function(int count) moreCountLabelBuilder;
  final String Function(int count) moreHintBuilder;
  final ValueChanged<int> onImageTap;
  final VoidCallback onMoreTap;

  @override
  Widget build(BuildContext context) {
    final visibleCount = images.length > 9 ? 9 : images.length;
    final extraCount = images.length - visibleCount;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: visibleCount,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemBuilder: (context, index) {
        final image = images[index];
        final showMoreOverlay = extraCount > 0 && index == visibleCount - 1;

        return _PostGridImageTile(
          imageUrl: image.url,
          overlayLabel: showMoreOverlay
              ? moreCountLabelBuilder(extraCount)
              : null,
          overlayTooltip: showMoreOverlay ? moreHintBuilder(extraCount) : null,
          onTap: showMoreOverlay ? onMoreTap : () => onImageTap(index),
        );
      },
    );
  }
}

class _PostGridImageTile extends StatelessWidget {
  const _PostGridImageTile({
    required this.imageUrl,
    required this.onTap,
    this.overlayLabel,
    this.overlayTooltip,
  });

  final String imageUrl;
  final VoidCallback onTap;
  final String? overlayLabel;
  final String? overlayTooltip;

  @override
  Widget build(BuildContext context) {
    final hasOverlay =
        overlayLabel != null &&
        overlayLabel!.trim().isNotEmpty &&
        overlayTooltip != null;

    final image = ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        fit: StackFit.expand,
        children: [
          _PostImage(imageUrl: imageUrl),
          if (hasOverlay)
            DecoratedBox(
              decoration: const BoxDecoration(color: Color(0x8A0F172A)),
              child: Center(
                child: Text(
                  overlayLabel!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
        ],
      ),
    );

    // 单张图片点击看大图；带 +N 遮罩的最后一张则跳去详情页查看全部。
    final tile = Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: image,
      ),
    );

    if (!hasOverlay) {
      return tile;
    }

    return Tooltip(message: overlayTooltip!, child: tile);
  }
}

class _PostAvatar extends StatelessWidget {
  const _PostAvatar({required this.name, required this.avatarUrl});

  final String name;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    final cleanAvatarUrl = avatarUrl?.trim();
    final avatarText = name.trim().isEmpty ? '?' : name.trim().substring(0, 1);

    return CircleAvatar(
      radius: 22,
      backgroundColor: const Color(0xFFE2E8F0),
      foregroundImage: cleanAvatarUrl != null && cleanAvatarUrl.isNotEmpty
          ? NetworkImage(cleanAvatarUrl)
          : null,
      child: Text(
        avatarText,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: Color(0xFF475569),
        ),
      ),
    );
  }
}

class _PostImage extends StatelessWidget {
  const _PostImage({required this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final cleanImageUrl = imageUrl?.trim();
    if (cleanImageUrl == null || cleanImageUrl.isEmpty) {
      return _buildPlaceholder();
    }

    if (cleanImageUrl.startsWith('assets/')) {
      return Image.asset(cleanImageUrl, fit: BoxFit.cover);
    }

    return Image.network(
      cleanImageUrl,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: const Color(0xFFE2E8F0),
      child: const Center(
        child: Icon(Icons.image_outlined, size: 28, color: Color(0xFF94A3B8)),
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({
    required this.icon,
    required this.value,
    required this.iconColor,
    required this.textColor,
    this.onTap,
    this.isLoading = false,
  });

  final IconData icon;
  final int value;
  final Color iconColor;
  final Color textColor;
  final VoidCallback? onTap;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final child = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isLoading)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            Icon(icon, size: 16, color: iconColor),
          const SizedBox(width: 6),
          Text(
            '$value',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );

    if (onTap == null) {
      return child;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: isLoading ? null : onTap,
        child: child,
      ),
    );
  }
}
