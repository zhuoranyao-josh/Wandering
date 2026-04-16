import '../../domain/entities/comment.dart';
import '../../domain/entities/post.dart';
import '../../domain/entities/post_image.dart';
import '../../domain/entities/user_profile_summary.dart';
import '../../domain/repositories/community_repository.dart';
import '../datasources/community_remote_data_source.dart';

class CommunityRepositoryImpl implements CommunityRepository {
  final CommunityRemoteDataSource remoteDataSource;

  CommunityRepositoryImpl(this.remoteDataSource);

  @override
  Future<List<Post>> getLatestPosts({int? limit}) {
    return remoteDataSource.getLatestPosts(limit: limit);
  }

  @override
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
  }) {
    return remoteDataSource.createPost(
      authorId: authorId,
      authorName: authorName,
      authorAvatarUrl: authorAvatarUrl,
      title: title,
      content: content,
      images: images,
      placeName: placeName,
      latitude: latitude,
      longitude: longitude,
    );
  }

  @override
  Future<List<Post>> getTrendingPosts({int? limit}) {
    return remoteDataSource.getTrendingPosts(limit: limit);
  }

  @override
  Future<List<Post>> getFollowingPosts({required String userId, int? limit}) {
    return remoteDataSource.getFollowingPosts(userId: userId, limit: limit);
  }

  @override
  Future<List<Post>> getNearbyPosts({
    required double latitude,
    required double longitude,
    double? radiusInKm,
    int? limit,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<Post?> getPostById(String postId) {
    return remoteDataSource.getPostById(postId);
  }

  @override
  Future<void> likePost({required String postId, required String userId}) {
    return remoteDataSource.likePost(postId: postId, userId: userId);
  }

  @override
  Future<void> unlikePost({required String postId, required String userId}) {
    return remoteDataSource.unlikePost(postId: postId, userId: userId);
  }

  @override
  Future<List<Comment>> getCommentsByPostId(String postId, {int? limit}) {
    return remoteDataSource.getCommentsByPostId(postId, limit: limit);
  }

  @override
  Future<Comment> addComment({
    required String postId,
    required String userId,
    required String userName,
    String? userAvatarUrl,
    required String content,
  }) {
    return remoteDataSource.addComment(
      postId: postId,
      userId: userId,
      userName: userName,
      userAvatarUrl: userAvatarUrl,
      content: content,
    );
  }

  @override
  Future<Comment> replyToComment({
    required String postId,
    required String parentCommentId,
    required String userId,
    required String userName,
    String? userAvatarUrl,
    required String content,
    String? replyToUserName,
  }) {
    return remoteDataSource.replyToComment(
      postId: postId,
      parentCommentId: parentCommentId,
      userId: userId,
      userName: userName,
      userAvatarUrl: userAvatarUrl,
      content: content,
      replyToUserName: replyToUserName,
    );
  }

  @override
  Future<void> likeComment({
    required String commentId,
    required String userId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> unlikeComment({
    required String commentId,
    required String userId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<UserProfileSummary?> getUserProfileSummary(String userId) {
    return remoteDataSource.getUserProfileSummary(userId);
  }

  @override
  Future<List<Post>> getPostsByUserId(String userId, {int? limit}) {
    return remoteDataSource.getPostsByUserId(userId, limit: limit);
  }

  @override
  Future<void> followUser({
    required String currentUserId,
    required String targetUserId,
  }) {
    return remoteDataSource.followUser(
      currentUserId: currentUserId,
      targetUserId: targetUserId,
    );
  }

  @override
  Future<void> unfollowUser({
    required String currentUserId,
    required String targetUserId,
  }) {
    return remoteDataSource.unfollowUser(
      currentUserId: currentUserId,
      targetUserId: targetUserId,
    );
  }

  @override
  Future<List<UserProfileSummary>> getFollowingUsers(String userId) {
    return remoteDataSource.getFollowingUsers(userId);
  }

  @override
  Future<bool> isFollowingUser({
    required String currentUserId,
    required String targetUserId,
  }) {
    return remoteDataSource.isFollowingUser(
      currentUserId: currentUserId,
      targetUserId: targetUserId,
    );
  }
}
