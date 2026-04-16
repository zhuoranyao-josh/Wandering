import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/error/app_exception.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../l10n/app_localizations.dart';
import '../controllers/community_controller.dart';

class CreatePostPage extends StatefulWidget {
  const CreatePostPage({super.key});

  @override
  State<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  late final CommunityController _controller;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _contentController = TextEditingController();
    _controller = ServiceLocator.communityController;
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
                          // 发帖表单只接入本次最小可用字段，图片和地点按钮先保留 UI。
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
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _controller.isSubmitting
                                      ? null
                                      : () {},
                                  icon: const Icon(Icons.image_outlined),
                                  label: Text(t.communityCreatePostAddImage),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _controller.isSubmitting
                                      ? null
                                      : () {},
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
