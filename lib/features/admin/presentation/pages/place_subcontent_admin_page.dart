import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/admin_subcontent_item.dart';
import '../../domain/entities/admin_subcontent_kind.dart';
import '../controllers/admin_place_subcontent_controller.dart';
import '../widgets/bilingual_text_field.dart';

class PlaceSubcontentAdminPage extends StatefulWidget {
  const PlaceSubcontentAdminPage({
    super.key,
    required this.placeId,
    required this.kind,
  });

  final String placeId;
  final AdminSubcontentKind kind;

  @override
  State<PlaceSubcontentAdminPage> createState() =>
      _PlaceSubcontentAdminPageState();
}

class _PlaceSubcontentAdminPageState extends State<PlaceSubcontentAdminPage> {
  late final AdminPlaceSubcontentController _controller =
      AdminPlaceSubcontentController(
        repository: ServiceLocator.adminRepository,
        placeId: widget.placeId,
        kind: widget.kind,
      );
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_handleControllerChange);
    _controller.load();
  }

  @override
  void dispose() {
    _controller.removeListener(_handleControllerChange);
    _controller.dispose();
    super.dispose();
  }

  void _handleControllerChange() {
    final key = _controller.errorKey;
    if (key == null || !mounted) return;
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
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _kindTitle(AppLocalizations t) {
    switch (widget.kind) {
      case AdminSubcontentKind.experiences:
        return t.adminExperiences;
      case AdminSubcontentKind.flavors:
        return t.adminFlavors;
      case AdminSubcontentKind.stays:
        return t.adminStays;
      case AdminSubcontentKind.gallery:
        return t.adminGallery;
    }
  }

  String _localizedMap(Map<String, String> map, String languageCode) {
    final isZh = languageCode.toLowerCase().startsWith('zh');
    final zh = map['zh']?.trim() ?? '';
    final en = map['en']?.trim() ?? '';
    if (isZh && zh.isNotEmpty) {
      return zh;
    }
    if (en.isNotEmpty) {
      return en;
    }
    return zh;
  }

  String _primaryText(AdminSubcontentItem item, String languageCode) {
    switch (widget.kind) {
      case AdminSubcontentKind.experiences:
        return _localizedMap(item.title, languageCode);
      case AdminSubcontentKind.flavors:
      case AdminSubcontentKind.stays:
        return _localizedMap(item.name, languageCode);
      case AdminSubcontentKind.gallery:
        final caption = _localizedMap(item.caption, languageCode);
        return caption.isEmpty ? item.imageUrl : caption;
    }
  }

  String _secondaryText(AdminSubcontentItem item, String languageCode) {
    switch (widget.kind) {
      case AdminSubcontentKind.experiences:
        return _localizedMap(item.badge, languageCode);
      case AdminSubcontentKind.flavors:
        return _localizedMap(item.subtitle, languageCode);
      case AdminSubcontentKind.stays:
        return item.priceRange;
      case AdminSubcontentKind.gallery:
        return item.imageUrl;
    }
  }

  Future<void> _openEditDialog({
    required AppLocalizations t,
    AdminSubcontentItem? existing,
  }) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return _SubcontentEditDialog(
          t: t,
          kind: widget.kind,
          existing: existing,
          controller: _controller,
          imagePicker: _imagePicker,
          onUploadSuccess: () => _showSnack(t.adminImageUploadSuccess),
        );
      },
    );
  }

  Future<void> _confirmDelete(
    AdminSubcontentItem item,
    AppLocalizations t,
  ) async {
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
    if (confirmed == true) {
      await _controller.delete(item.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    if (t == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final languageCode = Localizations.localeOf(context).languageCode;
    final title = _kindTitle(t);

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditDialog(t: t),
        icon: const Icon(Icons.add),
        label: Text(t.adminCreate),
      ),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          if (_controller.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final items = _controller.items;
          if (items.isEmpty) {
            return Center(child: Text(t.adminNoData));
          }

          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final item = items[index];
              return ListTile(
                title: Text(_primaryText(item, languageCode)),
                subtitle: Text(_secondaryText(item, languageCode)),
                leading: Icon(
                  item.enabled
                      ? Icons.check_circle_outline
                      : Icons.block_outlined,
                  color: item.enabled ? Colors.green.shade600 : Colors.grey,
                ),
                trailing: Wrap(
                  spacing: 2,
                  children: <Widget>[
                    IconButton(
                      onPressed: () =>
                          _controller.moveItem(item: item, direction: -1),
                      icon: const Icon(Icons.arrow_upward),
                    ),
                    IconButton(
                      onPressed: () =>
                          _controller.moveItem(item: item, direction: 1),
                      icon: const Icon(Icons.arrow_downward),
                    ),
                    IconButton(
                      onPressed: () => _controller.toggleEnabled(item),
                      icon: Icon(
                        item.enabled
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                    ),
                    IconButton(
                      onPressed: () => _openEditDialog(t: t, existing: item),
                      icon: const Icon(Icons.edit_outlined),
                    ),
                    IconButton(
                      onPressed: () => _confirmDelete(item, t),
                      icon: const Icon(Icons.delete_outline),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _SubcontentEditDialog extends StatefulWidget {
  const _SubcontentEditDialog({
    required this.t,
    required this.kind,
    required this.controller,
    required this.imagePicker,
    required this.onUploadSuccess,
    this.existing,
  });

  final AppLocalizations t;
  final AdminSubcontentKind kind;
  final AdminSubcontentItem? existing;
  final AdminPlaceSubcontentController controller;
  final ImagePicker imagePicker;
  final VoidCallback onUploadSuccess;

  @override
  State<_SubcontentEditDialog> createState() => _SubcontentEditDialogState();
}

class _SubcontentEditDialogState extends State<_SubcontentEditDialog> {
  late final TextEditingController _orderController = TextEditingController(
    text: (widget.existing?.order ?? 0).toString(),
  );
  late final TextEditingController _imageController = TextEditingController(
    text: widget.existing?.imageUrl ?? '',
  );
  late final TextEditingController _priceController = TextEditingController(
    text: widget.existing?.priceRange ?? '',
  );
  late final TextEditingController _titleZhController = TextEditingController(
    text: widget.existing?.title['zh'] ?? '',
  );
  late final TextEditingController _titleEnController = TextEditingController(
    text: widget.existing?.title['en'] ?? '',
  );
  late final TextEditingController _badgeZhController = TextEditingController(
    text: widget.existing?.badge['zh'] ?? '',
  );
  late final TextEditingController _badgeEnController = TextEditingController(
    text: widget.existing?.badge['en'] ?? '',
  );
  late final TextEditingController _nameZhController = TextEditingController(
    text: widget.existing?.name['zh'] ?? '',
  );
  late final TextEditingController _nameEnController = TextEditingController(
    text: widget.existing?.name['en'] ?? '',
  );
  late final TextEditingController _subtitleZhController =
      TextEditingController(text: widget.existing?.subtitle['zh'] ?? '');
  late final TextEditingController _subtitleEnController =
      TextEditingController(text: widget.existing?.subtitle['en'] ?? '');
  late final TextEditingController _captionZhController = TextEditingController(
    text: widget.existing?.caption['zh'] ?? '',
  );
  late final TextEditingController _captionEnController = TextEditingController(
    text: widget.existing?.caption['en'] ?? '',
  );

  late bool _enabled = widget.existing?.enabled ?? true;
  bool _isUploadingImage = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _orderController.dispose();
    _imageController.dispose();
    _priceController.dispose();
    _titleZhController.dispose();
    _titleEnController.dispose();
    _badgeZhController.dispose();
    _badgeEnController.dispose();
    _nameZhController.dispose();
    _nameEnController.dispose();
    _subtitleZhController.dispose();
    _subtitleEnController.dispose();
    _captionZhController.dispose();
    _captionEnController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_isSaving) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _isSaving = true);
    final order = int.tryParse(_orderController.text.trim()) ?? 0;
    final item = AdminSubcontentItem(
      id: widget.existing?.id ?? '',
      enabled: _enabled,
      order: order,
      title: <String, String>{
        'zh': _titleZhController.text.trim(),
        'en': _titleEnController.text.trim(),
      },
      badge: <String, String>{
        'zh': _badgeZhController.text.trim(),
        'en': _badgeEnController.text.trim(),
      },
      name: <String, String>{
        'zh': _nameZhController.text.trim(),
        'en': _nameEnController.text.trim(),
      },
      subtitle: <String, String>{
        'zh': _subtitleZhController.text.trim(),
        'en': _subtitleEnController.text.trim(),
      },
      caption: <String, String>{
        'zh': _captionZhController.text.trim(),
        'en': _captionEnController.text.trim(),
      },
      imageUrl: _imageController.text.trim(),
      priceRange: _priceController.text.trim(),
    );
    await widget.controller.save(item);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _pickAndUploadImage() async {
    final picked = await widget.imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked == null || !mounted) {
      return;
    }
    setState(() => _isUploadingImage = true);
    final url = await widget.controller.uploadImage(picked.path);
    if (!mounted) return;
    setState(() => _isUploadingImage = false);
    if (url == null) {
      return;
    }
    _imageController.text = url;
    widget.onUploadSuccess();
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.t;
    return AlertDialog(
      title: Text(widget.existing == null ? t.adminCreate : t.adminEdit),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _enabled,
                title: Text(_enabled ? t.adminEnabled : t.adminDisabled),
                onChanged: (value) => setState(() => _enabled = value),
              ),
              TextField(
                controller: _orderController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: t.adminOrder,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              ..._buildKindFields(t),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () {
            FocusManager.instance.primaryFocus?.unfocus();
            Navigator.of(context).pop();
          },
          child: Text(t.cancel),
        ),
        TextButton(onPressed: _isSaving ? null : _save, child: Text(t.save)),
      ],
    );
  }

  List<Widget> _buildKindFields(AppLocalizations t) {
    switch (widget.kind) {
      case AdminSubcontentKind.experiences:
        return <Widget>[
          BilingualTextField(
            label: t.adminTitle,
            zhLabel: t.languageChinese,
            enLabel: t.languageEnglish,
            zhController: _titleZhController,
            enController: _titleEnController,
          ),
          const SizedBox(height: 12),
          BilingualTextField(
            label: t.adminBadge,
            zhLabel: t.languageChinese,
            enLabel: t.languageEnglish,
            zhController: _badgeZhController,
            enController: _badgeEnController,
          ),
        ];
      case AdminSubcontentKind.flavors:
        return <Widget>[
          BilingualTextField(
            label: t.adminName,
            zhLabel: t.languageChinese,
            enLabel: t.languageEnglish,
            zhController: _nameZhController,
            enController: _nameEnController,
          ),
          const SizedBox(height: 12),
          BilingualTextField(
            label: t.adminSubtitle,
            zhLabel: t.languageChinese,
            enLabel: t.languageEnglish,
            zhController: _subtitleZhController,
            enController: _subtitleEnController,
          ),
          const SizedBox(height: 12),
          _buildImageUrlEditor(t),
        ];
      case AdminSubcontentKind.stays:
        return <Widget>[
          BilingualTextField(
            label: t.adminName,
            zhLabel: t.languageChinese,
            enLabel: t.languageEnglish,
            zhController: _nameZhController,
            enController: _nameEnController,
          ),
          const SizedBox(height: 12),
          BilingualTextField(
            label: t.adminBadge,
            zhLabel: t.languageChinese,
            enLabel: t.languageEnglish,
            zhController: _badgeZhController,
            enController: _badgeEnController,
          ),
          const SizedBox(height: 12),
          _buildImageUrlEditor(t),
          const SizedBox(height: 12),
          TextField(
            controller: _priceController,
            decoration: InputDecoration(
              labelText: t.adminPriceRange,
              border: const OutlineInputBorder(),
            ),
          ),
        ];
      case AdminSubcontentKind.gallery:
        return <Widget>[
          _buildImageUrlEditor(t),
          const SizedBox(height: 12),
          BilingualTextField(
            label: t.adminCaption,
            zhLabel: t.languageChinese,
            enLabel: t.languageEnglish,
            zhController: _captionZhController,
            enController: _captionEnController,
          ),
        ];
    }
  }

  Widget _buildImageUrlEditor(AppLocalizations t) {
    return Column(
      children: <Widget>[
        TextField(
          controller: _imageController,
          decoration: InputDecoration(
            labelText: t.adminImageUrl,
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            onPressed: _isUploadingImage ? null : _pickAndUploadImage,
            icon: _isUploadingImage
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.upload_file_outlined),
            label: Text(
              _isUploadingImage ? t.adminUploadingImage : t.adminUploadImage,
            ),
          ),
        ),
      ],
    );
  }
}
