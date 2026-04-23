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
    final orderController = TextEditingController(
      text: (existing?.order ?? 0).toString(),
    );
    final imageController = TextEditingController(
      text: existing?.imageUrl ?? '',
    );
    final priceController = TextEditingController(
      text: existing?.priceRange ?? '',
    );

    final titleZhController = TextEditingController(
      text: existing?.title['zh'] ?? '',
    );
    final titleEnController = TextEditingController(
      text: existing?.title['en'] ?? '',
    );
    final badgeZhController = TextEditingController(
      text: existing?.badge['zh'] ?? '',
    );
    final badgeEnController = TextEditingController(
      text: existing?.badge['en'] ?? '',
    );
    final nameZhController = TextEditingController(
      text: existing?.name['zh'] ?? '',
    );
    final nameEnController = TextEditingController(
      text: existing?.name['en'] ?? '',
    );
    final subtitleZhController = TextEditingController(
      text: existing?.subtitle['zh'] ?? '',
    );
    final subtitleEnController = TextEditingController(
      text: existing?.subtitle['en'] ?? '',
    );
    final captionZhController = TextEditingController(
      text: existing?.caption['zh'] ?? '',
    );
    final captionEnController = TextEditingController(
      text: existing?.caption['en'] ?? '',
    );

    bool enabled = existing?.enabled ?? true;
    bool isUploadingImage = false;

    Future<void> doSave() async {
      final order = int.tryParse(orderController.text.trim()) ?? 0;
      final item = AdminSubcontentItem(
        id: existing?.id ?? '',
        enabled: enabled,
        order: order,
        title: <String, String>{
          'zh': titleZhController.text.trim(),
          'en': titleEnController.text.trim(),
        },
        badge: <String, String>{
          'zh': badgeZhController.text.trim(),
          'en': badgeEnController.text.trim(),
        },
        name: <String, String>{
          'zh': nameZhController.text.trim(),
          'en': nameEnController.text.trim(),
        },
        subtitle: <String, String>{
          'zh': subtitleZhController.text.trim(),
          'en': subtitleEnController.text.trim(),
        },
        caption: <String, String>{
          'zh': captionZhController.text.trim(),
          'en': captionEnController.text.trim(),
        },
        imageUrl: imageController.text.trim(),
        priceRange: priceController.text.trim(),
      );
      await _controller.save(item);
      if (!mounted) return;
      Navigator.of(context).pop();
    }

    Future<void> pickAndUploadImage(StateSetter setDialogState) async {
      final picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (picked == null) {
        return;
      }
      setDialogState(() => isUploadingImage = true);
      final url = await _controller.uploadImage(picked.path);
      if (!mounted) return;
      setDialogState(() => isUploadingImage = false);
      if (url == null) {
        return;
      }
      imageController.text = url;
      _showSnack(t.adminImageUploadSuccess);
    }

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            // 子内容编辑使用同一弹窗骨架，按 kind 决定字段区块。
            return AlertDialog(
              title: Text(existing == null ? t.adminCreate : t.adminEdit),
              content: SizedBox(
                width: 560,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        value: enabled,
                        title: Text(enabled ? t.adminEnabled : t.adminDisabled),
                        onChanged: (value) =>
                            setDialogState(() => enabled = value),
                      ),
                      TextField(
                        controller: orderController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: t.adminOrder,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ..._buildKindFields(
                        t: t,
                        titleZhController: titleZhController,
                        titleEnController: titleEnController,
                        badgeZhController: badgeZhController,
                        badgeEnController: badgeEnController,
                        nameZhController: nameZhController,
                        nameEnController: nameEnController,
                        subtitleZhController: subtitleZhController,
                        subtitleEnController: subtitleEnController,
                        captionZhController: captionZhController,
                        captionEnController: captionEnController,
                        imageController: imageController,
                        priceController: priceController,
                        isUploadingImage: isUploadingImage,
                        onUploadImage: () => pickAndUploadImage(setDialogState),
                      ),
                    ],
                  ),
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(t.cancel),
                ),
                TextButton(onPressed: doSave, child: Text(t.save)),
              ],
            );
          },
        );
      },
    );

    orderController.dispose();
    imageController.dispose();
    priceController.dispose();
    titleZhController.dispose();
    titleEnController.dispose();
    badgeZhController.dispose();
    badgeEnController.dispose();
    nameZhController.dispose();
    nameEnController.dispose();
    subtitleZhController.dispose();
    subtitleEnController.dispose();
    captionZhController.dispose();
    captionEnController.dispose();
  }

  List<Widget> _buildKindFields({
    required AppLocalizations t,
    required TextEditingController titleZhController,
    required TextEditingController titleEnController,
    required TextEditingController badgeZhController,
    required TextEditingController badgeEnController,
    required TextEditingController nameZhController,
    required TextEditingController nameEnController,
    required TextEditingController subtitleZhController,
    required TextEditingController subtitleEnController,
    required TextEditingController captionZhController,
    required TextEditingController captionEnController,
    required TextEditingController imageController,
    required TextEditingController priceController,
    required bool isUploadingImage,
    required VoidCallback onUploadImage,
  }) {
    switch (widget.kind) {
      case AdminSubcontentKind.experiences:
        return <Widget>[
          BilingualTextField(
            label: t.adminTitle,
            zhLabel: t.languageChinese,
            enLabel: t.languageEnglish,
            zhController: titleZhController,
            enController: titleEnController,
          ),
          const SizedBox(height: 12),
          BilingualTextField(
            label: t.adminBadge,
            zhLabel: t.languageChinese,
            enLabel: t.languageEnglish,
            zhController: badgeZhController,
            enController: badgeEnController,
          ),
        ];
      case AdminSubcontentKind.flavors:
        return <Widget>[
          BilingualTextField(
            label: t.adminName,
            zhLabel: t.languageChinese,
            enLabel: t.languageEnglish,
            zhController: nameZhController,
            enController: nameEnController,
          ),
          const SizedBox(height: 12),
          BilingualTextField(
            label: t.adminSubtitle,
            zhLabel: t.languageChinese,
            enLabel: t.languageEnglish,
            zhController: subtitleZhController,
            enController: subtitleEnController,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: imageController,
            decoration: InputDecoration(
              labelText: t.adminImageUrl,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          _buildImageUploadButton(
            t: t,
            isUploading: isUploadingImage,
            onUpload: onUploadImage,
          ),
        ];
      case AdminSubcontentKind.stays:
        return <Widget>[
          BilingualTextField(
            label: t.adminName,
            zhLabel: t.languageChinese,
            enLabel: t.languageEnglish,
            zhController: nameZhController,
            enController: nameEnController,
          ),
          const SizedBox(height: 12),
          BilingualTextField(
            label: t.adminBadge,
            zhLabel: t.languageChinese,
            enLabel: t.languageEnglish,
            zhController: badgeZhController,
            enController: badgeEnController,
          ),
          const SizedBox(height: 12),
          _buildImageUrlEditor(
            t: t,
            controller: imageController,
            isUploading: isUploadingImage,
            onUpload: onUploadImage,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: priceController,
            decoration: InputDecoration(
              labelText: t.adminPriceRange,
              border: const OutlineInputBorder(),
            ),
          ),
        ];
      case AdminSubcontentKind.gallery:
        return <Widget>[
          _buildImageUrlEditor(
            t: t,
            controller: imageController,
            isUploading: isUploadingImage,
            onUpload: onUploadImage,
          ),
          const SizedBox(height: 12),
          BilingualTextField(
            label: t.adminCaption,
            zhLabel: t.languageChinese,
            enLabel: t.languageEnglish,
            zhController: captionZhController,
            enController: captionEnController,
          ),
        ];
    }
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

  Widget _buildImageUrlEditor({
    required AppLocalizations t,
    required TextEditingController controller,
    required bool isUploading,
    required VoidCallback onUpload,
  }) {
    return Column(
      children: <Widget>[
        TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: t.adminImageUrl,
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        _buildImageUploadButton(
          t: t,
          isUploading: isUploading,
          onUpload: onUpload,
        ),
      ],
    );
  }

  Widget _buildImageUploadButton({
    required AppLocalizations t,
    required bool isUploading,
    required VoidCallback onUpload,
  }) {
    return Align(
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
        label: Text(isUploading ? t.adminUploadingImage : t.adminUploadImage),
      ),
    );
  }
}
