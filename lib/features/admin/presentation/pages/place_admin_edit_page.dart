import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../app/app_router.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/admin_place.dart';
import '../../domain/entities/admin_subcontent_kind.dart';
import '../controllers/admin_place_edit_controller.dart';
import '../widgets/admin_section_card.dart';
import '../widgets/bilingual_text_area_field.dart';
import '../widgets/bilingual_text_field.dart';

class PlaceAdminEditPage extends StatefulWidget {
  const PlaceAdminEditPage({super.key, required this.placeId});

  final String placeId;

  bool get isCreating => placeId == 'new';

  @override
  State<PlaceAdminEditPage> createState() => _PlaceAdminEditPageState();
}

class _PlaceAdminEditPageState extends State<PlaceAdminEditPage> {
  late final AdminPlaceEditController _controller = AdminPlaceEditController(
    repository: ServiceLocator.adminRepository,
  );

  final TextEditingController _idController = TextEditingController();
  final TextEditingController _nameZhController = TextEditingController();
  final TextEditingController _nameEnController = TextEditingController();
  final TextEditingController _latitudeController = TextEditingController();
  final TextEditingController _longitudeController = TextEditingController();
  final TextEditingController _markerLatitudeController =
      TextEditingController();
  final TextEditingController _markerLongitudeController =
      TextEditingController();
  final TextEditingController _coverImageController = TextEditingController();
  final TextEditingController _flyToZoomController = TextEditingController();
  final TextEditingController _flyToPitchController = TextEditingController();
  final TextEditingController _flyToBearingController = TextEditingController();
  final TextEditingController _quoteZhController = TextEditingController();
  final TextEditingController _quoteEnController = TextEditingController();
  final TextEditingController _shortZhController = TextEditingController();
  final TextEditingController _shortEnController = TextEditingController();
  final TextEditingController _longZhController = TextEditingController();
  final TextEditingController _longEnController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  static const List<String> _defaultTagOptions = <String>[
    'city',
    'official',
    'community',
    'culture',
    'food',
    'shopping',
    'nature',
    'nightlife',
    'family',
  ];
  static const List<String> _defaultMarkerTypeOptions = <String>[
    'official',
    'community',
    'mixed',
  ];
  static final RegExp _lowercaseLettersPattern = RegExp(r'^[a-z_]+$');

