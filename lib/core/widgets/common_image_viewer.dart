import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../cache/app_image_cache_manager.dart';
import 'app_network_image.dart';
import '../../l10n/app_localizations.dart';

enum CommonImageViewerSourceType { network, local, asset }

class CommonImageViewerItem {
  const CommonImageViewerItem._({
    required this.sourceType,
    required this.value,
  });

  final CommonImageViewerSourceType sourceType;
  final String value;

  const CommonImageViewerItem.network(String url)
    : this._(sourceType: CommonImageViewerSourceType.network, value: url);

  const CommonImageViewerItem.local(String localPath)
    : this._(sourceType: CommonImageViewerSourceType.local, value: localPath);

  const CommonImageViewerItem.asset(String assetPath)
    : this._(sourceType: CommonImageViewerSourceType.asset, value: assetPath);

  String get cleanValue => value.trim();

  bool get isEmpty => cleanValue.isEmpty;

  ImageProvider<Object>? buildImageProvider() {
    if (isEmpty) {
      return null;
    }

    switch (sourceType) {
      case CommonImageViewerSourceType.network:
        return CachedNetworkImageProvider(
          cleanValue,
          cacheManager: AppImageCacheManager.instance,
        );
      case CommonImageViewerSourceType.local:
        return FileImage(File(cleanValue));
      case CommonImageViewerSourceType.asset:
        return AssetImage(cleanValue);
    }
  }
}

Future<void> showCommonImageViewer({
  required BuildContext context,
  required List<CommonImageViewerItem> images,
  int initialIndex = 0,
}) {
  if (images.isEmpty) {
    return Future<void>.value();
  }

  final t = AppLocalizations.of(context);
  final safeInitialIndex = initialIndex.clamp(0, images.length - 1);

  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: t?.commonImageViewerClose ?? 'Close',
    barrierColor: const Color(0xF2000000),
    pageBuilder: (context, animation, secondaryAnimation) {
      return CommonImageViewer(images: images, initialIndex: safeInitialIndex);
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(opacity: animation, child: child);
    },
  );
}

class CommonImageViewer extends StatefulWidget {
  const CommonImageViewer({
    super.key,
    required this.images,
    this.initialIndex = 0,
  });

  final List<CommonImageViewerItem> images;
  final int initialIndex;

  @override
  State<CommonImageViewer> createState() => _CommonImageViewerState();
}

class _CommonImageViewerState extends State<CommonImageViewer> {
  late final PageController _pageController;
  late int _currentIndex;
  bool _isCurrentImageZoomed = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, widget.images.length - 1);
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return Material(
      color: Colors.black,
      child: SafeArea(
        child: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              physics: _isCurrentImageZoomed
                  ? const NeverScrollableScrollPhysics()
                  : const PageScrollPhysics(),
              itemCount: widget.images.length,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                  _isCurrentImageZoomed = false;
                });
              },
              itemBuilder: (context, index) {
                return _ZoomableImagePage(
                  image: widget.images[index],
                  onScaleStateChanged: (isZoomed) {
                    if (!mounted || index != _currentIndex) {
                      return;
                    }
                    setState(() {
                      _isCurrentImageZoomed = isZoomed;
                    });
                  },
                );
              },
            ),
            Positioned(
              top: 12,
              left: 16,
              right: 16,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0x66000000),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      t?.commonImageViewerPageLabel(
                            _currentIndex + 1,
                            widget.images.length,
                          ) ??
                          '${_currentIndex + 1} / ${widget.images.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Tooltip(
                    message: t?.commonImageViewerClose,
                    child: Material(
                      color: const Color(0x66000000),
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () {
                          if (context.canPop()) {
                            context.pop();
                          }
                        },
                        child: const Padding(
                          padding: EdgeInsets.all(10),
                          child: Icon(
                            Icons.close_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ZoomableImagePage extends StatefulWidget {
  const _ZoomableImagePage({
    required this.image,
    required this.onScaleStateChanged,
  });

  final CommonImageViewerItem image;
  final ValueChanged<bool> onScaleStateChanged;

  @override
  State<_ZoomableImagePage> createState() => _ZoomableImagePageState();
}

class _ZoomableImagePageState extends State<_ZoomableImagePage> {
  late final TransformationController _transformationController;
  TapDownDetails? _doubleTapDetails;

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        widget.onScaleStateChanged(false);
      }
    });
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  void _handleDoubleTapDown(TapDownDetails details) {
    _doubleTapDetails = details;
  }

  void _handleDoubleTap() {
    final tapPosition = _doubleTapDetails?.localPosition;
    if (tapPosition == null) {
      return;
    }

    if (_isIdentityMatrix(_transformationController.value)) {
      const scale = 2.5;
      _transformationController.value = Matrix4.identity()
        ..translateByDouble(
          -tapPosition.dx * (scale - 1),
          -tapPosition.dy * (scale - 1),
          0,
          1,
        )
        ..scaleByDouble(scale, scale, 1, 1);
      widget.onScaleStateChanged(true);
      return;
    }

    _transformationController.value = Matrix4.identity();
    widget.onScaleStateChanged(false);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTapDown: _handleDoubleTapDown,
      onDoubleTap: _handleDoubleTap,
      child: InteractiveViewer(
        transformationController: _transformationController,
        minScale: 1,
        maxScale: 4,
        boundaryMargin: const EdgeInsets.all(80),
        onInteractionEnd: (_) {
          widget.onScaleStateChanged(
            !_isIdentityMatrix(_transformationController.value),
          );
        },
        child: Center(child: _buildPreviewImage()),
      ),
    );
  }

  Widget _buildPreviewImage() {
    final image = widget.image;
    if (image.sourceType == CommonImageViewerSourceType.network) {
      if (image.isEmpty) {
        return _buildPlaceholder();
      }
      // 全屏预览只允许完整展示图片，不能裁剪，也不能拉伸。
      return AppNetworkImage(
        imageUrl: image.cleanValue,
        pageName: 'common.imageViewer',
        fit: BoxFit.contain,
        placeholderBuilder: (context) => _buildPlaceholder(),
        errorBuilder: (context, error) => _buildPlaceholder(),
      );
    }

    final imageProvider = image.buildImageProvider();
    if (imageProvider == null) {
      return _buildPlaceholder();
    }

    return Image(
      image: imageProvider,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return _buildPlaceholder();
      },
    );
  }

  Widget _buildPlaceholder() {
    return const Icon(
      Icons.broken_image_outlined,
      size: 48,
      color: Color(0xFF94A3B8),
    );
  }

  bool _isIdentityMatrix(Matrix4 matrix) {
    final storage = matrix.storage;
    const identity = <double>[1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1];

    for (var index = 0; index < storage.length; index++) {
      if ((storage[index] - identity[index]).abs() > 0.001) {
        return false;
      }
    }
    return true;
  }
}
