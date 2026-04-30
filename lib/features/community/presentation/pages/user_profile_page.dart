import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/app_router.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/error/app_exception.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/post.dart';
import '../../domain/entities/user_profile_summary.dart';
import '../controllers/user_profile_controller.dart';
import '../models/community_models.dart';

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key, required this.userId, this.initialUser});

  final String userId;
  final CommunityUser? initialUser;

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  late final UserProfileController _controller;

  @override
  void initState() {
    super.initState();
    _controller = UserProfileController(
      userId: widget.userId,
      communityRepository:
          ServiceLocator.communityController.communityRepository,
      authController: ServiceLocator.authController,
      communityController: ServiceLocator.communityController,
    );
    _controller.load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _toggleFollow(AppLocalizations t) async {
    try {
      await _controller.toggleFollow();
    } catch (error) {
      if (!mounted) return;
      final message = _messageForFollowError(error: error, t: t);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  String _messageForFollowError({
    required Object error,
    required AppLocalizations t,
  }) {
    if (error is AppException && error.code == 'community_follow_failed') {
      return t.communityFollowFailed;
    }
    return t.errorUnknown;
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    if (t == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(title: Text(t.communityUserProfileTitle)),
          body: _buildBody(t),
        );
      },
    );
  }

  Widget _buildBody(AppLocalizations t) {
    if (_controller.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_controller.errorCode != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                t.communityLoadFailed,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _controller.load,
                child: Text(t.communityRetry),
              ),
            ],
          ),
        ),
      );
    }

    final summary = _controller.summary;
    if (summary == null) {
      return Center(child: Text(t.communityUserNotFound));
    }

    return RefreshIndicator(
      onRefresh: _controller.load,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ProfileHeaderCard(
              summary: summary,
              isCurrentUser: _controller.isCurrentUser,
              isFollowing: _controller.isFollowing,
              isFollowSubmitting: _controller.isFollowSubmitting,
              followLabel: t.communityFollowAction,
              unfollowLabel: t.communityUnfollowAction,
              uidLabel: t.uidLabel,
              postsLabel: t.communityStatPosts,
              followersLabel: t.communityStatFollowers,
              followingLabel: t.communityStatFollowing,
              likesReceivedLabel: t.communityStatLikesReceived,
              onFollowTap: _controller.isCurrentUser
                  ? null
                  : () => _toggleFollow(t),
            ),
            const SizedBox(height: 24),
            Text(
              t.communityFollowingListTitle,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 12),
            _FollowingListSection(
              users: _controller.followingUsers,
              emptyLabel: t.communityFollowingListEmpty,
            ),
            const SizedBox(height: 24),
            Text(
              t.communityUserPostsTitle,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 12),
            _UserPostsGrid(posts: _controller.posts),
          ],
        ),
      ),
    );
  }
}

class _ProfileHeaderCard extends StatelessWidget {
  const _ProfileHeaderCard({
    required this.summary,
    required this.isCurrentUser,
    required this.isFollowing,
    required this.isFollowSubmitting,
    required this.followLabel,
    required this.unfollowLabel,
    required this.uidLabel,
    required this.postsLabel,
    required this.followersLabel,
    required this.followingLabel,
    required this.likesReceivedLabel,
    required this.onFollowTap,
  });

