import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/app_router.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/error/app_exception.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/post.dart';
import '../controllers/community_controller.dart';
import '../models/community_models.dart';
import '../widgets/post_card.dart';

const String _fallbackPreviewImagePath = 'assets/images/tokyo_preview.png';

class CommunityPage extends StatefulWidget {
  const CommunityPage({super.key});

  @override
  State<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage> {
  late final CommunityController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ServiceLocator.communityController;
    _controller.ensureInitialized();
  }

  Future<void> _openCreatePostPage() async {
    await context.push(AppRouter.communityCreatePost());
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    if (t == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final tabLabels = <String>[
      t.communityTabFollowing,
      t.communityTabLatest,
      t.communityTabPopular,
    ];

    return DefaultTabController(
      length: tabLabels.length,
      initialIndex: 1,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        floatingActionButton: FloatingActionButton(
          onPressed: _openCreatePostPage,
          child: const Icon(Icons.add_rounded),
        ),
        body: SafeArea(
          child: Column(
            children: [
              // 顶部保留三个真实 feed 和搜索入口，搜索继续只保留 UI。
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: TabBar(
                        isScrollable: true,
                        tabAlignment: TabAlignment.start,
                        labelColor: const Color(0xFF0F172A),
                        unselectedLabelColor: const Color(0xFF94A3B8),
                        labelStyle: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                        unselectedLabelStyle: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                        dividerColor: Colors.transparent,
                        indicatorColor: const Color(0xFF111827),
                        tabs: tabLabels
                            .map((label) => Tab(text: label))
                            .toList(),
                      ),
                    ),
                    IconButton(
                      onPressed: () {},
                      tooltip: t.communitySearchTooltip,
                      icon: const Icon(Icons.search_rounded),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  children: const <Widget>[
                    _FeedPostList(type: CommunityFeedType.following),
                    _FeedPostList(type: CommunityFeedType.latest),
                    _FeedPostList(type: CommunityFeedType.trending),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeedPostList extends StatelessWidget {
  const _FeedPostList({required this.type});

  final CommunityFeedType type;

  @override
  Widget build(BuildContext context) {
    final controller = ServiceLocator.communityController;
    final t = AppLocalizations.of(context);
    if (t == null) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final posts = controller.postsFor(type);
        final errorCode = controller.feedErrorCode(type);
        final isLoading = controller.isFeedLoading(type);

        if (isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (errorCode != null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _messageForErrorCode(errorCode: errorCode, t: t),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _refreshFeed(controller, type),
                    child: Text(t.communityRetry),
                  ),
                ],
              ),
            ),
          );
        }

        if (posts.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                t.communityEmptyPosts,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.6,
                  color: Color(0xFF6B7280),
                ),
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => _refreshFeed(controller, type),
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            itemCount: posts.length,
            separatorBuilder: (context, index) => const SizedBox(height: 14),
            itemBuilder: (context, index) {
              final post = posts[index];
              return PostCard(
                post: post,
                isLikeLoading: controller.isPostLikePending(post.id),
                onTap: () {
                  context.push(
                    AppRouter.communityPostDetail(post.id),
                    extra: _toPresentationPost(
                      post: post,
                      localeTag: Localizations.localeOf(
                        context,
                      ).toLanguageTag(),
                    ),
                  );
                },
                onAvatarTap: () {
                  context.push(
                    AppRouter.communityUserProfile(post.authorId),
                    extra: _toPresentationUser(post),
                  );
                },
                onLikeTap: () => _handleLikeTap(
                  context: context,
                  controller: controller,
                  post: post,
                  t: t,
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _handleLikeTap({
    required BuildContext context,
    required CommunityController controller,
    required Post post,
    required AppLocalizations t,
  }) async {
    try {
      await controller.togglePostLike(post);
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      final message = _messageForActionError(error: error, t: t);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _refreshFeed(
    CommunityController controller,
    CommunityFeedType type,
  ) {
    switch (type) {
      case CommunityFeedType.following:
        return controller.refreshFollowingPosts();
      case CommunityFeedType.latest:
        return controller.refreshLatestPosts();
      case CommunityFeedType.trending:
        return controller.refreshTrendingPosts();
    }
  }

  String _messageForErrorCode({
    required String? errorCode,
    required AppLocalizations t,
  }) {
    switch (errorCode) {
      case 'community_load_failed':
        return t.communityLoadFailed;
      default:
        return t.errorUnknown;
    }
  }

  String _messageForActionError({
    required Object error,
    required AppLocalizations t,
  }) {
    if (error is AppException) {
      switch (error.code) {
        case 'community_like_failed':
          return t.communityLikeFailed;
      }
    }
    return t.errorUnknown;
  }

  CommunityPost _toPresentationPost({
    required Post post,
    required String localeTag,
  }) {
    return CommunityPost(
      id: post.id,
      author: _toPresentationUser(post),
      title: post.hasTitle ? post.title! : _buildExcerpt(post.content),
      excerpt: _buildExcerpt(post.content),
      content: post.content,
      imageAssetPath: post.coverImageUrl ?? _fallbackPreviewImagePath,
      timeLabel: DateFormat('MM-dd HH:mm', localeTag).format(post.createdAt),
      locationLabel: post.locationSummaryLabel ?? '',
      likeCount: post.likeCount,
      commentCount: post.commentCount,
      comments: const <CommunityComment>[],
    );
  }

  CommunityUser _toPresentationUser(Post post) {
    return CommunityUser(
      id: post.authorId,
      name: post.authorName,
      uid: post.authorId,
      avatarColor: _avatarColorForId(post.authorId),
    );
  }

  String _buildExcerpt(String content) {
    return content.replaceAll('\n', ' ').trim();
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