  bool _enabled = true;
  String? _markerId;
  String? _selectedRegionId;
  String? _selectedMarkerType;
  List<String> _selectedTags = <String>[];
  String? _pendingTag;
  String? _lastHandledErrorKey;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_handleControllerChange);
    if (widget.isCreating) {
      _initialized = true;
      _selectedMarkerType = 'official';
      _flyToZoomController.text = '10.8';
      _flyToPitchController.text = '48.0';
      _flyToBearingController.text = '12.0';
      _latitudeController.text = '0';
      _longitudeController.text = '0';
      _controller.loadRegions();
    } else {
      _controller.load(widget.placeId);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_handleControllerChange);
    _controller.dispose();
    _idController.dispose();
    _nameZhController.dispose();
    _nameEnController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _markerLatitudeController.dispose();
    _markerLongitudeController.dispose();
    _coverImageController.dispose();
    _flyToZoomController.dispose();
    _flyToPitchController.dispose();
    _flyToBearingController.dispose();
    _quoteZhController.dispose();
    _quoteEnController.dispose();
    _shortZhController.dispose();
    _shortEnController.dispose();
    _longZhController.dispose();
    _longEnController.dispose();
    super.dispose();
  }

  void _handleControllerChange() {
    if (!_initialized && _controller.place != null) {
      _bindFromPlace(_controller.place!);
      _initialized = true;
    }
    if (!mounted) return;
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
    if (t == null) return;
    if (key == 'adminLoadFailed') {
      _showSnack(t.adminLoadFailed);
    } else if (key == 'adminSaveFailed') {
      _showSnack(t.adminSaveFailed);
    } else if (key == 'adminDeleteFailed') {
      _showSnack(t.adminDeleteFailed);
    } else if (key == 'adminImageUploadFailed') {
      _showSnack(t.adminImageUploadFailed);
    } else if (key == 'adminPlaceRegionRequired') {
      _showSnack(t.adminPlaceRegionRequired);
    } else if (key == 'adminPlaceRegionInvalid') {
      _showSnack(t.adminPlaceRegionInvalid);
    }
  }

  void _bindFromPlace(AdminPlace place) {
    _idController.text = place.id;
    _nameZhController.text = place.name['zh'] ?? '';
    _nameEnController.text = place.name['en'] ?? '';
    _selectedRegionId = place.regionId.trim().isEmpty
        ? null
        : place.regionId.trim();
    _latitudeController.text = place.latitude.toString();
    _longitudeController.text = place.longitude.toString();
    _selectedMarkerType = place.markerType.trim().isEmpty
        ? 'official'
        : place.markerType.trim();
    _markerLatitudeController.text = place.markerLatitude?.toString() ?? '';
    _markerLongitudeController.text = place.markerLongitude?.toString() ?? '';
    _coverImageController.text = place.coverImage;
    _selectedTags = place.tags
        .map((tag) => tag.trim())
        .where((tag) => tag.isNotEmpty)
        .toList(growable: false);
    _flyToZoomController.text = place.flyToZoom.toString();
    _flyToPitchController.text = place.flyToPitch.toString();
    _flyToBearingController.text = place.flyToBearing.toString();
    _quoteZhController.text = place.quote['zh'] ?? '';
    _quoteEnController.text = place.quote['en'] ?? '';
    _shortZhController.text = place.shortDescription['zh'] ?? '';
    _shortEnController.text = place.shortDescription['en'] ?? '';
    _longZhController.text = place.longDescription['zh'] ?? '';
    _longEnController.text = place.longDescription['en'] ?? '';
    _enabled = place.enabled;
    _markerId = place.markerId;
  }

  void _showSnack(String message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
      );
  }

  double _parseDouble(String value, double fallback) {
    return double.tryParse(value.trim()) ?? fallback;
  }

  AdminPlace _buildDraft() {
    return AdminPlace(
      id: _idController.text.trim(),
      name: <String, String>{
        'zh': _nameZhController.text.trim(),
        'en': _nameEnController.text.trim(),
      },
      regionId: _selectedRegionId?.trim() ?? '',
      latitude: _parseDouble(_latitudeController.text, 0),
      longitude: _parseDouble(_longitudeController.text, 0),
      coverImage: _coverImageController.text.trim(),
      quote: <String, String>{
        'zh': _quoteZhController.text.trim(),
        'en': _quoteEnController.text.trim(),
      },
      shortDescription: <String, String>{
        'zh': _shortZhController.text.trim(),
        'en': _shortEnController.text.trim(),
      },
      longDescription: <String, String>{
        'zh': _longZhController.text.trim(),
        'en': _longEnController.text.trim(),
      },
      tags: _selectedTags.toList(growable: false),
      flyToZoom: _parseDouble(_flyToZoomController.text, 10.8),
      flyToPitch: _parseDouble(_flyToPitchController.text, 48.0),
      flyToBearing: _parseDouble(_flyToBearingController.text, 12.0),
      enabled: _enabled,
      markerId: _markerId,
      markerType: (_selectedMarkerType ?? 'official').trim(),
      markerLatitude: _markerLatitudeController.text.trim().isEmpty
          ? null
          : _parseDouble(_markerLatitudeController.text, 0),
      markerLongitude: _markerLongitudeController.text.trim().isEmpty
          ? null
          : _parseDouble(_markerLongitudeController.text, 0),
    );
  }

  Future<void> _save(AppLocalizations t) async {
    // 新建时限制 UID 只能是小写字母，避免写入不符合约束的文档 ID。
    if (widget.isCreating &&
        !_lowercaseLettersPattern.hasMatch(_idController.text.trim())) {
      _showSnack(t.adminPlaceUidLowercaseOnly);
      return;
    }

    final selectedRegionId = _selectedRegionId?.trim() ?? '';
    if (selectedRegionId.isEmpty) {
      _showSnack(t.adminPlaceRegionRequired);
      return;
    }
    if (!_controller.regionIds.contains(selectedRegionId)) {
      _showSnack(t.adminPlaceRegionInvalid);
      return;
    }

    final savedId = await _controller.save(_buildDraft());
    if (savedId == null || !mounted) {
      return;
    }
    _showSnack(t.save);
    if (widget.isCreating) {
      context.go(AppRouter.adminPlaceEdit(savedId));
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
    final success = await _controller.delete(widget.placeId);
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
      placeIdHint: _idController.text.trim().isEmpty
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

  bool _isCurrentRegionMissing() {
    final regionId = _selectedRegionId?.trim() ?? '';
    if (regionId.isEmpty) {
      return false;
    }
    return !_controller.regionIds.contains(regionId);
  }

  List<String> _resolveTagOptions() {
    final options = <String>{..._defaultTagOptions, ..._selectedTags};
    final pending = _pendingTag?.trim() ?? '';
    if (pending.isNotEmpty) {
      options.remove(pending);
    }
    return options.toList(growable: false)..sort();
  }

  List<String> _resolveMarkerTypeOptions() {
    final options = <String>{..._defaultMarkerTypeOptions};
    final current = _selectedMarkerType?.trim() ?? '';
    if (current.isNotEmpty) {
      options.add(current);
    }
    return options.toList(growable: false)..sort();
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
          widget.isCreating ? t.adminCreatePlace : t.adminPlaceEditTitle,
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

          final languageCode = Localizations.localeOf(context).languageCode;
          final regions = _controller.regions.toList(growable: false)
            ..sort((a, b) => a.id.compareTo(b.id));
          final regionIds = _controller.regionIds;
          final hasSelectedRegion =
              _selectedRegionId != null &&
              _selectedRegionId!.isNotEmpty &&
              regionIds.contains(_selectedRegionId!);
          final missingRegion = _isCurrentRegionMissing();
          final markerTypeOptions = _resolveMarkerTypeOptions();
          final tagOptions = _resolveTagOptions();

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
                      inputFormatters: widget.isCreating
                          ? <TextInputFormatter>[
                              FilteringTextInputFormatter.allow(
                                RegExp(r'[a-z_]'),
                              ),
                            ]
                          : null,
                      decoration: InputDecoration(
                        labelText: t.uidLabel,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    BilingualTextField(
                      label: t.adminName,
                      zhLabel: t.languageChinese,
                      enLabel: t.languageEnglish,
                      zhController: _nameZhController,
                      enController: _nameEnController,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      key: ValueKey<String?>('tag-${_pendingTag ?? ''}'),
                      initialValue: _pendingTag,
                      items: tagOptions
                          .map(
                            (tag) => DropdownMenuItem<String>(
                              value: tag,
                              child: Text(tag),
                            ),
                          )
                          .toList(growable: false),
                      onChanged: (value) {
                        if (value == null) {
                          return;
                        }
                        if (_selectedTags.contains(value)) {
                          setState(() {
                            _pendingTag = null;
                          });
                          return;
                        }
                        setState(() {
                          _selectedTags = <String>[..._selectedTags, value];
                          _pendingTag = null;
                        });
                      },
                      decoration: InputDecoration(
                        labelText: t.adminTags,
                        hintText: t.adminTagsHint,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    if (_selectedTags.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: _selectedTags
                              .map(
                                (tag) => InputChip(
                                  label: Text(tag),
                                  onDeleted: () {
                                    setState(() {
                                      _selectedTags = _selectedTags
                                          .where((item) => item != tag)
                                          .toList(growable: false);
                                    });
                                  },
                                ),
                              )
                              .toList(growable: false),
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _enabled,
                      title: Text(_enabled ? t.adminEnabled : t.adminDisabled),
                      onChanged: (value) => setState(() => _enabled = value),
                    ),
                  ],
                ),
              ),
              AdminSectionCard(
                title: t.adminMapSettings,
                child: Column(
                  children: <Widget>[
                    // 区域只能从真实 regions 集合中选择，避免写入无效 regionId。
                    DropdownButtonFormField<String>(
                      key: ValueKey<String?>(
                        'region-${hasSelectedRegion ? _selectedRegionId : ''}',
                      ),
                      initialValue: hasSelectedRegion
                          ? _selectedRegionId
                          : null,
                      items: regions
                          .map(
                            (region) => DropdownMenuItem<String>(
                              value: region.id,
                              child: Text(
                                '${region.localizedName(languageCode).trim().isEmpty ? region.id : region.localizedName(languageCode)} (${region.id})',
                              ),
                            ),
                          )
                          .toList(growable: false),
                      onChanged: (value) {
                        setState(() {
                          _selectedRegionId = value;
                        });
                      },
                      decoration: InputDecoration(
                        labelText: t.adminRegionId,
                        hintText: t.adminPlaceSelectRegionHint,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    if (missingRegion) ...<Widget>[
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          t.adminPlaceRegionMissingCurrent,
                          style: TextStyle(
                            color: Colors.red.shade600,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    TextField(
                      controller: _latitudeController,
                      keyboardType: const TextInputType.numberWithOptions(
                        signed: true,
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: t.adminLatitude,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _longitudeController,
                      keyboardType: const TextInputType.numberWithOptions(
                        signed: true,
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: t.adminLongitude,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _flyToZoomController,
                      keyboardType: const TextInputType.numberWithOptions(
                        signed: true,
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: t.adminFlyToZoom,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _flyToPitchController,
                      keyboardType: const TextInputType.numberWithOptions(
                        signed: true,
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: t.adminFlyToPitch,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _flyToBearingController,
                      keyboardType: const TextInputType.numberWithOptions(
                        signed: true,
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: t.adminFlyToBearing,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              AdminSectionCard(
                title: t.adminMarkerSettings,
                child: Column(
                  children: <Widget>[
                    DropdownButtonFormField<String>(
                      key: ValueKey<String?>(
                        'marker-${_selectedMarkerType ?? ''}',
                      ),
                      initialValue: _selectedMarkerType,
                      items: markerTypeOptions
                          .map(
                            (markerType) => DropdownMenuItem<String>(
                              value: markerType,
                              child: Text(markerType),
                            ),
                          )
                          .toList(growable: false),
                      onChanged: (value) {
                        setState(() {
                          _selectedMarkerType = value;
                        });
                      },
                      decoration: InputDecoration(
                        labelText: t.adminMarkerType,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    if ((_selectedMarkerType ?? '').isNotEmpty) ...<Widget>[
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: InputChip(
                          label: Text(_selectedMarkerType!),
                          onDeleted: () {
                            setState(() {
                              _selectedMarkerType = null;
                            });
                          },
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    TextField(
                      controller: _markerLatitudeController,
                      keyboardType: const TextInputType.numberWithOptions(
                        signed: true,
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: t.adminMarkerLatitude,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _markerLongitudeController,
                      keyboardType: const TextInputType.numberWithOptions(
                        signed: true,
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: t.adminMarkerLongitude,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              AdminSectionCard(
                title: t.adminPreviewCard,
                child: Column(
                  children: <Widget>[
                    // 管理端支持“选图上传 + 自动回填 URL”，同时保留手动输入能力。
                    _buildImageUrlEditor(
                      t: t,
                      controller: _coverImageController,
                      label: t.adminCoverImageUrl,
                      onUpload: () => _pickAndUploadCoverImage(t),
                      isUploading: _controller.isUploadingImage,
                    ),
                    const SizedBox(height: 12),
                    BilingualTextField(
                      label: t.adminQuote,
                      zhLabel: t.languageChinese,
                      enLabel: t.languageEnglish,
                      zhController: _quoteZhController,
                      enController: _quoteEnController,
                    ),
                    const SizedBox(height: 12),
                    BilingualTextAreaField(
                      label: t.adminShortDescription,
                      zhLabel: t.languageChinese,
                      enLabel: t.languageEnglish,
                      zhController: _shortZhController,
                      enController: _shortEnController,
                    ),
                  ],
                ),
              ),
              AdminSectionCard(
                title: t.adminPlaceDetails,
                child: BilingualTextAreaField(
                  label: t.adminLongDescription,
                  zhLabel: t.languageChinese,
                  enLabel: t.languageEnglish,
                  zhController: _longZhController,
                  enController: _longEnController,
                  minLines: 4,
                  maxLines: 8,
                ),
              ),
              if (!widget.isCreating && _idController.text.trim().isNotEmpty)
                AdminSectionCard(
                  title: t.adminSubcontent,
                  child: Column(
                    children: <Widget>[
                      _buildSubcontentTile(
                        context: context,
                        title: t.adminExperiences,
                        kind: AdminSubcontentKind.experiences,
                      ),
                      _buildSubcontentTile(
                        context: context,
                        title: t.adminFlavors,
                        kind: AdminSubcontentKind.flavors,
                      ),
                      _buildSubcontentTile(
                        context: context,
                        title: t.adminStays,
                        kind: AdminSubcontentKind.stays,
                      ),
                      _buildSubcontentTile(
                        context: context,
                        title: t.adminGallery,
                        kind: AdminSubcontentKind.gallery,
                      ),
                    ],
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

  Widget _buildSubcontentTile({
    required BuildContext context,
    required String title,
    required AdminSubcontentKind kind,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => context.push(
        AppRouter.adminPlaceSubcontent(
          _idController.text.trim(),
          kind.collectionName,
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
