import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/app_router.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../l10n/app_localizations.dart';
import '../controllers/checklist_controller.dart';
import '../widgets/checklist_card.dart';

class ChecklistListPage extends StatefulWidget {
  const ChecklistListPage({super.key});

  @override
  State<ChecklistListPage> createState() => _ChecklistListPageState();
}

class _ChecklistListPageState extends State<ChecklistListPage> {
  late final ChecklistController _controller =
      ServiceLocator.checklistController;
  final Stopwatch _pageLoadStopwatch = Stopwatch();
  bool _hasLoggedFirstContentFrame = false;
  String? _lastErrorKey;

  @override
  void initState() {
    super.initState();
    _pageLoadStopwatch.start();
    debugPrint(
      '[MyTrips] page init started cachedItems=${_controller.items.length}',
    );
    _controller.addListener(_handleControllerChange);
    _controller.load();
  }

  @override
  void dispose() {
    _controller.removeListener(_handleControllerChange);
    super.dispose();
  }

  void _handleControllerChange() {
    final key = _controller.errorKey;
    if (!mounted || key == null) {
      _lastErrorKey = null;
      return;
    }
    if (key == _lastErrorKey) {
      return;
    }

    _lastErrorKey = key;
    final t = AppLocalizations.of(context);
    if (t == null) {
      return;
    }

    if (key == 'checklistLoadFailed') {
      _showSnack(t.checklistLoadFailed);
    } else if (key == 'checklistDeleteFailed') {
      _showSnack(t.checklistDeleteFailed);
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    final t = AppLocalizations.of(context);
    if (t == null) return false;

    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              title: Text(t.checklistDeleteTitle),
              content: Text(t.checklistDeleteMessage),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: Text(t.cancel),
                ),
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: Text(t.communityDeleteAction),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    if (t == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        // 顶栏与底部导航栏保持一致的纯白背景风格。
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        foregroundColor: const Color(0xFF111827),
        centerTitle: true,
        title: Text(
          t.myTrips,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: <Widget>[
          IconButton(
            onPressed: () => context.push(AppRouter.checklistCreate()),
            icon: const Icon(Icons.add),
            tooltip: t.createChecklist,
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          if (_controller.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!_hasLoggedFirstContentFrame) {
            _hasLoggedFirstContentFrame = true;
            // 首次内容帧渲染后再记时，便于区分“页面打开”与“列表真正可见”。
            WidgetsBinding.instance.addPostFrameCallback((_) {
              debugPrint(
                '[MyTrips] first frame rendered '
                'elapsed=${_pageLoadStopwatch.elapsedMilliseconds}ms',
              );
            });
          }

          final items = _controller.items;
          if (items.isEmpty) {
            return _buildEmptyState(t);
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Dismissible(
                  key: ValueKey<String>(item.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.delete_outline,
                      color: Color(0xFFB91C1C),
                    ),
                  ),
                  confirmDismiss: (_) async {
                    final confirmed = await _confirmDelete(context);
                    if (!confirmed) {
                      return false;
                    }
                    return await _controller.deleteChecklist(item.id);
                  },
                  child: ChecklistCard(
                    item: item,
                    onTap: () =>
                        context.push(AppRouter.checklistDetail(item.id)),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations t) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              t.startYourFirstTrip,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.push(AppRouter.checklistCreate()),
              child: Text(t.createChecklist),
            ),
          ],
        ),
      ),
    );
  }
}
