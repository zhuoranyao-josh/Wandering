import 'post_image.dart';

class Post {
  final String id;

  /// 作者信息单独平铺，方便列表页直接展示，后续也能平滑过渡到 summary 实体。
  final String authorId;
  final String authorName;
  final String? authorAvatarUrl;

  /// 标题允许为空，适配“只有正文”的轻量帖子。
  final String? title;
  final String content;

  /// 图片预留为列表，便于从单图扩展到多图。
  final List<PostImage> images;

  /// 地点信息可为空，附近帖子等功能可按需使用经纬度。
  final String? placeName;
  final double? latitude;
  final double? longitude;

  /// 互动计数与创建时间是社区列表、详情页的基础展示字段。
  final int likeCount;
  final int commentCount;
  final DateTime createdAt;

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
}
