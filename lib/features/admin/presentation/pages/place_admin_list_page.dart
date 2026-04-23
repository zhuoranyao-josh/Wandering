import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/app_router.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/admin_place.dart';
import '../controllers/admin_place_list_controller.dart';

class PlaceAdminListPage extends StatefulWidget {
  const PlaceAdminListPage({super.key});

  @override
  State<PlaceAdminListPage> createState() => _PlaceAdminListPageState();
}

class _PlaceAdminListPageState extends State<PlaceAdminListPage> {
  late final AdminPlaceListController _controller = AdminPlaceListController(
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
    if (key == null || !mounted) return;
    final t = AppLocalizations.of(context);
    if (t == null) return;
    if (key == 'adminLoadFailed') {
      _showSnack(t.adminLoadFailed);
    } else if (key == 'adminSaveFailed') {
      _showSnack(t.adminSaveFailed);
    } else if (key == 'adminDeleteFailed') {
      _showSnack(t.adminDeleteFailed);
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  Future<void> _confirmDelete(AdminPlace place, AppLocalizations t) async {
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
      await _controller.deletePlace(place.id);
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
      appBar: AppBar(title: Text(t.adminPlaceListTitle)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await context.push(AppRouter.adminPlaceEdit('new'));
          if (!mounted) return;
          await _controller.load();
        },
        label: Text(t.adminCreatePlace),
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
                        separatorBuilder: (context, index) =>
                            const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final place = items[index];
                          return ListTile(
                            title: Text(place.localizedName(languageCode)),
                            subtitle: Text(place.id),
                            leading: Icon(
                              place.enabled
                                  ? Icons.check_circle_outline
                                  : Icons.block_outlined,
                              color: place.enabled
                                  ? Colors.green.shade600
                                  : Colors.grey,
                            ),
                            trailing: Wrap(
                              spacing: 4,
                              children: <Widget>[
                                IconButton(
                                  tooltip: place.enabled
                                      ? t.adminDisable
                                      : t.adminEnable,
                                  onPressed: () =>
                                      _controller.toggleEnabled(place),
                                  icon: Icon(
                                    place.enabled
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                  ),
                                ),
                                IconButton(
                                  tooltip: t.adminEdit,
                                  onPressed: () async {
                                    await context.push(
                                      AppRouter.adminPlaceEdit(place.id),
                                    );
                                    if (!mounted) return;
                                    await _controller.load();
                                  },
                                  icon: const Icon(Icons.edit_outlined),
                                ),
                                IconButton(
                                  tooltip: t.communityDeleteAction,
                                  onPressed: () => _confirmDelete(place, t),
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
