class Comment {
  final String id;

  /// 评论与帖子绑定，方便按帖子维度查询评论列表。
  final String postId;

  /// 评论作者的社区展示信息直接平铺，便于 UI 快速使用。
  final String userId;
  final String userName;
  final String? userAvatarUrl;

  final String content;
  final int likeCount;
  final DateTime createdAt;

  /// 为空表示一级评论；有值表示“回复某条一级评论”。
  final String? parentCommentId;

  /// 回复场景下可直接显示“回复 xxx”，不需要额外再查一次用户名。
  final String? replyToUserName;

  const Comment({
    required this.id,
    required this.postId,
    required this.userId,
    required this.userName,
    required this.userAvatarUrl,
    required this.content,
    required this.likeCount,
    required this.createdAt,
    required this.parentCommentId,
    required this.replyToUserName,
  });

  bool get isReply =>
      parentCommentId != null && parentCommentId!.trim().isNotEmpty;

  bool get isTopLevel => !isReply;
}
