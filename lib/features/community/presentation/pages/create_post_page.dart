import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../app/app_router.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/error/app_exception.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/common_image_viewer.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/post_location.dart';
import '../controllers/community_controller.dart';

const int _maxPostImageCount = 20;

class CreatePostPage extends StatefulWidget {
  const CreatePostPage({super.key});

  @override
  State<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  late final CommunityController _controller;
  late final ImagePicker _imagePicker;
  List<String> _selectedImagePaths = <String>[];
  PostLocation? _selectedLocation;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _contentController = TextEditingController();
    _controller = ServiceLocator.communityController;
    _imagePicker = ImagePicker();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _submitPost(AppLocalizations t) async {
    try {
      await _controller.createPost(
        title: _titleController.text,
        content: _contentController.text,
        imageLocalPaths: _selectedImagePaths,
        placeNameFull: _selectedLocation?.fullName,
        placeCity: _selectedLocation?.city,
        placeCountry: _selectedLocation?.country,
        placeType: _selectedLocation?.placeType,
        latitude: _selectedLocation?.latitude,
        longitude: _selectedLocation?.longitude,
      );

      if (!mounted) return;
      context.pop();
    } catch (error) {
      if (!mounted) return;

      final message = _messageForError(error: error, t: t);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _pickImages(AppLocalizations t) async {
    try {
      final pickedImages = await _imagePicker.pickMultiImage(imageQuality: 85);
      if (pickedImages.isEmpty || !mounted) {
        return;
      }

      // 多次选择时继续追加，但整个帖子最多保留 20 张。
      final mergedImagePaths = <String>[
        ..._selectedImagePaths,
        ...pickedImages.map((file) => file.path),
      ];
      final limitedImagePaths = mergedImagePaths
          .take(_maxPostImageCount)
          .toList(growable: false);

      setState(() {
        _selectedImagePaths = limitedImagePaths;
      });

      if (mergedImagePaths.length > _maxPostImageCount) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              t.communityCreatePostImageLimitReached(_maxPostImageCount),
            ),
          ),
        );
      }
    } catch (error, stackTrace) {
      debugPrint('CreatePostPage pick images failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t.errorUnknown)));
    }
  }

  Future<void> _pickLocation() async {
    final selectedLocation = await context.push<PostLocation>(
      AppRouter.communityLocationSearch(),
    );
    if (!mounted || selectedLocation == null) {
      return;
    }

    setState(() {
      _selectedLocation = selectedLocation;
    });
  }

  void _clearSelectedLocation() {
    setState(() {
      _selectedLocation = null;
    });
  }

  void _removeSelectedImageAt(int index) {
    if (index < 0 || index >= _selectedImagePaths.length) {
      return;
    }

    setState(() {
      _selectedImagePaths = List<String>.from(_selectedImagePaths)
        ..removeAt(index);
    });
  }

  Future<void> _openSelectedImages(int initialIndex) {
    final images = _selectedImagePaths
        .where((path) => path.trim().isNotEmpty)
        .map(CommonImageViewerItem.local)
        .toList(growable: false);
    return showCommonImageViewer(
      context: context,
      images: images,
      initialIndex: initialIndex,
    );
  }

  String _messageForError({
    required Object error,
    required AppLocalizations t,
  }) {
    if (error is AppException) {
      switch (error.code) {
        case 'community_content_empty':
          return t.communityContentEmpty;
        case 'community_publish_failed':
          return t.communityPublishFailed;
      }
    }
    return t.errorUnknown;
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    if (t == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(title: Text(t.communityCreatePostTitle)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 发帖表单继续保持最小字段集合，图片和地点都在页面预览，
                          // 真正提交统一走 controller -> repository -> remote data source。
                          _FormSectionLabel(
                            text: t.communityCreatePostTitleOptional,
                          ),
                          const SizedBox(height: 8),
                          _FormTextField(
                            controller: _titleController,
                            hintText: t.communityCreatePostTitleHint,
                          ),
                          const SizedBox(height: 20),
                          _FormSectionLabel(
                            text: t.communityCreatePostContentRequired,
                          ),
                          const SizedBox(height: 8),
                          _FormTextField(
                            controller: _contentController,
                            hintText: t.communityCreatePostContentHint,
                            maxLines: 8,
                            minLines: 6,
                          ),
                          if (_selectedImagePaths.isNotEmpty) ...[
                            const SizedBox(height: 20),
                            // 只有选中图片后才显示预览区，避免空状态占空间。
                            IgnorePointer(
                              ignoring: _controller.isSubmitting,
                              child: _SelectedImagePreviewSection(
                                imagePaths: _selectedImagePaths,
                                title: t.communityCreatePostSelectedImages(
                                  _selectedImagePaths.length,
                                  _maxPostImageCount,
                                ),
                                removeTooltip: t.communityCreatePostRemoveImage,
                                onRemoveAt: _removeSelectedImageAt,
                                onImageTap: _openSelectedImages,
                              ),
                            ),
                          ],
                          if (_selectedLocation != null) ...[
                            const SizedBox(height: 20),
                            IgnorePointer(
                              ignoring: _controller.isSubmitting,
                              child: _SelectedLocationSection(
                                locationLabel:
                                    _selectedLocation?.summaryLabel ??
                                    _selectedLocation?.fullLabel ??
                                    '',
                                removeTooltip:
                                    t.communityCreatePostRemoveLocation,
                                onRemove: _clearSelectedLocation,
                              ),
                            ),
                          ],
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _controller.isSubmitting
                                      ? null
                                      : () => _pickImages(t),
                                  icon: const Icon(Icons.image_outlined),
                                  label: Text(t.communityCreatePostAddImage),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _controller.isSubmitting
                                      ? null
                                      : _pickLocation,
                                  icon: const Icon(Icons.place_outlined),
                                  label: Text(t.communityCreatePostAddLocation),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  AppButton(
                    text: t.communityCreatePostSubmit,
                    onPressed: _controller.isSubmitting
                        ? null
                        : () => _submitPost(t),
                    isLoading: _controller.isSubmitting,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _SelectedImagePreviewSection extends StatelessWidget {
  const _SelectedImagePreviewSection({
    required this.imagePaths,
    required this.title,
    required this.removeTooltip,
    required this.onRemoveAt,
    required this.onImageTap,
  });

  final List<String> imagePaths;
  final String title;
  final String removeTooltip;
  final ValueChanged<int> onRemoveAt;
  final ValueChanged<int> onImageTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: imagePaths.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1,
          ),
          itemBuilder: (context, index) {
            return _SelectedImageGridItem(
              imagePath: imagePaths[index],
              removeTooltip: removeTooltip,
              onTap: () => onImageTap(index),
              onRemove: () => onRemoveAt(index),
            );
          },
        ),
      ],
    );
  }
}

