import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/error/app_exception.dart';
import '../../domain/entities/comment.dart';
import '../../domain/entities/post.dart';
import '../../domain/entities/post_image.dart';
import '../../domain/entities/user_profile_summary.dart';
import 'community_remote_data_source.dart';

class FirebaseCommunityRemoteDataSource implements CommunityRemoteDataSource {
  final FirebaseFirestore firestore;
  final FirebaseAuth firebaseAuth;

  FirebaseCommunityRemoteDataSource({
    required this.firestore,
    required this.firebaseAuth,
  });

  @override
  Future<List<Post>> getLatestPosts({int? limit}) async {
    try {
      Query<Map<String, dynamic>> query = firestore.collection('posts');
      if (limit != null) {
        query = query.limit(limit);
      }

      final snapshot = await query.get();
      final posts = snapshot.docs
          .map((doc) => _mapDocToPost(doc.id, doc.data()))
          .toList(growable: false);
      posts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return _attachLikeState(posts);
    } catch (_) {
      throw AppException('community_load_failed');
    }
  }

  @override
  Future<List<Post>> getTrendingPosts({int? limit}) async {
    try {
      Query<Map<String, dynamic>> query = firestore.collection('posts');
      if (limit != null) {
        query = query.limit(math.max(limit * 2, limit));
      }

      final snapshot = await query.get();
      final posts = snapshot.docs
          .map((doc) => _mapDocToPost(doc.id, doc.data()))
          .toList(growable: false);
      posts.sort((a, b) {
        final likeCompare = b.likeCount.compareTo(a.likeCount);
        if (likeCompare != 0) {
          return likeCompare;
        }
        final commentCompare = b.commentCount.compareTo(a.commentCount);
        if (commentCompare != 0) {
          return commentCompare;
        }
        return b.createdAt.compareTo(a.createdAt);
      });
      final visiblePosts = limit == null
          ? posts
          : posts.take(limit).toList(growable: false);
      return _attachLikeState(visiblePosts);
    } catch (_) {
      throw AppException('community_load_failed');
    }
  }

  @override
  Future<List<Post>> getFollowingPosts({
    required String userId,
    int? limit,
  }) async {
    try {
      final followingSnapshot = await _followingCollection(userId).get();
      final followingIds = followingSnapshot.docs
          .map((doc) => doc.id.trim())
          .where((id) => id.isNotEmpty)
          .toSet()
          .toList(growable: false);

      if (followingIds.isEmpty) {
        return const <Post>[];
      }

      final posts = <Post>[];
      for (final chunk in _chunkedStrings(followingIds, 10)) {
        final snapshot = await firestore
            .collection('posts')
            .where('authorId', whereIn: chunk)
            .get();
        posts.addAll(
          snapshot.docs.map((doc) => _mapDocToPost(doc.id, doc.data())),
        );
      }

      final deduplicatedPosts = <String, Post>{};
      for (final post in posts) {
        deduplicatedPosts[post.id] = post;
      }

      final sortedPosts = deduplicatedPosts.values.toList(growable: false)
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      final visiblePosts = limit == null
          ? sortedPosts
          : sortedPosts.take(limit).toList(growable: false);
      return _attachLikeState(visiblePosts);
    } catch (_) {
      throw AppException('community_load_failed');
    }
  }

