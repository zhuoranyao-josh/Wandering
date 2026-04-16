import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/app_router.dart';
import '../../../../core/di/service_locator.dart';
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
      t.communityTabNearby,
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
              // 顶部先保留社区 tabs 与搜索入口，本次仅“最新”接真实逻辑。
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
                  children: List<Widget>.generate(tabLabels.length, (_) {
                    return _LatestPostList(controller: _controller);
                  }),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LatestPostList extends StatelessWidget {
  const _LatestPostList({required this.controller});

  final CommunityController controller;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    if (t == null) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        if (controller.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.errorCode != null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _messageForErrorCode(errorCode: controller.errorCode, t: t),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: controller.refreshLatestPosts,
                    child: Text(t.communityRetry),
                  ),
                ],
              ),
            ),
          );
        }

        if (controller.latestPosts.isEmpty) {
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
          onRefresh: controller.refreshLatestPosts,
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            itemCount: controller.latestPosts.length,
            separatorBuilder: (context, index) => const SizedBox(height: 14),
            itemBuilder: (context, index) {
              final post = controller.latestPosts[index];
              return PostCard(
                post: post,
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
              );
            },
          ),
        );
      },
    );
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
      locationLabel: post.placeName ?? '',
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
    final normalizedContent = content.replaceAll('\n', ' ').trim();
    return normalizedContent;
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
