class PostImage {
  /// 帖子图片地址，后续可对接云存储或 CDN。
  final String url;

  /// 图片原始宽高，便于后续做单图/多图布局优化。
  final double? width;
  final double? height;

  const PostImage({required this.url, this.width, this.height});

  bool get hasSize => width != null && height != null;

  double? get aspectRatio {
    if (!hasSize || height == 0) {
      return null;
    }
    return width! / height!;
  }
}
