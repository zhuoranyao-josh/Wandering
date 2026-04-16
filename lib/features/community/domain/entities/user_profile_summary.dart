class UserProfileSummary {
  /// 社区用户唯一标识，避免与认证模块完整用户实体强耦合。
  final String uid;

  /// 社区昵称与头像用于帖子卡片、评论区和个人主页头部展示。
  final String nickname;
  final String? avatarUrl;

  /// 社区简介与统计信息，后续可直接复用到个人主页。
  final String? bio;
  final int postCount;
  final int followerCount;
  final int followingCount;

  const UserProfileSummary({
    required this.uid,
    required this.nickname,
    required this.avatarUrl,
    required this.bio,
    required this.postCount,
    required this.followerCount,
    required this.followingCount,
  });

  bool get hasAvatar => avatarUrl != null && avatarUrl!.trim().isNotEmpty;

  bool get hasBio => bio != null && bio!.trim().isNotEmpty;
}
