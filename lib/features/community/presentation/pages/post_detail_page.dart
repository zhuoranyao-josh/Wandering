import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/app_router.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/error/app_exception.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../../core/widgets/common_image_viewer.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/comment.dart';
import '../../domain/entities/post.dart';
import '../../domain/entities/post_image.dart';
import '../controllers/post_detail_controller.dart';
import '../models/community_models.dart';

class PostDetailPage extends StatefulWidget {
  const PostDetailPage({super.key, required this.postId, this.initialPost});

  final String postId;
  final CommunityPost? initialPost;

  @override
  State<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage> {
  late final PostDetailController _controller;
  late final TextEditingController _commentController;
  late final FocusNode _commentFocusNode;

  @override
  void initState() {
    super.initState();
    _commentController = TextEditingController();
    _commentFocusNode = FocusNode();
    _controller = PostDetailController(
      postId: widget.postId,
      communityRepository:
          ServiceLocator.communityController.communityRepository,
      authController: ServiceLocator.authController,
      profileSetupController: ServiceLocator.profileSetupController,
      communityController: ServiceLocator.communityController,
    );
    _controller.load();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _commentFocusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submitComment(AppLocalizations t) async {
    try {
      await _controller.submitComment(_commentController.text);
      _commentController.clear();
      if (!mounted) return;
      _commentFocusNode.unfocus();
    } catch (error) {
      if (!mounted) return;
      final message = _messageForCommentError(error: error, t: t);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  void _startReply(Comment comment) {
    _controller.startReply(comment);
    _commentFocusNode.requestFocus();
  }

  Future<void> _toggleLike(AppLocalizations t) async {
    try {
      await _controller.toggleLike();
    } catch (error) {
      if (!mounted) return;
      final message = _messageForLikeError(error: error, t: t);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _confirmDeletePost(AppLocalizations t) async {
    final shouldDelete = await _showDeleteConfirmDialog(
      title: t.communityDeletePostTitle,
      message: t.communityDeletePostMessage,
      confirmLabel: t.communityDeleteAction,
    );
    if (shouldDelete != true) {
      return;
    }

    try {
      await _controller.deletePost();
      if (!mounted) return;
      context.pop();
    } catch (error) {
      if (!mounted) return;
      final message = _messageForDeleteError(error: error, t: t);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _confirmDeleteComment(
    Comment comment,
    AppLocalizations t,
  ) async {
    final shouldDelete = await _showDeleteConfirmDialog(
      title: t.communityDeleteCommentTitle,
      message: t.communityDeleteCommentMessage,
      confirmLabel: t.communityDeleteAction,
    );
    if (shouldDelete != true) {
      return;
    }

    try {
      await _controller.deleteComment(comment);
    } catch (error) {
      if (!mounted) return;
      final message = _messageForDeleteError(error: error, t: t);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<bool?> _showDeleteConfirmDialog({
    required String title,
    required String message,
    required String confirmLabel,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final t = AppLocalizations.of(dialogContext);
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(t?.cancel ?? ''),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(confirmLabel),
            ),
          ],
        );
      },
    );
  }

  String _messageForCommentError({
    required Object error,
    required AppLocalizations t,
  }) {
    if (error is AppException) {
      switch (error.code) {
        case 'community_comment_empty':
          return t.communityCommentEmpty;
        case 'community_comment_submit_failed':
          return t.communityCommentSubmitFailed;
      }
    }
    return t.errorUnknown;
  }

  String _messageForLikeError({
    required Object error,
    required AppLocalizations t,
  }) {
    if (error is AppException && error.code == 'community_like_failed') {
      return t.communityLikeFailed;
    }
    return t.errorUnknown;
  }

  String _messageForDeleteError({
    required Object error,
    required AppLocalizations t,
  }) {
    if (error is AppException) {
      switch (error.code) {
        case 'community_delete_post_failed':
          return t.communityDeletePostFailed;
        case 'community_delete_comment_failed':
          return t.communityDeleteCommentFailed;
      }
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
          appBar: AppBar(title: Text(t.communityPostDetailTitle)),
          body: _buildBody(t),
          bottomNavigationBar: _buildCommentComposer(t),
        );
      },
    );
  }

  Widget _buildBody(AppLocalizations t) {
    if (_controller.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_controller.errorCode != null && _controller.post == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _messageForLoadError(errorCode: _controller.errorCode, t: t),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _controller.refresh,
                child: Text(t.communityRetry),
              ),
            ],
          ),
        ),
      );
    }

