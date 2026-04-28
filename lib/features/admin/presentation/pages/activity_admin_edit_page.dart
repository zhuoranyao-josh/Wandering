import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../activity/presentation/support/activity_category.dart';
import '../../domain/entities/admin_activity.dart';
import '../controllers/admin_activity_edit_controller.dart';
import '../widgets/admin_section_card.dart';
import '../widgets/bilingual_text_area_field.dart';
import '../widgets/bilingual_text_field.dart';

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
  final TextEditingController _titleZhController = TextEditingController();
  final TextEditingController _titleEnController = TextEditingController();
  final TextEditingController _cityNameZhController = TextEditingController();
  final TextEditingController _cityNameEnController = TextEditingController();
  final TextEditingController _countryNameZhController = TextEditingController();
  final TextEditingController _countryNameEnController = TextEditingController();
  final TextEditingController _cityCodeController = TextEditingController();
  final TextEditingController _placeIdController = TextEditingController();
  final TextEditingController _coverImageController = TextEditingController();
  final TextEditingController _startAtController = TextEditingController();
  final TextEditingController _endAtController = TextEditingController();
  final TextEditingController _detailZhController = TextEditingController();
  final TextEditingController _detailEnController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  bool _isPublished = true;
  bool _isFeatured = false;
  bool _initialized = false;
  String? _pendingCategory;
  List<String> _selectedCategories = <String>[];
  String? _lastHandledErrorKey;

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
    _titleZhController.dispose();
    _titleEnController.dispose();
    _cityNameZhController.dispose();
    _cityNameEnController.dispose();
    _countryNameZhController.dispose();
    _countryNameEnController.dispose();
    _cityCodeController.dispose();
    _placeIdController.dispose();
    _coverImageController.dispose();
    _startAtController.dispose();
    _endAtController.dispose();
    _detailZhController.dispose();
    _detailEnController.dispose();
    super.dispose();
  }

  void _handleControllerChange() {
    if (!_initialized && _controller.activity != null) {
      _bindFromActivity(_controller.activity!);
      _initialized = true;
    }
    if (!mounted) {
      return;
    }
    final key = _controller.errorKey;
    if (key == null) {
      _lastHandledErrorKey = null;
      return;
    }
    if (key == _lastHandledErrorKey) {
      return;
    }
    _lastHandledErrorKey = key;

    final t = AppLocalizations.of(context);
    if (t == null) {
      return;
    }
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
    _titleZhController.text = activity.title['zh'] ?? '';
    _titleEnController.text = activity.title['en'] ?? '';
    _selectedCategories = activity.categories.toList(growable: false);
    _cityNameZhController.text = activity.cityName['zh'] ?? '';
    _cityNameEnController.text = activity.cityName['en'] ?? '';
    _countryNameZhController.text = activity.countryName['zh'] ?? '';
    _countryNameEnController.text = activity.countryName['en'] ?? '';
    _cityCodeController.text = activity.cityCode;
    _placeIdController.text = activity.placeId ?? '';
    _coverImageController.text = activity.coverImageUrl;
    _startAtController.text = activity.startAt?.toIso8601String() ?? '';
    _endAtController.text = activity.endAt?.toIso8601String() ?? '';
    _detailZhController.text = activity.detailText['zh'] ?? '';
    _detailEnController.text = activity.detailText['en'] ?? '';
    _isPublished = activity.isPublished;
    _isFeatured = activity.isFeatured;
  }

  void _showSnack(String message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
      );
  }

  DateTime? _parseDateTime(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    return DateTime.tryParse(trimmed);
  }

  String _normalizeActivityIdForCreate(String raw) {
    final lower = raw.trim().toLowerCase();
    var normalized = lower.replaceAll(RegExp(r'[^a-z0-9_-]+'), '_');
    normalized = normalized.replaceAll(RegExp(r'_+'), '_');
    normalized = normalized.replaceAll(RegExp(r'^[_-]+|[_-]+$'), '');
    return normalized;
  }

  AdminActivity _buildDraft() {
    final rawId = _idController.text.trim();
    final normalizedId = widget.isCreating
        ? _normalizeActivityIdForCreate(rawId)
        : rawId;
    return AdminActivity(
      id: normalizedId,
      title: <String, String>{
        'zh': _titleZhController.text.trim(),
        'en': _titleEnController.text.trim(),
      },
      categories: _selectedCategories.toList(growable: false),
      cityName: <String, String>{
        'zh': _cityNameZhController.text.trim(),
        'en': _cityNameEnController.text.trim(),
      },
      countryName: <String, String>{
        'zh': _countryNameZhController.text.trim(),
        'en': _countryNameEnController.text.trim(),
      },
      cityCode: _cityCodeController.text.trim(),
      coverImageUrl: _coverImageController.text.trim(),
      startAt: _parseDateTime(_startAtController.text),
      endAt: _parseDateTime(_endAtController.text),
      isPublished: _isPublished,
      isFeatured: _isFeatured,
      detailText: <String, String>{
        'zh': _detailZhController.text.trim(),
        'en': _detailEnController.text.trim(),
      },
      placeId: _placeIdController.text.trim().isEmpty
          ? null
          : _placeIdController.text.trim(),
    );
  }

  Future<void> _save(AppLocalizations t) async {
    final draft = _buildDraft();
    if (widget.isCreating && _idController.text.trim().isNotEmpty) {
      // 创建场景下，UI 直接回填清洗后的 docId，避免管理员误解保存结果。
      _idController.text = draft.id;
    }

    final savedId = await _controller.save(draft);
    if (savedId == null || !mounted) {
      return;
    }
    _showSnack(t.save);
    if (widget.isCreating) {
      context.pop();
    }
  }

  Future<void> _delete(AppLocalizations t) async {
    if (widget.isCreating) {
      return;
    }
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
    if (confirmed != true || !mounted) {
      return;
    }
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

    final rawId = _idController.text.trim();
    final normalizedHint = rawId.isEmpty
        ? null
        : _normalizeActivityIdForCreate(rawId);
    final url = await _controller.uploadCoverImage(
      localPath: picked.path,
      activityIdHint: normalizedHint,
    );
    if (!mounted || url == null) {
      return;
    }
    setState(() {
      _coverImageController.text = url;
    });
    _showSnack(t.adminImageUploadSuccess);
  }

  List<String> _categoryOptions() {
    return ActivityCategories.selectable
        .map((option) => option.key)
        .toList(growable: false);
  }

  String _categoryLabel(String categoryKey, AppLocalizations t) {
    final option = ActivityCategories.fromRawCategory(categoryKey);
    return option?.label(t) ?? categoryKey;
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    if (t == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final categoryOptions = _categoryOptions()
        .where((item) => !_selectedCategories.contains(item))
        .toList(growable: false);

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
                    BilingualTextField(
                      label: t.adminTitle,
                      zhLabel: t.languageChinese,
                      enLabel: t.languageEnglish,
                      zhController: _titleZhController,
                      enController: _titleEnController,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      key: ValueKey<String?>('category-${_pendingCategory ?? ''}'),
                      initialValue: _pendingCategory,
                      items: categoryOptions
                          .map(
                            (category) => DropdownMenuItem<String>(
                              value: category,
                              child: Text(_categoryLabel(category, t)),
                            ),
                          )
                          .toList(growable: false),
                      onChanged: (value) {
                        if (value == null) {
                          return;
                        }
                        setState(() {
                          _selectedCategories = <String>[
                            ..._selectedCategories,
                            value,
                          ];
                          _pendingCategory = null;
                        });
                      },
                      decoration: InputDecoration(
                        labelText: t.adminCategory,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    if (_selectedCategories.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: _selectedCategories
                              .map(
                                (category) => InputChip(
                                  label: Text(_categoryLabel(category, t)),
                                  onDeleted: () {
                                    setState(() {
                                      _selectedCategories = _selectedCategories
                                          .where((item) => item != category)
                                          .toList(growable: false);
                                    });
                                  },
                                ),
                              )
                              .toList(growable: false),
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    BilingualTextField(
                      label: t.adminCityName,
                      zhLabel: t.languageChinese,
                      enLabel: t.languageEnglish,
                      zhController: _cityNameZhController,
                      enController: _cityNameEnController,
                    ),
                    const SizedBox(height: 12),
                    BilingualTextField(
                      label: t.adminCountryName,
                      zhLabel: t.languageChinese,
                      enLabel: t.languageEnglish,
                      zhController: _countryNameZhController,
                      enController: _countryNameEnController,
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
                      onChanged: (value) => setState(() => _isPublished = value),
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
                child: BilingualTextAreaField(
                  label: t.adminDetailText,
                  zhLabel: t.languageChinese,
                  enLabel: t.languageEnglish,
                  zhController: _detailZhController,
                  enController: _detailEnController,
                  minLines: 4,
                  maxLines: 8,
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