  @override
  Future<Post?> getPostById(String postId) async {
    try {
      final doc = await firestore.collection('posts').doc(postId).get();
      if (!doc.exists) {
        return null;
      }

      final data = doc.data();
      if (data == null) {
        return null;
      }

      return _withLikeState(_mapDocToPost(doc.id, data));
    } catch (_) {
      throw AppException('community_load_failed');
    }
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
  }) async {
    try {
      final now = DateTime.now();
      final docRef = firestore.collection('posts').doc();
      final cleanTitle = _normalizeNullableText(title);
      final cleanContent = content.trim();
      final cleanPlaceName = _normalizeNullableText(placeName);

      await docRef.set(<String, dynamic>{
        'authorId': authorId,
        'authorName': authorName.trim(),
        'authorAvatarUrl': _normalizeNullableText(authorAvatarUrl),
        'title': cleanTitle,
        'content': cleanContent,
        'images': images.map(_mapImageToJson).toList(growable: false),
        'placeName': cleanPlaceName,
        'latitude': latitude,
        'longitude': longitude,
        'likeCount': 0,
        'commentCount': 0,
        // 使用服务端时间，保证帖子排序稳定。
        'createdAt': FieldValue.serverTimestamp(),
      });

      return Post(
        id: docRef.id,
        authorId: authorId,
        authorName: authorName.trim(),
        authorAvatarUrl: _normalizeNullableText(authorAvatarUrl),
        title: cleanTitle,
        content: cleanContent,
        images: images,
        placeName: cleanPlaceName,
        latitude: latitude,
        longitude: longitude,
        likeCount: 0,
        commentCount: 0,
        createdAt: now,
        isLikedByCurrentUser: false,
      );
    } catch (_) {
      throw AppException('community_publish_failed');
    }
  }

  @override
  Future<List<Comment>> getCommentsByPostId(String postId, {int? limit}) async {
    try {
      Query<Map<String, dynamic>> query = _commentsCollection(
        postId,
      ).orderBy('createdAt', descending: false);

      if (limit != null) {
        query = query.limit(limit);
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => _mapDocToComment(doc.id, doc.data()))
          .toList(growable: false);
    } catch (_) {
      throw AppException('community_load_failed');
    }
  }

  @override
  Future<Comment> addComment({
    required String postId,
    required String userId,
    required String userName,
    String? userAvatarUrl,
    required String content,
  }) async {
    final now = DateTime.now();
    final commentRef = _commentsCollection(postId).doc();
    final cleanContent = content.trim();

    try {
      // 评论计数由 Cloud Functions 维护，客户端只写评论文档。
      await commentRef.set(<String, dynamic>{
        'postId': postId,
        'userId': userId,
        'userName': userName.trim(),
        'userAvatarUrl': _normalizeNullableText(userAvatarUrl),
        'content': cleanContent,
        'likeCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'parentCommentId': null,
        'replyToUserName': null,
      });

      return Comment(
        id: commentRef.id,
        postId: postId,
        userId: userId,
        userName: userName.trim(),
        userAvatarUrl: _normalizeNullableText(userAvatarUrl),
        content: cleanContent,
        likeCount: 0,
        createdAt: now,
        parentCommentId: null,
        replyToUserName: null,
      );
    } catch (_) {
      throw AppException('community_comment_submit_failed');
    }
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
  }) async {
    final now = DateTime.now();
    final commentRef = _commentsCollection(postId).doc();
    final cleanContent = content.trim();

    try {
      // 回复同样只写 comments 子集合，commentCount 交给函数同步。
      await commentRef.set(<String, dynamic>{
        'postId': postId,
        'userId': userId,
        'userName': userName.trim(),
        'userAvatarUrl': _normalizeNullableText(userAvatarUrl),
        'content': cleanContent,
        'likeCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'parentCommentId': parentCommentId,
        'replyToUserName': _normalizeNullableText(replyToUserName),
      });

      return Comment(
        id: commentRef.id,
        postId: postId,
        userId: userId,
        userName: userName.trim(),
        userAvatarUrl: _normalizeNullableText(userAvatarUrl),
        content: cleanContent,
        likeCount: 0,
        createdAt: now,
        parentCommentId: parentCommentId,
        replyToUserName: _normalizeNullableText(replyToUserName),
      );
    } catch (_) {
      throw AppException('community_comment_submit_failed');
    }
  }

  @override
  Future<void> likePost({
    required String postId,
    required String userId,
  }) async {
    try {
      _assertCurrentUser(userId, errorCode: 'community_like_failed');
      await _likesCollection(postId).doc(userId).set(<String, dynamic>{
        'userId': userId,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (error) {
      if (error is AppException) {
        rethrow;
      }
      throw AppException('community_like_failed');
    }
  }

  @override
  Future<void> unlikePost({
    required String postId,
    required String userId,
  }) async {
    try {
      _assertCurrentUser(userId, errorCode: 'community_like_failed');
      await _likesCollection(postId).doc(userId).delete();
    } catch (error) {
      if (error is AppException) {
        rethrow;
      }
      throw AppException('community_like_failed');
    }
  }

  @override
  Future<UserProfileSummary?> getUserProfileSummary(String userId) async {
    try {
      final userDoc = await firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        return null;
      }

      final userData = userDoc.data();
      if (userData == null) {
        return null;
      }

      final postSnapshot = await firestore
          .collection('posts')
          .where('authorId', isEqualTo: userId)
          .get();
      final posts = postSnapshot.docs
          .map((doc) => _mapDocToPost(doc.id, doc.data()))
          .toList(growable: false);
      final totalLikesReceived = posts.fold<int>(
        0,
        (total, post) => total + post.likeCount,
      );

      return _mapDocToUserProfileSummary(
        uid: userId,
        data: userData,
        postCount: posts.length,
        totalLikesReceived: totalLikesReceived,
      );
    } catch (_) {
      throw AppException('community_load_failed');
    }
  }

  @override
  Future<List<Post>> getPostsByUserId(String userId, {int? limit}) async {
    try {
      Query<Map<String, dynamic>> query = firestore
          .collection('posts')
          .where('authorId', isEqualTo: userId);
      if (limit != null) {
        query = query.limit(limit);
      }

      final snapshot = await query.get();
      final posts = snapshot.docs
          .map((doc) => _mapDocToPost(doc.id, doc.data()))
          .toList(growable: false);
      posts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return _attachLikeState(posts);
    } catch (_) {
      throw AppException('community_load_failed');
    }
  }

  @override
  Future<void> followUser({
    required String currentUserId,
    required String targetUserId,
  }) async {
    try {
      _assertCurrentUser(currentUserId, errorCode: 'community_follow_failed');
      if (currentUserId == targetUserId) {
        throw AppException('community_follow_failed');
      }

      await _followingCollection(
        currentUserId,
      ).doc(targetUserId).set(<String, dynamic>{
        'userId': currentUserId,
        'targetUserId': targetUserId,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (error) {
      if (error is AppException) {
        rethrow;
      }
      throw AppException('community_follow_failed');
    }
  }

  @override
  Future<void> unfollowUser({
    required String currentUserId,
    required String targetUserId,
  }) async {
    try {
      _assertCurrentUser(currentUserId, errorCode: 'community_follow_failed');
      if (currentUserId == targetUserId) {
        throw AppException('community_follow_failed');
      }

      await _followingCollection(currentUserId).doc(targetUserId).delete();
    } catch (error) {
      if (error is AppException) {
        rethrow;
      }
      throw AppException('community_follow_failed');
    }
  }

  @override
  Future<List<UserProfileSummary>> getFollowingUsers(String userId) async {
    try {
      final followingSnapshot = await _followingCollection(userId).get();
      final followingIds = followingSnapshot.docs
          .map((doc) => doc.id.trim())
          .where((id) => id.isNotEmpty)
          .toList(growable: false);
      if (followingIds.isEmpty) {
        return const <UserProfileSummary>[];
      }

      final userSnapshots = await Future.wait(
        followingIds.map((targetUserId) {
          return firestore.collection('users').doc(targetUserId).get();
        }),
      );

      final followingUsers = <UserProfileSummary>[];
      for (final doc in userSnapshots) {
        if (!doc.exists) {
          continue;
        }
        final data = doc.data();
        if (data == null) {
          continue;
        }
        followingUsers.add(
          _mapDocToUserProfileSummary(uid: doc.id, data: data),
        );
      }

      followingUsers.sort((a, b) => a.nickname.compareTo(b.nickname));
      return followingUsers;
    } catch (_) {
      throw AppException('community_load_failed');
    }
  }

  @override
  Future<bool> isFollowingUser({
    required String currentUserId,
    required String targetUserId,
  }) async {
    try {
      if (currentUserId.trim().isEmpty || targetUserId.trim().isEmpty) {
        return false;
      }

      final doc = await _followingCollection(
        currentUserId,
      ).doc(targetUserId).get();
      return doc.exists;
    } catch (_) {
      throw AppException('community_load_failed');
    }
  }

  CollectionReference<Map<String, dynamic>> _commentsCollection(String postId) {
    return firestore.collection('posts').doc(postId).collection('comments');
  }

  CollectionReference<Map<String, dynamic>> _likesCollection(String postId) {
    return firestore.collection('posts').doc(postId).collection('likes');
  }

  CollectionReference<Map<String, dynamic>> _followingCollection(
    String userId,
  ) {
    return firestore.collection('users').doc(userId).collection('following');
  }

  Future<List<Post>> _attachLikeState(List<Post> posts) async {
    if (posts.isEmpty) {
      return const <Post>[];
    }

    final currentUserId = firebaseAuth.currentUser?.uid;
    if (currentUserId == null || currentUserId.trim().isEmpty) {
      return posts;
    }

    return Future.wait(posts.map(_withLikeState));
  }

  Future<Post> _withLikeState(Post post) async {
    final currentUserId = firebaseAuth.currentUser?.uid;
    if (currentUserId == null || currentUserId.trim().isEmpty) {
      return post.copyWith(isLikedByCurrentUser: false);
    }

    final likeDoc = await _likesCollection(post.id).doc(currentUserId).get();
    return post.copyWith(isLikedByCurrentUser: likeDoc.exists);
  }

  UserProfileSummary _mapDocToUserProfileSummary({
    required String uid,
    required Map<String, dynamic> data,
    int? postCount,
    int? totalLikesReceived,
  }) {
    final nickname = _normalizeNullableText(data['nickname']);
    return UserProfileSummary(
      uid: uid,
      nickname: nickname ?? uid,
      avatarUrl: _normalizeNullableText(data['avatarUrl']),
      bio: _normalizeNullableText(data['bio']),
      postCount: postCount ?? _readInt(data['postCount']),
      followerCount: _readInt(data['followerCount']),
      followingCount: _readInt(data['followingCount']),
      totalLikesReceived:
          totalLikesReceived ?? _readInt(data['totalLikesReceived']),
    );
  }

  Post _mapDocToPost(String id, Map<String, dynamic> data) {
    try {
      final rawImages = data['images'];
      final images = rawImages is List
          ? rawImages
                .whereType<Map<dynamic, dynamic>>()
                .map((item) => _mapJsonToImage(Map<String, dynamic>.from(item)))
                .toList(growable: false)
          : const <PostImage>[];

      return Post(
        id: id,
        authorId: (data['authorId'] as String?)?.trim() ?? '',
        authorName: (data['authorName'] as String?)?.trim() ?? '',
        authorAvatarUrl: _normalizeNullableText(data['authorAvatarUrl']),
        title: _normalizeNullableText(data['title']),
        content: (data['content'] as String?)?.trim() ?? '',
        images: images,
        placeName: _normalizeNullableText(data['placeName']),
        latitude: _readDouble(data['latitude']),
        longitude: _readDouble(data['longitude']),
        likeCount: _readInt(data['likeCount']),
        commentCount: _readInt(data['commentCount']),
        createdAt:
            _readDateTime(data['createdAt']) ??
            DateTime.fromMillisecondsSinceEpoch(0),
      );
    } catch (_) {
      throw AppException('community_load_failed');
    }
  }

  Comment _mapDocToComment(String id, Map<String, dynamic> data) {
    try {
      return Comment(
        id: id,
        postId: (data['postId'] as String?)?.trim() ?? '',
        userId: (data['userId'] as String?)?.trim() ?? '',
        userName: (data['userName'] as String?)?.trim() ?? '',
        userAvatarUrl: _normalizeNullableText(data['userAvatarUrl']),
        content: (data['content'] as String?)?.trim() ?? '',
        likeCount: _readInt(data['likeCount']),
        createdAt:
            _readDateTime(data['createdAt']) ??
            DateTime.fromMillisecondsSinceEpoch(0),
        parentCommentId: _normalizeNullableText(data['parentCommentId']),
        replyToUserName: _normalizeNullableText(data['replyToUserName']),
      );
    } catch (_) {
      throw AppException('community_load_failed');
    }
  }

  void _assertCurrentUser(String expectedUserId, {required String errorCode}) {
    final currentUserId = firebaseAuth.currentUser?.uid;
    if (currentUserId == null || currentUserId != expectedUserId) {
      throw AppException(errorCode);
    }
  }

  Map<String, dynamic> _mapImageToJson(PostImage image) {
    return <String, dynamic>{
      'url': image.url.trim(),
      'width': image.width,
      'height': image.height,
    };
  }

  PostImage _mapJsonToImage(Map<String, dynamic> json) {
    return PostImage(
      url: (json['url'] as String?)?.trim() ?? '',
      width: _readDouble(json['width']),
      height: _readDouble(json['height']),
    );
  }

  String? _normalizeNullableText(dynamic value) {
    if (value is! String) {
      return null;
    }
    final cleanValue = value.trim();
    return cleanValue.isEmpty ? null : cleanValue;
  }

  int _readInt(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return 0;
  }

  double? _readDouble(dynamic value) {
    if (value is double) {
      return value;
    }
    if (value is int) {
      return value.toDouble();
    }
    if (value is num) {
      return value.toDouble();
    }
    return null;
  }

  DateTime? _readDateTime(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is DateTime) {
      return value;
    }
    if (value is String) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  List<List<String>> _chunkedStrings(List<String> values, int chunkSize) {
    final chunks = <List<String>>[];
    for (var index = 0; index < values.length; index += chunkSize) {
      final end = math.min(index + chunkSize, values.length);
      chunks.add(values.sublist(index, end));
    }
    return chunks;
  }
}
