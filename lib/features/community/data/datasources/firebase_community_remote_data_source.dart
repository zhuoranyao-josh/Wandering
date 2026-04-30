// ignore_for_file: unused_element

import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/config/mapbox_config.dart';
import '../../../../core/error/app_exception.dart';
import '../../domain/entities/comment.dart';
import '../../domain/entities/post.dart';
import '../../domain/entities/post_image.dart';
import '../../domain/entities/post_location.dart';
import '../../domain/entities/user_profile_summary.dart';
import 'community_remote_data_source.dart';

class FirebaseCommunityRemoteDataSource implements CommunityRemoteDataSource {
  final FirebaseFirestore firestore;
  final FirebaseAuth firebaseAuth;
  final FirebaseStorage storage;

  FirebaseCommunityRemoteDataSource({
    required this.firestore,
    required this.firebaseAuth,
    required this.storage,
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
      return _attachLikeSnapshot(posts);
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
      return _attachLikeSnapshot(visiblePosts);
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
      return _attachLikeSnapshot(visiblePosts);
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

      return _withLikeSnapshot(_mapDocToPost(doc.id, data));
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
    List<String> imageLocalPaths = const <String>[],
    String? placeName,
    String? placeNameFull,
    String? placeCity,
    String? placeCountry,
    String? placeType,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final now = DateTime.now();
      final docRef = firestore.collection('posts').doc();
      final cleanTitle = _normalizeNullableText(title);
      final cleanContent = content.trim();
      final cleanPlaceName = _normalizeNullableText(placeName);
      final cleanPlaceNameFull = _normalizeNullableText(
        placeNameFull ?? placeName,
      );
      final cleanPlaceCity = _normalizeNullableText(placeCity);
      final cleanPlaceCountry = _normalizeNullableText(placeCountry);
      final cleanPlaceType = _normalizeNullableText(placeType);
      // 先上传图片，再把下载地址写进帖子文档，保证 images 中都是可访问 URL。
      final uploadedImages = await _uploadPostImages(
        authorId: authorId,
        postId: docRef.id,
        imageLocalPaths: imageLocalPaths,
      );

      await docRef.set(<String, dynamic>{
        'authorId': authorId,
        'authorName': authorName.trim(),
        'authorAvatarUrl': _normalizeNullableText(authorAvatarUrl),
        'title': cleanTitle,
        'content': cleanContent,
        'images': uploadedImages.map(_mapImageToJson).toList(growable: false),
        'placeName': cleanPlaceNameFull ?? cleanPlaceName,
        'placeNameFull': cleanPlaceNameFull,
        'placeCity': cleanPlaceCity,
        'placeCountry': cleanPlaceCountry,
        'placeType': cleanPlaceType,
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
        images: uploadedImages,
        placeName: cleanPlaceNameFull ?? cleanPlaceName,
        placeNameFull: cleanPlaceNameFull,
        placeCity: cleanPlaceCity,
        placeCountry: cleanPlaceCountry,
        placeType: cleanPlaceType,
        latitude: latitude,
        longitude: longitude,
        likeCount: 0,
        commentCount: 0,
        createdAt: now,
        isLikedByCurrentUser: false,
      );
    } catch (error, stackTrace) {
      _logCreatePostError(
        message: 'Community createPost failed.',
        error: error,
        stackTrace: stackTrace,
      );
      if (error is AppException) {
        rethrow;
      }
      throw AppException('community_publish_failed');
    }
  }

  @override
  Future<List<PostLocation>> searchLocations({
    required String query,
    required String sessionToken,
  }) async {
    final cleanQuery = query.trim();
    final cleanSessionToken = sessionToken.trim();
    if (cleanQuery.isEmpty) {
      return const <PostLocation>[];
    }

    if (!MapboxConfig.hasAccessToken || cleanSessionToken.isEmpty) {
      throw AppException('community_location_search_failed');
    }

    final uri = Uri.https(
      'api.mapbox.com',
      '/search/searchbox/v1/suggest',
      <String, String>{
        'q': cleanQuery,
        'access_token': MapboxConfig.accessToken,
        'session_token': cleanSessionToken,
        // 兼容中英文关键词输入，优先中文但允许英文地名检索。
        'language': 'zh,en',
        // 让结果覆盖 POI / 地址 / 城市，避免被单一 street 结果主导。
        'types': 'poi,address,place,locality,district,region,country',
        'limit': '5',
      },
    );

    HttpClient? client;
    try {
      client = HttpClient();
      final request = await client.getUrl(uri);
      final response = await request.close();
      final payload = await response.transform(utf8.decoder).join();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw AppException('community_location_search_failed');
      }

      final json = jsonDecode(payload);
      if (json is! Map<String, dynamic>) {
        throw AppException('community_location_search_failed');
      }

      final rawSuggestions = json['suggestions'];
      if (rawSuggestions is! List) {
        return const <PostLocation>[];
      }

      final suggestions = rawSuggestions
          .whereType<Map<dynamic, dynamic>>()
          .map(
            (item) => _mapJsonToSearchSuggestion(
              Map<String, dynamic>.from(item),
              sessionToken: cleanSessionToken,
            ),
          )
          .where((location) => location.hasValue)
          .toList(growable: false);

      // 对建议结果做轻量排序与去重：优先 POI/城市，地址结果作为补充。
      return _normalizeSearchSuggestions(
        suggestions: suggestions,
        query: cleanQuery,
      );
    } catch (error, stackTrace) {
      _logCreatePostError(
        message: 'Community searchLocations failed.',
        error: error,
        stackTrace: stackTrace,
      );
      if (error is AppException) {
        rethrow;
      }
      throw AppException('community_location_search_failed');
    } finally {
      client?.close(force: true);
    }
  }

