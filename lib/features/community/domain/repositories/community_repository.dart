import '../entities/comment.dart';
import '../entities/post.dart';
import '../entities/post_location.dart';
import '../entities/user_profile_summary.dart';

abstract class CommunityRepository {
  /// 获取最新帖子列表。
  Future<List<Post>> getLatestPosts({int? limit});

  /// 获取热门帖子列表。
  Future<List<Post>> getTrendingPosts({int? limit});

  /// 获取当前用户关注的人发布的帖子。
  Future<List<Post>> getFollowingPosts({required String userId, int? limit});

  /// 附近帖子当前仍未接真实链路，先保留接口。
  Future<List<Post>> getNearbyPosts({
    required double latitude,
    required double longitude,
    double? radiusInKm,
    int? limit,
  });

  /// 根据帖子 ID 获取详情页所需的完整帖子信息。
  Future<Post?> getPostById(String postId);

  /// 创建帖子并返回保存后的帖子。
  Future<Post> createPost({
    required String authorId,
    required String authorName,
    String? authorAvatarUrl,
    String? title,
    required String content,
    List<String> imageLocalPaths = const <String>[],
    String? placeName,
    String? placeNameFull,
    String? placeCity,
    String? placeCountry,
    String? placeType,
    double? latitude,
    double? longitude,
  });

  /// 使用 Search Box suggest 获取候选地点。
  Future<List<PostLocation>> searchLocations({
    required String query,
    required String sessionToken,
  });

  /// 用户点击候选项后，再通过 retrieve 换取完整地点详情。
  Future<PostLocation> retrieveLocation(PostLocation suggestion);

  /// 删除当前用户自己发布的帖子。
  Future<void> deletePost({required String postId, required String userId});

  /// 帖子点赞与取消点赞。
  Future<void> likePost({required String postId, required String userId});

  Future<void> unlikePost({required String postId, required String userId});

  /// 获取某条帖子下的评论列表。
  Future<List<Comment>> getCommentsByPostId(String postId, {int? limit});

  /// 添加一级评论。
  Future<Comment> addComment({
    required String postId,
    required String userId,
    required String userName,
    String? userAvatarUrl,
    required String content,
  });

  /// 回复一级评论。
  Future<Comment> replyToComment({
    required String postId,
    required String parentCommentId,
    required String userId,
    required String userName,
    String? userAvatarUrl,
    required String content,
    String? replyToUserName,
  });

  /// 删除当前用户自己的评论；一级评论会连同其回复一起移除。
  Future<void> deleteComment({
    required String postId,
    required String commentId,
    required String userId,
  });

  /// 评论点赞能力暂未接入真实链路，先保留接口。
  Future<void> likeComment({required String commentId, required String userId});

  Future<void> unlikeComment({
    required String commentId,
    required String userId,
  });

  /// 获取社区用户摘要资料。
  Future<UserProfileSummary?> getUserProfileSummary(String userId);

  /// 获取指定用户发布的帖子列表。
  Future<List<Post>> getPostsByUserId(String userId, {int? limit});

  /// 关注与取消关注指定用户。
  Future<void> followUser({
    required String currentUserId,
    required String targetUserId,
  });

  Future<void> unfollowUser({
    required String currentUserId,
    required String targetUserId,
  });

  /// 获取用户关注列表与关注状态。
  Future<List<UserProfileSummary>> getFollowingUsers(String userId);

  Future<bool> isFollowingUser({
    required String currentUserId,
    required String targetUserId,
  });
}
