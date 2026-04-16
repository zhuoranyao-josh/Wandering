import '../entities/comment.dart';
import '../entities/post.dart';
import '../entities/post_image.dart';
import '../entities/user_profile_summary.dart';

abstract class CommunityRepository {
  /// 获取最新帖子列表，后续可扩展分页和过滤条件。
  Future<List<Post>> getLatestPosts({int? limit});

  /// 获取热门帖子列表，通常用于按热度排序的社区首页。
  Future<List<Post>> getTrendingPosts({int? limit});

  /// 获取当前用户关注的人发布的帖子。
  Future<List<Post>> getFollowingPosts({required String userId, int? limit});

  /// 获取附近帖子列表，后续可对接地理检索能力。
  Future<List<Post>> getNearbyPosts({
    required double latitude,
    required double longitude,
    double? radiusInKm,
    int? limit,
  });

  /// 根据帖子 ID 获取详情页所需的完整帖子信息。
  Future<Post?> getPostById(String postId);

  /// 创建帖子，返回保存后的帖子结构，方便后续立即刷新 UI。
  Future<Post> createPost({
    required String authorId,
    required String authorName,
    String? authorAvatarUrl,
    String? title,
    required String content,
    List<PostImage> images = const <PostImage>[],
    String? placeName,
    double? latitude,
    double? longitude,
  });

  /// 帖子点赞与取消点赞接口，避免在 UI 层感知底层实现细节。
  Future<void> likePost({required String postId, required String userId});

  Future<void> unlikePost({required String postId, required String userId});

  /// 获取某条帖子下的评论列表，包含一级评论与一级回复。
  Future<List<Comment>> getCommentsByPostId(String postId, {int? limit});

  /// 添加一级评论。
  Future<Comment> addComment({
    required String postId,
    required String userId,
    required String userName,
    String? userAvatarUrl,
    required String content,
  });

  /// 回复一级评论，不支持无限嵌套树结构。
  Future<Comment> replyToComment({
    required String postId,
    required String parentCommentId,
    required String userId,
    required String userName,
    String? userAvatarUrl,
    required String content,
    String? replyToUserName,
  });

  /// 评论点赞与取消点赞接口。
  Future<void> likeComment({required String commentId, required String userId});

  Future<void> unlikeComment({
    required String commentId,
    required String userId,
  });

  /// 获取社区用户简要资料，用于头像跳转和用户主页展示。
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
}
