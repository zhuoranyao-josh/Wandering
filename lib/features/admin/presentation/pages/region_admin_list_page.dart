import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/app_router.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/admin_region.dart';
import '../controllers/admin_region_list_controller.dart';

class RegionAdminListPage extends StatefulWidget {
  const RegionAdminListPage({super.key});

  @override
  State<RegionAdminListPage> createState() => _RegionAdminListPageState();
}

class _RegionAdminListPageState extends State<RegionAdminListPage> {
  late final AdminRegionListController _controller = AdminRegionListController(
    repository: ServiceLocator.adminRepository,
  );
  final TextEditingController _searchController = TextEditingController();

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
    _searchController.dispose();
    super.dispose();
  }

  void _handleControllerChange() {
    final key = _controller.errorKey;
    if (key == null || !mounted) {
      return;
    }
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
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), duration: const Duration(seconds: 2)));
  }

  Future<void> _confirmDelete(AdminRegion region, AppLocalizations t) async {
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
      await _controller.deleteRegion(region.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    if (t == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final languageCode = Localizations.localeOf(context).languageCode;

    return Scaffold(
      appBar: AppBar(title: Text(t.adminRegionListTitle)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await context.push(AppRouter.adminRegionCreate);
          if (!mounted) {
            return;
          }
          await _controller.load();
        },
        label: Text(t.adminCreateRegion),
        icon: const Icon(Icons.add),
      ),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final items = _controller.filteredItems;
          return Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(12),
                child: TextField(
                  controller: _searchController,
                  onChanged: _controller.setKeyword,
                  decoration: InputDecoration(
                    hintText: t.adminSearchHint,
                    prefixIcon: const Icon(Icons.search),
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
              Expanded(
                child: _controller.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : items.isEmpty
                    ? Center(child: Text(t.adminNoData))
                    : ListView.separated(
                        itemCount: items.length,
                        separatorBuilder: (context, index) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final region = items[index];
                          final title = region.hasName
                              ? region.localizedName(languageCode)
                              : region.id;
                          final enabled = region.enabled;
                          final statusText = enabled == null
                              ? t.adminStatusNotSupported
                              : (enabled ? t.adminEnabled : t.adminDisabled);
                          return ListTile(
                            title: Text(title),
                            subtitle: Text(
                              '${region.id} · ${t.adminFocusZoom}: ${region.focusZoom.toStringAsFixed(1)} · $statusText',
                            ),
                            leading: Icon(
                              enabled == null
                                  ? Icons.remove_circle_outline
                                  : (enabled
                                        ? Icons.check_circle_outline
                                        : Icons.block_outlined),
                              color: enabled == null
                                  ? Colors.grey.shade500
                                  : (enabled ? Colors.green.shade600 : Colors.grey),
                            ),
                            trailing: Wrap(
                              spacing: 4,
                              children: <Widget>[
                                if (region.supportsEnabledFlag)
                                  IconButton(
                                    tooltip: enabled == true ? t.adminDisable : t.adminEnable,
                                    onPressed: () => _controller.toggleEnabled(region),
                                    icon: Icon(
                                      enabled == true
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                    ),
                                  ),
                                IconButton(
                                  tooltip: t.adminEdit,
                                  onPressed: () async {
                                    await context.push(AppRouter.adminRegionEdit(region.id));
                                    if (!mounted) {
                                      return;
                                    }
                                    await _controller.load();
                                  },
                                  icon: const Icon(Icons.edit_outlined),
                                ),
                                IconButton(
                                  tooltip: t.communityDeleteAction,
                                  onPressed: () => _confirmDelete(region, t),
                                  icon: const Icon(Icons.delete_outline),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
