import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// 统一网络图入口：集中处理缓存、比例、日志和占位体验。
class AppNetworkImage extends StatefulWidget {
  const AppNetworkImage({
    super.key,
    required this.imageUrl,
    required this.pageName,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    this.placeholderBuilder,
    this.errorBuilder,
  });

  final String imageUrl;
  final String pageName;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Alignment alignment;
  final WidgetBuilder? placeholderBuilder;
  final Widget Function(BuildContext context, Object error)? errorBuilder;

  @override
  State<AppNetworkImage> createState() => _AppNetworkImageState();
}

class _AppNetworkImageState extends State<AppNetworkImage> {
  Stopwatch _stopwatch = Stopwatch();
  bool _hasLoggedResult = false;
  String _currentUrlHash = '';

  @override
  void initState() {
    super.initState();
    _restartTrace();
  }

  @override
  void didUpdateWidget(covariant AppNetworkImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl.trim() != widget.imageUrl.trim() ||
        oldWidget.pageName != widget.pageName) {
      _restartTrace();
    }
  }

  void _restartTrace() {
    _stopwatch = Stopwatch()..start();
    _hasLoggedResult = false;
    _currentUrlHash = _hashUrl(widget.imageUrl.trim());
    debugPrint(
      '[ImageLoad] start page=${widget.pageName} '
      'urlHash=$_currentUrlHash',
    );
  }

  @override
  Widget build(BuildContext context) {
    final cleanUrl = widget.imageUrl.trim();
    if (cleanUrl.isEmpty) {
      return _buildPlaceholder(context);
    }

    final effectiveFit = _resolveFit(widget.fit);

    return LayoutBuilder(
      builder: (context, constraints) {
        final (cacheWidth, cacheHeight) = _resolveCacheSize(
          context: context,
          constraints: constraints,
        );

        return CachedNetworkImage(
          imageUrl: cleanUrl,
          width: widget.width,
          height: widget.height,
          memCacheWidth: cacheWidth,
          memCacheHeight: cacheHeight,
          maxWidthDiskCache: cacheWidth,
          maxHeightDiskCache: cacheHeight,
          fadeInDuration: const Duration(milliseconds: 120),
          fadeOutDuration: Duration.zero,
          useOldImageOnUrlChange: true,
          imageBuilder: (context, imageProvider) {
            _logLoaded();
            return Image(
              image: imageProvider,
              width: widget.width,
              height: widget.height,
              fit: effectiveFit,
              alignment: widget.alignment,
              filterQuality: FilterQuality.low,
            );
          },
          placeholder: (context, url) => _buildPlaceholder(context),
          errorWidget: (context, url, error) {
            _logError(error);
            final customError = widget.errorBuilder;
            if (customError != null) {
              return customError(context, error);
            }
            return _buildPlaceholder(context);
          },
        );
      },
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    final builder = widget.placeholderBuilder;
    if (builder != null) {
      return builder(context);
    }
    return const SizedBox.shrink();
  }

  BoxFit _resolveFit(BoxFit fit) {
    // 禁止 fill，避免图片被横向拉宽或纵向压扁。
    if (fit == BoxFit.fill) {
      return BoxFit.cover;
    }
    return fit;
  }

  (int?, int?) _resolveCacheSize({
    required BuildContext context,
    required BoxConstraints constraints,
  }) {
    final devicePixelRatio = MediaQuery.maybeDevicePixelRatioOf(context) ?? 1;

    double? logicalWidth = widget.width;
    if ((logicalWidth == null || logicalWidth <= 0) &&
        constraints.maxWidth.isFinite) {
      logicalWidth = constraints.maxWidth;
    }

    double? logicalHeight = widget.height;
    if ((logicalHeight == null || logicalHeight <= 0) &&
        constraints.maxHeight.isFinite) {
      logicalHeight = constraints.maxHeight;
    }

    final cacheWidth = logicalWidth != null && logicalWidth > 0
        ? (logicalWidth * devicePixelRatio).round()
        : null;
    final cacheHeight = logicalHeight != null && logicalHeight > 0
        ? (logicalHeight * devicePixelRatio).round()
        : null;

    return (
      cacheWidth != null && cacheWidth > 0 ? cacheWidth : null,
      cacheHeight != null && cacheHeight > 0 ? cacheHeight : null,
    );
  }

  void _logLoaded() {
    if (_hasLoggedResult) {
      return;
    }
    _hasLoggedResult = true;
    debugPrint(
      '[ImageLoad] loaded page=${widget.pageName} '
      'urlHash=$_currentUrlHash '
      'elapsed=${_stopwatch.elapsedMilliseconds}ms',
    );
  }

  void _logError(Object error) {
    if (_hasLoggedResult) {
      return;
    }
    _hasLoggedResult = true;
    debugPrint(
      '[ImageLoad] error=${error.runtimeType} '
      'page=${widget.pageName} '
      'urlHash=$_currentUrlHash '
      'elapsed=${_stopwatch.elapsedMilliseconds}ms',
    );
  }

  String _hashUrl(String value) {
    var hash = 0x811C9DC5;
    for (final codeUnit in value.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * 0x01000193) & 0xFFFFFFFF;
    }
    return hash.toRadixString(16).padLeft(8, '0');
  }
}