class _SelectedLocationSection extends StatelessWidget {
  const _SelectedLocationSection({
    required this.locationLabel,
    required this.removeTooltip,
    required this.onRemove,
  });

  final String locationLabel;
  final String removeTooltip;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.place_rounded, size: 18, color: Color(0xFFDC2626)),
          const SizedBox(width: 8),
          Expanded(
            // 发帖页预览只展示“国家 · 城市”，保持信息简洁。
            child: Text(
              locationLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF334155),
              ),
            ),
          ),
          IconButton(
            onPressed: onRemove,
            tooltip: removeTooltip,
            visualDensity: VisualDensity.compact,
            icon: const Icon(
              Icons.close_rounded,
              size: 18,
              color: Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectedImageGridItem extends StatelessWidget {
  const _SelectedImageGridItem({
    required this.imagePath,
    required this.removeTooltip,
    required this.onTap,
    required this.onRemove,
  });

  final String imagePath;
  final String removeTooltip;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: AspectRatio(
            aspectRatio: 1,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // 网格中的每张图都固定成正方形，并使用 cover 裁切铺满。
                Image.file(
                  File(imagePath),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: const Color(0xFFE2E8F0),
                      child: const Center(
                        child: Icon(
                          Icons.broken_image_outlined,
                          size: 32,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    );
                  },
                ),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x260F172A), Color(0x000F172A)],
                    ),
                  ),
                ),
                Positioned(
                  top: 6,
                  right: 6,
                  child: Tooltip(
                    message: removeTooltip,
                    child: Material(
                      color: const Color(0x990F172A),
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: onRemove,
                        child: const Padding(
                          padding: EdgeInsets.all(6),
                          child: Icon(
                            Icons.close_rounded,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FormSectionLabel extends StatelessWidget {
  const _FormSectionLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: Color(0xFF111827),
      ),
    );
  }
}

class _FormTextField extends StatelessWidget {
  const _FormTextField({
    required this.controller,
    required this.hintText,
    this.maxLines = 1,
    this.minLines,
  });

  final TextEditingController controller;
  final String hintText;
  final int maxLines;
  final int? minLines;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      minLines: minLines,
      decoration: InputDecoration(
        hintText: hintText,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
