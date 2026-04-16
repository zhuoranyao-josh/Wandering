import 'post_image.dart';

const Object _postSentinel = Object();

class Post {
  final String id;

  /// 作者信息单独平铺，方便列表页和详情页直接展示。
  final String authorId;
  final String authorName;
  final String? authorAvatarUrl;

  /// 标题允许为空，兼容轻量帖子。
  final String? title;
  final String content;

  /// 图片保留为数组，便于后续扩展多图布局。
  final List<PostImage> images;

  /// 地点信息可为空，当前仅用于展示。
  final String? placeName;
  final double? latitude;
  final double? longitude;

  /// 点赞、评论计数与当前用户点赞状态用于社区列表和详情页。
  final int likeCount;
  final int commentCount;
  final DateTime createdAt;
  final bool isLikedByCurrentUser;

  const Post({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.authorAvatarUrl,
    this.title,
    required this.content,
    this.images = const <PostImage>[],
    required this.placeName,
    required this.latitude,
    required this.longitude,
    required this.likeCount,
    required this.commentCount,
    required this.createdAt,
    this.isLikedByCurrentUser = false,
  });

  bool get hasTitle => title != null && title!.trim().isNotEmpty;

  bool get hasImages => images.isNotEmpty;

  String? get coverImageUrl {
    if (!hasImages) {
      return null;
    }
    return images.first.url;
  }

  bool get isSingleImage => images.length == 1;

  bool get isMultiImage => images.length > 1;

  bool get hasLocation =>
      placeName != null || latitude != null || longitude != null;

  Post copyWith({
    String? id,
    String? authorId,
    String? authorName,
    String? authorAvatarUrl,
    Object? title = _postSentinel,
    String? content,
    List<PostImage>? images,
    Object? placeName = _postSentinel,
    Object? latitude = _postSentinel,
    Object? longitude = _postSentinel,
    int? likeCount,
    int? commentCount,
    DateTime? createdAt,
    bool? isLikedByCurrentUser,
  }) {
    return Post(
      id: id ?? this.id,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      authorAvatarUrl: authorAvatarUrl ?? this.authorAvatarUrl,
      title: title == _postSentinel ? this.title : title as String?,
      content: content ?? this.content,
      images: images ?? this.images,
      placeName: placeName == _postSentinel
          ? this.placeName
          : placeName as String?,
      latitude: latitude == _postSentinel ? this.latitude : latitude as double?,
      longitude: longitude == _postSentinel
          ? this.longitude
          : longitude as double?,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      createdAt: createdAt ?? this.createdAt,
      isLikedByCurrentUser: isLikedByCurrentUser ?? this.isLikedByCurrentUser,
    );
  }
}