    final post = _controller.post;
    if (post == null) {
      return Center(child: Text(t.communityPostNotFound));
    }

    return RefreshIndicator(
      onRefresh: _controller.refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          _PostHeader(
            post: post,
            isLikeSubmitting: _controller.isLikeSubmitting,
            isPostDeleting: _controller.isPostDeleting,
            canDeletePost: _controller.canDeletePost,
            deletePostTooltip: t.communityDeletePostAction,
            onLikeTap: () => _toggleLike(t),
            onDeletePost: () => _confirmDeletePost(t),
            onImageTap: (index) => _openPostImages(post, index),
            onAuthorTap: () {
              context.push(
                AppRouter.communityUserProfile(post.authorId),
                extra: CommunityUser(
                  id: post.authorId,
                  name: post.authorName,
                  uid: post.authorId,
                  avatarColor: _avatarColorForId(post.authorId),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          Text(
            t.communityCommentsTitle,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 12),
          if (_controller.hasCommentsLoadError) ...[
            // 评论读取失败时保留帖子主体，给用户明确的局部重试入口。
            _CommentsLoadErrorCard(
              message: t.communityLoadFailed,
              retryLabel: t.communityRetry,
              onRetry: _controller.refresh,
            ),
            const SizedBox(height: 12),
          ],
          if (_controller.topLevelComments.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(
                t.communityCommentsEmpty,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Color(0xFF64748B)),
              ),
            )
          else
            ..._controller.topLevelComments.map((comment) {
              final replies = _controller.repliesFor(comment.id);
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _CommentCard(
                  comment: comment,
                  replies: replies,
                  isExpanded: _controller.isExpanded(comment.id),
                  deleteTooltip: t.communityDeleteCommentAction,
                  canDeleteComment: _controller.canDeleteComment,
                  isCommentDeleting: _controller.isCommentDeleting,
                  onReplyTap: () => _startReply(comment),
                  onDeleteComment: (comment) =>
                      _confirmDeleteComment(comment, t),
                  onToggleReplies: replies.length > 3
                      ? () => _controller.toggleReplies(comment.id)
                      : null,
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildCommentComposer(AppLocalizations t) {
    if (_controller.post == null || _controller.errorCode != null) {
      return const SizedBox.shrink();
    }

    final viewInsetsBottom = MediaQuery.of(context).viewInsets.bottom;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: viewInsetsBottom),
      child: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
          decoration: const BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Color(0x12000000),
                blurRadius: 10,
                offset: Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_controller.replyTarget != null)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          t.communityReplyingToUser(
                            _controller.replyTarget!.userName,
                          ),
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF475569),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: _controller.isSubmitting
                            ? null
                            : _controller.clearReplyTarget,
                        child: Text(t.communityCancelReply),
                      ),
                    ],
                  ),
                ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      focusNode: _commentFocusNode,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.newline,
                      decoration: InputDecoration(
                        hintText: t.communityCommentHint,
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _controller.isSubmitting
                          ? null
                          : () => _submitComment(t),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _controller.isSubmitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(t.communityCommentSend),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _messageForLoadError({
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

  Future<void> _openPostImages(Post post, int initialIndex) {
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

class _CommentsLoadErrorCard extends StatelessWidget {
  const _CommentsLoadErrorCard({
    required this.message,
    required this.retryLabel,
    required this.onRetry,
  });

  final String message;
  final String retryLabel;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 18,
            color: Color(0xFFB45309),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 8,
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 13,
                height: 1.5,
                color: Color(0xFF475569),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          TextButton(onPressed: onRetry, child: Text(retryLabel)),
        ],
      ),
    );
  }
}

class _PostHeader extends StatelessWidget {
  const _PostHeader({
    required this.post,
    required this.onAuthorTap,
    required this.onLikeTap,
    required this.onDeletePost,
    required this.onImageTap,
    required this.isLikeSubmitting,
    required this.isPostDeleting,
    required this.canDeletePost,
    required this.deletePostTooltip,
  });

  final Post post;
  final VoidCallback onAuthorTap;
  final VoidCallback onLikeTap;
  final VoidCallback onDeletePost;
  final ValueChanged<int> onImageTap;
  final bool isLikeSubmitting;
  final bool isPostDeleting;
  final bool canDeletePost;
  final String deletePostTooltip;

  @override
  Widget build(BuildContext context) {
    final localeTag = Localizations.localeOf(context).toLanguageTag();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 详情头部保留作者入口，方便从帖子详情继续浏览用户主页。
        Row(
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onAuthorTap,
              child: _DetailAvatar(
                name: post.authorName,
                avatarUrl: post.authorAvatarUrl,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                post.authorName,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              DateFormat('MM-dd HH:mm', localeTag).format(post.createdAt),
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
          ],
        ),
        if (post.hasTitle) ...[
          const SizedBox(height: 18),
          Text(
            post.title!,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
        ],
        const SizedBox(height: 12),
        Text(
          post.content,
          style: const TextStyle(
            fontSize: 15,
            height: 1.7,
            color: Color(0xFF334155),
          ),
        ),
        if (post.hasImages) ...[
          const SizedBox(height: 16),
          _PostImageGallery(images: post.images, onImageTap: onImageTap),
        ],
        if (post.locationFullLabel != null &&
            post.locationFullLabel!.trim().isNotEmpty) ...[
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 1),
                child: Icon(
                  Icons.place_rounded,
                  size: 16,
                  color: Color(0xFFDC2626),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  post.locationFullLabel!,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 16),
        Row(
          children: [
            _DetailMetric(
              icon: post.isLikedByCurrentUser
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
              value: post.likeCount,
              iconColor: post.isLikedByCurrentUser
                  ? const Color(0xFFDC2626)
                  : const Color(0xFF64748B),
              textColor: post.isLikedByCurrentUser
                  ? const Color(0xFF991B1B)
                  : const Color(0xFF334155),
              onTap: onLikeTap,
              isLoading: isLikeSubmitting,
            ),
            const SizedBox(width: 12),
            _DetailMetric(
              icon: Icons.mode_comment_outlined,
              value: post.commentCount,
              iconColor: const Color(0xFF64748B),
              textColor: const Color(0xFF334155),
            ),
            const Spacer(),
            if (canDeletePost) ...[
              // 帖子删除入口放到互动数据同一行，右侧用垃圾桶图标承载。
              _DeleteIconButton(
                tooltip: deletePostTooltip,
                isLoading: isPostDeleting,
                onTap: onDeletePost,
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _CommentCard extends StatelessWidget {
  const _CommentCard({
    required this.comment,
    required this.replies,
    required this.isExpanded,
    required this.deleteTooltip,
    required this.canDeleteComment,
    required this.isCommentDeleting,
    required this.onReplyTap,
    required this.onDeleteComment,
    this.onToggleReplies,
  });

  final Comment comment;
  final List<Comment> replies;
  final bool isExpanded;
  final String deleteTooltip;
  final bool Function(Comment comment) canDeleteComment;
  final bool Function(String commentId) isCommentDeleting;
  final VoidCallback onReplyTap;
  final ValueChanged<Comment> onDeleteComment;
  final VoidCallback? onToggleReplies;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    if (t == null) {
      return const SizedBox.shrink();
    }

    final localeTag = Localizations.localeOf(context).toLanguageTag();
    final visibleReplies = isExpanded || replies.length <= 3
        ? replies
        : replies.take(3).toList(growable: false);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DetailAvatar(
                name: comment.userName,
                avatarUrl: comment.userAvatarUrl,
                radius: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            comment.userName,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        Text(
                          DateFormat(
                            'MM-dd HH:mm',
                            localeTag,
                          ).format(comment.createdAt),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      comment.content,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: Color(0xFF475569),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        TextButton(
                          onPressed: onReplyTap,
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(t.communityReplyAction),
                        ),
                        const Spacer(),
                        if (canDeleteComment(comment)) ...[
                          // 评论删除放在卡片底部右侧，避免和用户名、时间信息挤在一起。
                          _DeleteIconButton(
                            tooltip: deleteTooltip,
                            isLoading: isCommentDeleting(comment.id),
                            onTap: () => onDeleteComment(comment),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (visibleReplies.isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(
              margin: const EdgeInsets.only(left: 50),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...visibleReplies.map((reply) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _replyPreviewText(reply, t),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              height: 1.4,
                              color: Color(0xFF475569),
                            ),
                          ),
                          if (canDeleteComment(reply)) ...[
                            const SizedBox(height: 4),
                            Align(
                              alignment: Alignment.centerRight,
                              child: _DeleteIconButton(
                                tooltip: deleteTooltip,
                                isLoading: isCommentDeleting(reply.id),
                                onTap: () => onDeleteComment(reply),
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  }),
                  if (replies.length > 3 || isExpanded) ...[
                    const SizedBox(height: 4),
                    GestureDetector(
                      onTap: onToggleReplies,
                      child: Text(
                        isExpanded
                            ? t.communityHideReplies
                            : t.communityViewAllReplies(replies.length),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _replyPreviewText(Comment reply, AppLocalizations t) {
    final replyToUserName = reply.replyToUserName?.trim();
    if (replyToUserName != null && replyToUserName.isNotEmpty) {
      return t.communityReplyPreview(
        reply.userName,
        replyToUserName,
        reply.content,
      );
    }
    return '${reply.userName}: ${reply.content}';
  }
}

class _DeleteIconButton extends StatelessWidget {
  const _DeleteIconButton({
    required this.tooltip,
    required this.isLoading,
    required this.onTap,
  });

  final String tooltip;
  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const SizedBox(
        width: 20,
        height: 20,
        child: Padding(
          padding: EdgeInsets.all(2),
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    // 统一使用垃圾桶按钮，和帖子删除入口保持一致，减少用户理解成本。
    return IconButton(
      onPressed: onTap,
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      splashRadius: 18,
      icon: const Icon(
        Icons.delete_outline_rounded,
        size: 20,
        color: Color(0xFF94A3B8),
      ),
    );
  }
}

class _PostImageGallery extends StatelessWidget {
  const _PostImageGallery({required this.images, required this.onImageTap});

  final List<PostImage> images;
  final ValueChanged<int> onImageTap;

  @override
  Widget build(BuildContext context) {
    // 详情页展示全部图片，不做 9 张裁剪，方便用户完整浏览帖子内容。
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: images.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1,
      ),
      itemBuilder: (context, index) {
        final image = images[index];
        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => onImageTap(index),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: _DetailImage(imagePath: image.url),
            ),
          ),
        );
      },
    );
  }
}

class _DetailAvatar extends StatelessWidget {
  const _DetailAvatar({
    required this.name,
    required this.avatarUrl,
    this.radius = 24,
  });

  final String name;
  final String? avatarUrl;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final avatarText = name.trim().isEmpty ? '?' : name.trim().substring(0, 1);
    final cleanAvatarUrl = avatarUrl?.trim();

    return CircleAvatar(
      radius: radius,
      backgroundColor: const Color(0xFFE2E8F0),
      child: cleanAvatarUrl != null && cleanAvatarUrl.isNotEmpty
          ? ClipOval(
              child: SizedBox.expand(
                child: AppNetworkImage(
                  imageUrl: cleanAvatarUrl,
                  pageName: 'community.detailAvatar',
                  fit: BoxFit.cover,
                  placeholderBuilder: (context) =>
                      _buildAvatarFallback(avatarText),
                  errorBuilder: (context, error) =>
                      _buildAvatarFallback(avatarText),
                ),
              ),
            )
          : _buildAvatarFallback(avatarText),
    );
  }

  Widget _buildAvatarFallback(String avatarText) {
    return Center(
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

class _DetailMetric extends StatelessWidget {
  const _DetailMetric({
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isLoading)
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            Icon(icon, size: 18, color: iconColor),
          const SizedBox(width: 6),
          Text(
            '$value',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
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

class _DetailImage extends StatelessWidget {
  const _DetailImage({required this.imagePath});

  final String imagePath;

  @override
  Widget build(BuildContext context) {
    final cleanImagePath = imagePath.trim();
    if (cleanImagePath.isEmpty) {
      return _buildPlaceholder();
    }

    if (cleanImagePath.startsWith('assets/')) {
      return Image.asset(cleanImagePath, fit: BoxFit.cover);
    }

    return AppNetworkImage(
      imageUrl: cleanImagePath,
      pageName: 'community.postDetail',
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
