import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/error/app_exception.dart';
import '../../domain/entities/comment.dart';
import '../../domain/entities/post.dart';
import '../../domain/entities/post_image.dart';
import 'community_remote_data_source.dart';

class FirebaseCommunityRemoteDataSource implements CommunityRemoteDataSource {
  final FirebaseFirestore firestore;

  FirebaseCommunityRemoteDataSource({required this.firestore});

  @override
  Future<List<Post>> getLatestPosts({int? limit}) async {
    try {
      Query<Map<String, dynamic>> query = firestore
          .collection('posts')
          .orderBy('createdAt', descending: true);

      if (limit != null) {
        query = query.limit(limit);
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => _mapDocToPost(doc.id, doc.data()))
          .toList(growable: false);
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

      return _mapDocToPost(doc.id, data);
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
        // 使用服务端时间，保证排序稳定。
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
      final batch = firestore.batch();
      batch.set(commentRef, <String, dynamic>{
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
      batch.update(firestore.collection('posts').doc(postId), <String, dynamic>{
        'commentCount': FieldValue.increment(1),
      });
      await batch.commit();

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
      final batch = firestore.batch();
      batch.set(commentRef, <String, dynamic>{
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
      batch.update(firestore.collection('posts').doc(postId), <String, dynamic>{
        'commentCount': FieldValue.increment(1),
      });
      await batch.commit();

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

  CollectionReference<Map<String, dynamic>> _commentsCollection(String postId) {
    return firestore.collection('posts').doc(postId).collection('comments');
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
}
