const Object _summarySentinel = Object();

class UserProfileSummary {
  /// 社区用户唯一标识。
  final String uid;

  /// 用户主页、关注列表和帖子作者信息都复用这组基础字段。
  final String nickname;
  final String? avatarUrl;
  final String? bio;

  /// 统计字段按页面最小可用需求保留。
  final int postCount;
  final int followerCount;
  final int followingCount;
  final int totalLikesReceived;

  const UserProfileSummary({
    required this.uid,
    required this.nickname,
    required this.avatarUrl,
    required this.bio,
    required this.postCount,
    required this.followerCount,
    required this.followingCount,
    this.totalLikesReceived = 0,
  });

  bool get hasAvatar => avatarUrl != null && avatarUrl!.trim().isNotEmpty;

  bool get hasBio => bio != null && bio!.trim().isNotEmpty;

  UserProfileSummary copyWith({
    String? uid,
    String? nickname,
    Object? avatarUrl = _summarySentinel,
    Object? bio = _summarySentinel,
    int? postCount,
    int? followerCount,
    int? followingCount,
    int? totalLikesReceived,
  }) {
    return UserProfileSummary(
      uid: uid ?? this.uid,
      nickname: nickname ?? this.nickname,
      avatarUrl: avatarUrl == _summarySentinel
          ? this.avatarUrl
          : avatarUrl as String?,
      bio: bio == _summarySentinel ? this.bio : bio as String?,
      postCount: postCount ?? this.postCount,
      followerCount: followerCount ?? this.followerCount,
      followingCount: followingCount ?? this.followingCount,
      totalLikesReceived: totalLikesReceived ?? this.totalLikesReceived,
    );
  }
}
