import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/admin_region.dart';
import '../controllers/admin_region_edit_controller.dart';
import '../widgets/admin_section_card.dart';
import '../widgets/bilingual_text_field.dart';

class RegionAdminEditPage extends StatefulWidget {
  const RegionAdminEditPage({super.key, required this.regionId});

  final String regionId;

  bool get isCreating => regionId == 'new';

  @override
  State<RegionAdminEditPage> createState() => _RegionAdminEditPageState();
}

class _RegionAdminEditPageState extends State<RegionAdminEditPage> {
  late final AdminRegionEditController _controller = AdminRegionEditController(
    repository: ServiceLocator.adminRepository,
  );

  final TextEditingController _idController = TextEditingController();
  final TextEditingController _focusZoomController = TextEditingController();
  final TextEditingController _nameZhController = TextEditingController();
  final TextEditingController _nameEnController = TextEditingController();
  static final RegExp _lowercaseLettersPattern = RegExp(r'^[a-z]+$');

  bool _initialized = false;
  bool _supportsEnabled = false;
  bool _enabled = true;
  String? _lastHandledErrorKey;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_handleControllerChange);
    if (widget.isCreating) {
      _initialized = true;
      _focusZoomController.text = '4.8';
    } else {
      _controller.load(widget.regionId);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_handleControllerChange);
    _controller.dispose();
    _idController.dispose();
    _focusZoomController.dispose();
    _nameZhController.dispose();
    _nameEnController.dispose();
    super.dispose();
  }

  void _handleControllerChange() {
    if (!_initialized && _controller.region != null) {
      _bindFromRegion(_controller.region!);
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
    } else if (key == 'adminRegionInUse') {
      _showSnack(t.adminRegionInUse);
    } else if (key == 'adminRegionIdRequired') {
      _showSnack(t.adminRegionIdRequired);
    } else if (key == 'adminRegionIdLowercaseOnly') {
      _showSnack(t.adminRegionIdLowercaseOnly);
    }
  }

  void _bindFromRegion(AdminRegion region) {
    _idController.text = region.id;
    _focusZoomController.text = region.focusZoom.toString();
    _nameZhController.text = region.name['zh'] ?? '';
    _nameEnController.text = region.name['en'] ?? '';
    _supportsEnabled = region.supportsEnabledFlag;
    _enabled = region.enabled ?? true;
  }

  void _showSnack(String message) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
      );
  }

  double _parseDouble(String value, double fallback) {
    return double.tryParse(value.trim()) ?? fallback;
  }

  AdminRegion _buildDraft() {
    return AdminRegion(
      id: _idController.text.trim(),
      focusZoom: _parseDouble(_focusZoomController.text, 4.8),
      name: <String, String>{
        'zh': _nameZhController.text.trim(),
        'en': _nameEnController.text.trim(),
      },
      enabled: _supportsEnabled ? _enabled : null,
    );
  }

  Future<void> _save(AppLocalizations t) async {
    // 新建/编辑保存前再次校验，防止非常规输入绕过前端输入限制。
    if (!_lowercaseLettersPattern.hasMatch(_idController.text.trim())) {
      _showSnack(t.adminRegionIdLowercaseOnly);
      return;
    }

    final savedId = await _controller.save(_buildDraft());
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
    final success = await _controller.delete(widget.regionId);
    if (success && mounted) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    if (t == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isCreating ? t.adminCreateRegion : t.adminRegionEditTitle),
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
                      inputFormatters: widget.isCreating
                          ? <TextInputFormatter>[
                              FilteringTextInputFormatter.allow(
                                RegExp(r'[a-z]'),
                              ),
                            ]
                          : null,
                      decoration: InputDecoration(
                        labelText: t.adminRegionId,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _focusZoomController,
                      keyboardType: const TextInputType.numberWithOptions(
                        signed: false,
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: t.adminFocusZoom,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    if (_supportsEnabled) ...<Widget>[
                      const SizedBox(height: 8),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        value: _enabled,
                        title: Text(_enabled ? t.adminEnabled : t.adminDisabled),
                        onChanged: (value) => setState(() => _enabled = value),
                      ),
                    ],
                  ],
                ),
              ),
              AdminSectionCard(
                title: t.adminName,
                child: BilingualTextField(
                  label: t.adminName,
                  zhLabel: t.languageChinese,
                  enLabel: t.languageEnglish,
                  zhController: _nameZhController,
                  enController: _nameEnController,
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
            style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
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
}
