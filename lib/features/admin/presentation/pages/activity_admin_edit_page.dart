import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/admin_activity.dart';
import '../controllers/admin_activity_edit_controller.dart';
import '../widgets/admin_section_card.dart';

class ActivityAdminEditPage extends StatefulWidget {
  const ActivityAdminEditPage({super.key, required this.activityId});

  final String activityId;

  bool get isCreating => activityId == 'new';

  @override
  State<ActivityAdminEditPage> createState() => _ActivityAdminEditPageState();
}

class _ActivityAdminEditPageState extends State<ActivityAdminEditPage> {
  late final AdminActivityEditController _controller =
      AdminActivityEditController(repository: ServiceLocator.adminRepository);

  final TextEditingController _idController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _cityNameController = TextEditingController();
  final TextEditingController _countryNameController = TextEditingController();
  final TextEditingController _cityCodeController = TextEditingController();
  final TextEditingController _placeIdController = TextEditingController();
  final TextEditingController _coverImageController = TextEditingController();
  final TextEditingController _startAtController = TextEditingController();
  final TextEditingController _endAtController = TextEditingController();
  final TextEditingController _detailController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  bool _isPublished = true;
  bool _isFeatured = false;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_handleControllerChange);
    if (widget.isCreating) {
      _initialized = true;
    } else {
      _controller.load(widget.activityId);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_handleControllerChange);
    _controller.dispose();
    _idController.dispose();
    _titleController.dispose();
    _categoryController.dispose();
    _cityNameController.dispose();
    _countryNameController.dispose();
    _cityCodeController.dispose();
    _placeIdController.dispose();
    _coverImageController.dispose();
    _startAtController.dispose();
    _endAtController.dispose();
    _detailController.dispose();
    super.dispose();
  }

  void _handleControllerChange() {
    if (!_initialized && _controller.activity != null) {
      _bindFromActivity(_controller.activity!);
      _initialized = true;
    }
    if (!mounted) return;
    final t = AppLocalizations.of(context);
    if (t == null) return;
    final key = _controller.errorKey;
    if (key == 'adminLoadFailed') {
      _showSnack(t.adminLoadFailed);
    } else if (key == 'adminSaveFailed') {
      _showSnack(t.adminSaveFailed);
    } else if (key == 'adminDeleteFailed') {
      _showSnack(t.adminDeleteFailed);
    } else if (key == 'adminImageUploadFailed') {
      _showSnack(t.adminImageUploadFailed);
    }
  }

  void _bindFromActivity(AdminActivity activity) {
    _idController.text = activity.id;
    _titleController.text = activity.title;
    _categoryController.text = activity.category;
    _cityNameController.text = activity.cityName;
    _countryNameController.text = activity.countryName;
    _cityCodeController.text = activity.cityCode;
    _placeIdController.text = activity.placeId ?? '';
    _coverImageController.text = activity.coverImageUrl;
    _startAtController.text = activity.startAt?.toIso8601String() ?? '';
    _endAtController.text = activity.endAt?.toIso8601String() ?? '';
    _detailController.text = activity.detailText;
    _isPublished = activity.isPublished;
    _isFeatured = activity.isFeatured;
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  DateTime? _parseDateTime(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    return DateTime.tryParse(trimmed);
  }

  AdminActivity _buildDraft() {
    return AdminActivity(
      id: _idController.text.trim(),
      title: _titleController.text.trim(),
      category: _categoryController.text.trim(),
      cityName: _cityNameController.text.trim(),
      countryName: _countryNameController.text.trim(),
      cityCode: _cityCodeController.text.trim(),
      coverImageUrl: _coverImageController.text.trim(),
      startAt: _parseDateTime(_startAtController.text),
      endAt: _parseDateTime(_endAtController.text),
      isPublished: _isPublished,
      isFeatured: _isFeatured,
      detailText: _detailController.text.trim(),
      placeId: _placeIdController.text.trim().isEmpty
          ? null
          : _placeIdController.text.trim(),
    );
  }

  Future<void> _save(AppLocalizations t) async {
    final savedId = await _controller.save(_buildDraft());
    if (savedId == null || !mounted) return;
    _showSnack(t.save);
    if (widget.isCreating) {
      context.pop();
    }
  }

  Future<void> _delete(AppLocalizations t) async {
    if (widget.isCreating) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(t.adminDeleteConfirmTitle),
          content: Text(t.adminDeleteConfirmMessage),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(t.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(t.communityDeleteAction),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) return;
    final success = await _controller.delete(widget.activityId);
    if (success && mounted) {
      context.pop();
    }
  }

  Future<void> _pickAndUploadCoverImage(AppLocalizations t) async {
    final picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked == null) {
      return;
    }

    final url = await _controller.uploadCoverImage(
      localPath: picked.path,
      activityIdHint: _idController.text.trim().isEmpty
          ? null
          : _idController.text.trim(),
    );
    if (!mounted || url == null) {
      return;
    }
    setState(() {
      _coverImageController.text = url;
    });
    _showSnack(t.adminImageUploadSuccess);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    if (t == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isCreating ? t.adminCreateActivity : t.adminActivityEditTitle,
        ),
        actions: <Widget>[
          if (!widget.isCreating)
            IconButton(
              onPressed: _controller.isDeleting ? null : () => _delete(t),
              icon: const Icon(Icons.delete_outline),
            ),
        ],
      ),
      backgroundColor: const Color(0xFFF6F7FB),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          if (_controller.isLoading && !_initialized) {
            return const Center(child: CircularProgressIndicator());
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              AdminSectionCard(
                title: t.adminBasicInfo,
                child: Column(
                  children: <Widget>[
                    TextField(
                      controller: _idController,
                      readOnly: !widget.isCreating,
                      decoration: InputDecoration(
                        labelText: t.uidLabel,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        labelText: t.adminTitle,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _categoryController,
                      decoration: InputDecoration(
                        labelText: t.adminCategory,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _cityNameController,
                      decoration: InputDecoration(
                        labelText: t.adminCityName,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _countryNameController,
                      decoration: InputDecoration(
                        labelText: t.adminCountryName,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _cityCodeController,
                      decoration: InputDecoration(
                        labelText: t.adminCityCode,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _placeIdController,
                      decoration: InputDecoration(
                        labelText: t.adminPlaceId,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              AdminSectionCard(
                title: t.adminSchedule,
                child: Column(
                  children: <Widget>[
                    TextField(
                      controller: _startAtController,
                      decoration: InputDecoration(
                        labelText: t.adminStartAtIso,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _endAtController,
                      decoration: InputDecoration(
                        labelText: t.adminEndAtIso,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _isPublished,
                      title: Text(
                        _isPublished ? t.adminEnabled : t.adminDisabled,
                      ),
                      onChanged: (value) =>
                          setState(() => _isPublished = value),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _isFeatured,
                      title: Text(t.adminFeatured),
                      onChanged: (value) => setState(() => _isFeatured = value),
                    ),
                  ],
                ),
              ),
              AdminSectionCard(
                title: t.adminPreviewCard,
                child: _buildImageUrlEditor(
                  t: t,
                  controller: _coverImageController,
                  label: t.adminCoverImageUrl,
                  onUpload: () => _pickAndUploadCoverImage(t),
                  isUploading: _controller.isUploadingImage,
                ),
              ),
              AdminSectionCard(
                title: t.adminPlaceDetails,
                child: TextField(
                  controller: _detailController,
                  minLines: 4,
                  maxLines: 8,
                  decoration: InputDecoration(
                    labelText: t.adminDetailText,
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: ElevatedButton(
            onPressed: _controller.isSaving ? null : () => _save(t),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
            ),
            child: _controller.isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(t.save),
          ),
        ),
      ),
    );
  }

  Widget _buildImageUrlEditor({
    required AppLocalizations t,
    required TextEditingController controller,
    required String label,
    required VoidCallback onUpload,
    required bool isUploading,
  }) {
    return Column(
      children: <Widget>[
        TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            onPressed: isUploading ? null : onUpload,
            icon: isUploading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.upload_file_outlined),
            label: Text(
              isUploading ? t.adminUploadingImage : t.adminUploadImage,
            ),
          ),
        ),
      ],
    );
  }
}