  @override
  Future<PostLocation> retrieveLocation(PostLocation suggestion) async {
    final mapboxId = suggestion.mapboxId?.trim();
    final sessionToken = suggestion.sessionToken?.trim();
    if (mapboxId == null ||
        mapboxId.isEmpty ||
        sessionToken == null ||
        sessionToken.isEmpty ||
        !MapboxConfig.hasAccessToken) {
      throw AppException('community_location_search_failed');
    }

    final encodedMapboxId = Uri.encodeComponent(mapboxId);
    final uri = Uri.https(
      'api.mapbox.com',
      '/search/searchbox/v1/retrieve/$encodedMapboxId',
      <String, String>{
        'access_token': MapboxConfig.accessToken,
        'session_token': sessionToken,
        'language': 'zh,en',
      },
    );

    HttpClient? client;
    try {
      client = HttpClient();
      final request = await client.getUrl(uri);
      final response = await request.close();
      final payload = await response.transform(utf8.decoder).join();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw AppException('community_location_search_failed');
      }

      final json = jsonDecode(payload);
      if (json is! Map<String, dynamic>) {
        throw AppException('community_location_search_failed');
      }

      final rawFeatures = json['features'];
      if (rawFeatures is! List || rawFeatures.isEmpty) {
        throw AppException('community_location_search_failed');
      }

      final firstFeature = rawFeatures.first;
      if (firstFeature is! Map) {
        throw AppException('community_location_search_failed');
      }

      return _mapJsonToRetrievedLocation(
        Map<String, dynamic>.from(firstFeature),
        fallback: suggestion,
      );
    } catch (error, stackTrace) {
      _logCreatePostError(
        message: 'Community retrieveLocation failed.',
        error: error,
        stackTrace: stackTrace,
      );
      if (error is AppException) {
        rethrow;
      }
      throw AppException('community_location_search_failed');
    } finally {
      client?.close(force: true);
    }
  }

  @override
  Future<void> deletePost({
    required String postId,
    required String userId,
  }) async {
    try {
      _assertCurrentUser(userId, errorCode: 'community_delete_post_failed');

      final postRef = firestore.collection('posts').doc(postId);
      final postDoc = await postRef.get();
      final postData = postDoc.data();
      if (!postDoc.exists || postData == null) {
        throw AppException('community_delete_post_failed');
      }

      final authorId = (postData['authorId'] as String?)?.trim();
      if (authorId == null || authorId != userId) {
        throw AppException('community_delete_post_failed');
      }

      final post = _mapDocToPost(postDoc.id, postData);
      final commentsSnapshot = await _commentsCollection(postId).get();
      final likesSnapshot = await _likesCollection(postId).get();

      await _deletePostImages(post.images);

      for (final doc in likesSnapshot.docs) {
        await doc.reference.delete();
      }
      for (final doc in commentsSnapshot.docs) {
        await doc.reference.delete();
      }

      await postRef.delete();
    } catch (error, stackTrace) {
      _logCreatePostError(
        message: 'Community deletePost failed.',
        error: error,
        stackTrace: stackTrace,
      );
      if (error is AppException) {
        rethrow;
      }
      throw AppException('community_delete_post_failed');
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
  Future<void> deleteComment({
    required String postId,
    required String commentId,
    required String userId,
  }) async {
    try {
      _assertCurrentUser(userId, errorCode: 'community_delete_comment_failed');

      final commentRef = _commentsCollection(postId).doc(commentId);
      final commentDoc = await commentRef.get();
      final commentData = commentDoc.data();
      if (!commentDoc.exists || commentData == null) {
        throw AppException('community_delete_comment_failed');
      }

      final commentOwnerId = (commentData['userId'] as String?)?.trim();
      if (commentOwnerId == null || commentOwnerId != userId) {
        throw AppException('community_delete_comment_failed');
      }

      // 一级评论删除时，把挂在它下面的回复一起删掉，避免留下孤儿回复。
      final repliesSnapshot = await _commentsCollection(
        postId,
      ).where('parentCommentId', isEqualTo: commentId).get();

      for (final replyDoc in repliesSnapshot.docs) {
        await replyDoc.reference.delete();
      }
      await commentRef.delete();
    } catch (error, stackTrace) {
      _logCreatePostError(
        message: 'Community deleteComment failed.',
        error: error,
        stackTrace: stackTrace,
      );
      if (error is AppException) {
        rethrow;
      }
      throw AppException('community_delete_comment_failed');
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
      return _attachLikeSnapshot(posts);
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

  Future<List<Post>> _attachLikeSnapshot(List<Post> posts) async {
    if (posts.isEmpty) {
      return const <Post>[];
    }

    // 这里统一以 likes 子集合为准，避免仅依赖 posts.likeCount 导致重进后计数回 0。
    return Future.wait(posts.map(_withLikeSnapshot));
  }

  Future<Post> _withLikeSnapshot(Post post) async {
    final currentUserId = firebaseAuth.currentUser?.uid;
    try {
      final likesSnapshot = await _likesCollection(post.id).get();
      final likeCount = likesSnapshot.size;
      final isLikedByCurrentUser =
          currentUserId != null &&
          currentUserId.trim().isNotEmpty &&
          likesSnapshot.docs.any((doc) => doc.id == currentUserId);

      return post.copyWith(
        likeCount: likeCount,
        isLikedByCurrentUser: isLikedByCurrentUser,
      );
    } catch (_) {
      // 某条帖子点赞子集合读取失败时，兜底保留原值，避免整页加载失败。
      return post.copyWith(isLikedByCurrentUser: false);
    }
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
        placeNameFull:
            _normalizeNullableText(data['placeNameFull']) ??
            _normalizeNullableText(data['placeName']),
        placeCity: _normalizeNullableText(data['placeCity']),
        placeCountry: _normalizeNullableText(data['placeCountry']),
        placeType: _normalizeNullableText(data['placeType']),
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

  PostLocation _mapJsonToPostLocation(Map<String, dynamic> json) {
    final fullName = _normalizeNullableText(json['place_name']);
    final placeText = _normalizeNullableText(json['text']);
    final context = json['context'];
    final placeTypes = _readStringList(json['place_type']);
    final center = json['center'];

    return PostLocation(
      fullName: fullName ?? placeText,
      // Mapbox 的 text 通常就是本次匹配到的主名称，这里优先作为城市展示。
      city:
          placeText ??
          _findContextText(
            context: context,
            prefixes: const <String>['place', 'locality', 'district', 'region'],
          ),
      country:
          _findContextText(
            context: context,
            prefixes: const <String>['country'],
          ) ??
          (placeTypes.contains('country') ? placeText : null),
      latitude: _readCoordinate(center, 1),
      longitude: _readCoordinate(center, 0),
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

  double? _readCoordinate(dynamic value, int index) {
    if (value is! List || value.length <= index) {
      return null;
    }
    return _readDouble(value[index]);
  }

  List<String> _readStringList(dynamic value) {
    if (value is! List) {
      return const <String>[];
    }
    return value
        .whereType<String>()
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }

  String? _findContextText({
    required dynamic context,
    required List<String> prefixes,
  }) {
    if (context is! List) {
      return null;
    }

    for (final item in context) {
      if (item is! Map) {
        continue;
      }
      final typedItem = Map<String, dynamic>.from(item);
      final rawId = _normalizeNullableText(typedItem['id']);
      if (rawId == null) {
        continue;
      }

      final matchesPrefix = prefixes.any((prefix) => rawId.startsWith(prefix));
      if (!matchesPrefix) {
        continue;
      }

      final text = _normalizeNullableText(typedItem['text']);
      if (text != null) {
        return text;
      }
    }
    return null;
  }

  PostLocation _mapJsonToSearchSuggestion(
    Map<String, dynamic> json, {
    required String sessionToken,
  }) {
    final name = _normalizeNullableText(json['name']);
    final formatted = _normalizeNullableText(json['place_formatted']);
    final rawFeatureType = _normalizeNullableText(json['feature_type']);
    return PostLocation(
      fullName: name,
      city: _cityFromFormatted(formatted),
      country: _countryFromFormatted(formatted),
      latitude: null,
      longitude: null,
      placeType: _canonicalPlaceType(rawFeatureType),
      placeFormatted: formatted,
      mapboxId: _normalizeNullableText(json['mapbox_id']),
      sessionToken: sessionToken,
    );
  }

  PostLocation _mapJsonToRetrievedLocation(
    Map<String, dynamic> json, {
    required PostLocation fallback,
  }) {
    final properties = _readMap(json['properties']);
    final coordinates = _readMap(properties?['coordinates']);
    final name =
        _normalizeNullableText(json['name']) ??
        _normalizeNullableText(properties?['name']) ??
        fallback.fullName;
    final formatted =
        _normalizeNullableText(json['place_formatted']) ??
        _normalizeNullableText(properties?['place_formatted']) ??
        fallback.placeFormatted;
    final rawFeatureType =
        _normalizeNullableText(json['feature_type']) ?? fallback.placeType;

    return fallback.copyWith(
      fullName: name,
      city: _cityFromFormatted(formatted) ?? fallback.city,
      country: _countryFromFormatted(formatted) ?? fallback.country,
      latitude: _readCoordinatesLatitude(coordinates) ?? fallback.latitude,
      longitude: _readCoordinatesLongitude(coordinates) ?? fallback.longitude,
      placeType: _canonicalPlaceType(rawFeatureType),
      placeFormatted: formatted,
    );
  }

  Map<String, dynamic>? _readMap(dynamic value) {
    if (value is! Map) {
      return null;
    }
    return Map<String, dynamic>.from(value);
  }

  double? _readCoordinatesLatitude(Map<String, dynamic>? coordinates) {
    if (coordinates == null) {
      return null;
    }
    return _readDouble(coordinates['latitude'] ?? coordinates['lat']);
  }

  double? _readCoordinatesLongitude(Map<String, dynamic>? coordinates) {
    if (coordinates == null) {
      return null;
    }
    return _readDouble(coordinates['longitude'] ?? coordinates['lng']);
  }

  String? _countryFromFormatted(String? formatted) {
    final segments = _splitFormattedSegments(formatted);
    if (segments.isEmpty) {
      return null;
    }
    return segments.last;
  }

  String? _cityFromFormatted(String? formatted) {
    final segments = _splitFormattedSegments(formatted);
    if (segments.isEmpty) {
      return null;
    }
    if (segments.length == 1) {
      return segments.first;
    }
    return segments[segments.length - 2];
  }

  List<String> _splitFormattedSegments(String? formatted) {
    if (formatted == null) {
      return const <String>[];
    }
    return formatted
        .split(RegExp(r'[,，]'))
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }

  List<PostLocation> _normalizeSearchSuggestions({
    required List<PostLocation> suggestions,
    required String query,
  }) {
    if (suggestions.isEmpty) {
      return const <PostLocation>[];
    }

    final queryLower = query.trim().toLowerCase();
    final unique = <String, PostLocation>{};
    for (final location in suggestions) {
      final key = [
        location.mapboxId?.trim() ?? '',
        location.fullName?.trim() ?? '',
        location.placeFormatted?.trim() ?? '',
      ].join('|');
      unique.putIfAbsent(key, () => location);
    }

    final ranked = unique.values.toList(growable: false)
      ..sort((left, right) {
        final leftKeyword = _keywordScore(left, queryLower);
        final rightKeyword = _keywordScore(right, queryLower);
        if (leftKeyword != rightKeyword) {
          return rightKeyword.compareTo(leftKeyword);
        }

        final leftPriority = _placeTypePriority(left.placeType);
        final rightPriority = _placeTypePriority(right.placeType);
        if (leftPriority != rightPriority) {
          return leftPriority.compareTo(rightPriority);
        }

        final leftName = left.fullName?.trim() ?? '';
        final rightName = right.fullName?.trim() ?? '';
        return leftName.compareTo(rightName);
      });

    final hasPoiOrCity = ranked.any(
      (location) => _placeTypePriority(location.placeType) <= 1,
    );
    if (!hasPoiOrCity) {
      return ranked.take(5).toList(growable: false);
    }

    final filtered = ranked
        .where(
          (location) =>
              _placeTypePriority(location.placeType) <= 1 ||
              _keywordScore(location, queryLower) >= 3,
        )
        .toList(growable: false);
    final finalList = filtered.isEmpty ? ranked : filtered;
    return finalList.take(5).toList(growable: false);
  }

  int _keywordScore(PostLocation location, String queryLower) {
    if (queryLower.isEmpty) {
      return 0;
    }
    final fullName = location.fullName?.toLowerCase() ?? '';
    final formatted = location.placeFormatted?.toLowerCase() ?? '';

    if (fullName == queryLower) {
      return 5;
    }
    if (fullName.startsWith(queryLower)) {
      return 4;
    }
    if (fullName.contains(queryLower)) {
      return 3;
    }
    if (formatted.startsWith(queryLower)) {
      return 2;
    }
    if (formatted.contains(queryLower)) {
      return 1;
    }
    return 0;
  }

  int _placeTypePriority(String? placeType) {
    final type = placeType?.trim().toLowerCase();
    switch (type) {
      case 'poi':
        return 0;
      case 'city':
        return 1;
      default:
        return 2;
    }
  }

  String? _canonicalPlaceType(String? rawType) {
    final type = rawType?.trim().toLowerCase();
    switch (type) {
      case 'place':
      case 'locality':
      case 'district':
      case 'region':
      case 'country':
      case 'neighborhood':
        return 'city';
      case 'poi':
      case 'address':
      case 'street':
      case 'block':
      case 'postcode':
      case 'category':
        return 'poi';
      default:
        return type;
    }
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

  Future<List<PostImage>> _uploadPostImages({
    required String authorId,
    required String postId,
    required List<String> imageLocalPaths,
  }) async {
    final cleanPaths = imageLocalPaths
        .map((path) => path.trim())
        .where((path) => path.isNotEmpty)
        .toList(growable: false);
    if (cleanPaths.isEmpty) {
      return const <PostImage>[];
    }

    final uploadedImages = <PostImage>[];
    for (var index = 0; index < cleanPaths.length; index++) {
      final localPath = cleanPaths[index];
      final file = File(localPath);

      try {
        if (!await file.exists()) {
          throw AppException('community_publish_failed');
        }

        final storageRef = storage
            .ref()
            .child('community')
            .child('posts')
            .child(authorId)
            .child(postId)
            .child(
              'image_${DateTime.now().microsecondsSinceEpoch}_$index${_resolveImageExtension(localPath)}',
            );

        await storageRef.putFile(file);
        final imageUrl = await storageRef.getDownloadURL();
        uploadedImages.add(PostImage(url: imageUrl));
      } catch (error, stackTrace) {
        _logCreatePostError(
          message: 'Community post image upload failed.',
          error: error,
          stackTrace: stackTrace,
        );
        if (error is AppException) {
          rethrow;
        }
        throw AppException('community_publish_failed');
      }
    }

    return uploadedImages;
  }

  Future<void> _deletePostImages(List<PostImage> images) async {
    for (final image in images) {
      final cleanUrl = image.url.trim();
      if (cleanUrl.isEmpty || cleanUrl.startsWith('assets/')) {
        continue;
      }
      await storage.refFromURL(cleanUrl).delete();
    }
  }

  String _resolveImageExtension(String localPath) {
    final dotIndex = localPath.lastIndexOf('.');
    if (dotIndex == -1 || dotIndex == localPath.length - 1) {
      return '.jpg';
    }

    final extension = localPath.substring(dotIndex).trim().toLowerCase();
    if (extension.length > 10) {
      return '.jpg';
    }
    return extension;
  }

  void _logCreatePostError({
    required String message,
    required Object error,
    StackTrace? stackTrace,
  }) {
    debugPrint('$message $error');
    if (stackTrace != null) {
      debugPrintStack(stackTrace: stackTrace);
    }
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
