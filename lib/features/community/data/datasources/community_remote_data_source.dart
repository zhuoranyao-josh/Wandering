import '../../domain/entities/comment.dart';
import '../../domain/entities/post.dart';
import '../../domain/entities/post_location.dart';
import '../../domain/entities/user_profile_summary.dart';

abstract class CommunityRemoteDataSource {
  Future<List<Post>> getLatestPosts({int? limit});

  Future<List<Post>> getTrendingPosts({int? limit});

  Future<List<Post>> getFollowingPosts({required String userId, int? limit});

  Future<Post?> getPostById(String postId);

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

  Future<List<PostLocation>> searchLocations({
    required String query,
    required String sessionToken,
  });

  Future<PostLocation> retrieveLocation(PostLocation suggestion);

  Future<void> deletePost({required String postId, required String userId});

  Future<List<Comment>> getCommentsByPostId(String postId, {int? limit});

  Future<Comment> addComment({
    required String postId,
    required String userId,
    required String userName,
    String? userAvatarUrl,
    required String content,
  });

  Future<Comment> replyToComment({
    required String postId,
    required String parentCommentId,
    required String userId,
    required String userName,
    String? userAvatarUrl,
    required String content,
    String? replyToUserName,
  });

  Future<void> deleteComment({
    required String postId,
    required String commentId,
    required String userId,
  });

  Future<void> likePost({required String postId, required String userId});

  Future<void> unlikePost({required String postId, required String userId});

  Future<UserProfileSummary?> getUserProfileSummary(String userId);

  Future<List<Post>> getPostsByUserId(String userId, {int? limit});

  Future<void> followUser({
    required String currentUserId,
    required String targetUserId,
  });

  Future<void> unfollowUser({
    required String currentUserId,
    required String targetUserId,
  });

  Future<List<UserProfileSummary>> getFollowingUsers(String userId);

  Future<bool> isFollowingUser({
    required String currentUserId,
    required String targetUserId,
  });
}