  final UserProfileSummary summary;
  final bool isCurrentUser;
  final bool isFollowing;
  final bool isFollowSubmitting;
  final String followLabel;
  final String unfollowLabel;
  final String uidLabel;
  final String postsLabel;
  final String followersLabel;
  final String followingLabel;
  final String likesReceivedLabel;
  final VoidCallback? onFollowTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          _ProfileAvatar(
            name: summary.nickname,
            avatarUrl: summary.avatarUrl,
            color: _avatarColorForId(summary.uid),
          ),
          const SizedBox(height: 14),
          Text(
            summary.nickname,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$uidLabel: ${summary.uid}',
            style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
          ),
          if (summary.hasBio) ...[
            const SizedBox(height: 12),
            Text(
              summary.bio!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                height: 1.6,
                color: Color(0xFF475569),
              ),
            ),
          ],
          if (!isCurrentUser) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: 160,
              child: AppButton(
                text: isFollowing ? unfollowLabel : followLabel,
                onPressed: onFollowTap,
                isLoading: isFollowSubmitting,
                styleType: isFollowing
                    ? AppButtonStyleType.whiteOutlined
                    : AppButtonStyleType.blackFilled,
              ),
            ),
          ],
          const SizedBox(height: 20),
          // 资料页统计信息保持在同一张卡片里，减少页面层级改动。
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: [
              _StatPill(label: postsLabel, value: summary.postCount),
              _StatPill(label: followersLabel, value: summary.followerCount),
              _StatPill(label: followingLabel, value: summary.followingCount),
              _StatPill(
                label: likesReceivedLabel,
                value: summary.totalLikesReceived,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _avatarColorForId(String id) {
    const palette = <Color>[
      Color(0xFFF97316),
      Color(0xFF2563EB),
      Color(0xFF059669),
      Color(0xFFDC2626),
      Color(0xFF7C3AED),
    ];
    return palette[id.hashCode.abs() % palette.length];
  }
}

class _FollowingListSection extends StatelessWidget {
  const _FollowingListSection({required this.users, required this.emptyLabel});

  final List<UserProfileSummary> users;
  final String emptyLabel;

  @override
  Widget build(BuildContext context) {
    if (users.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          emptyLabel,
          style: const TextStyle(
            fontSize: 14,
            height: 1.6,
            color: Color(0xFF64748B),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: users
            .map((user) {
              return _FollowingListItem(user: user);
            })
            .toList(growable: false),
      ),
    );
  }
}

class _FollowingListItem extends StatelessWidget {
  const _FollowingListItem({required this.user});

  final UserProfileSummary user;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          context.push(AppRouter.communityUserProfile(user.uid));
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Row(
            children: [
              _ProfileAvatar(
                name: user.nickname,
                avatarUrl: user.avatarUrl,
                color: _avatarColorForId(user.uid),
                radius: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.nickname,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.uid,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
            ],
          ),
        ),
      ),
    );
  }

  Color _avatarColorForId(String id) {
    const palette = <Color>[
      Color(0xFFF97316),
      Color(0xFF2563EB),
      Color(0xFF059669),
      Color(0xFFDC2626),
      Color(0xFF7C3AED),
    ];
    return palette[id.hashCode.abs() % palette.length];
  }
}

class _UserPostsGrid extends StatelessWidget {
  const _UserPostsGrid({required this.posts});

  final List<Post> posts;

  @override
  Widget build(BuildContext context) {
    if (posts.isEmpty) {
      final t = AppLocalizations.of(context);
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          t?.communityEmptyPosts ?? '',
          style: const TextStyle(
            fontSize: 14,
            height: 1.6,
            color: Color(0xFF64748B),
          ),
        ),
      );
    }

    // 下半部分继续使用两列宫格，点击后进入帖子详情。
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: posts.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.82,
      ),
      itemBuilder: (context, index) {
        final post = posts[index];
        return Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () {
              context.push(AppRouter.communityPostDetail(post.id));
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(18),
                    ),
                    child: SizedBox.expand(
                      child: _ProfilePostImage(imageUrl: post.coverImageUrl),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    post.hasTitle ? post.title! : post.content,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({
    required this.name,
    required this.avatarUrl,
    required this.color,
    this.radius = 34,
  });

  final String name;
  final String? avatarUrl;
  final Color color;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final cleanAvatarUrl = avatarUrl?.trim();
    final text = name.trim().isEmpty ? '?' : name.trim().substring(0, 1);

    return CircleAvatar(
      radius: radius,
      backgroundColor: color.withValues(alpha: 0.18),
      child: cleanAvatarUrl != null && cleanAvatarUrl.isNotEmpty
          ? ClipOval(
              child: SizedBox.expand(
                child: AppNetworkImage(
                  imageUrl: cleanAvatarUrl,
                  pageName: 'community.userAvatar',
                  fit: BoxFit.cover,
                  placeholderBuilder: (context) =>
                      _buildAvatarFallback(text, color, radius),
                  errorBuilder: (context, error) =>
                      _buildAvatarFallback(text, color, radius),
                ),
              ),
            )
          : _buildAvatarFallback(text, color, radius),
    );
  }

  Widget _buildAvatarFallback(String text, Color color, double radius) {
    return Center(
      child: Text(
        text,
        style: TextStyle(
          fontSize: radius * 0.68,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$value',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfilePostImage extends StatelessWidget {
  const _ProfilePostImage({required this.imageUrl});

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

    return AppNetworkImage(
      imageUrl: cleanImageUrl,
      pageName: 'community.userProfile',
      fit: BoxFit.cover,
      placeholderBuilder: (context) => _buildPlaceholder(),
      errorBuilder: (context, error) => _buildPlaceholder(),
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
