import 'package:flutter/foundation.dart';

import '../../domain/entities/admin_subcontent_item.dart';
import '../../domain/entities/admin_subcontent_kind.dart';
import '../../domain/repositories/admin_repository.dart';

class AdminPlaceSubcontentController extends ChangeNotifier {
  AdminPlaceSubcontentController({
    required this.repository,
    required this.placeId,
    required this.kind,
  });

  final AdminRepository repository;
  final String placeId;
  final AdminSubcontentKind kind;

  bool _isLoading = false;
  bool _isUploadingImage = false;
  String? _errorKey;
  List<AdminSubcontentItem> _items = const <AdminSubcontentItem>[];

  bool get isLoading => _isLoading;
  bool get isUploadingImage => _isUploadingImage;
  String? get errorKey => _errorKey;
  List<AdminSubcontentItem> get items => _items;

  Future<void> load() async {
    _isLoading = true;
    _errorKey = null;
    notifyListeners();
    try {
      _items = await repository.getPlaceSubcontent(
        placeId: placeId,
        kind: kind,
      );
    } catch (_) {
      _errorKey = 'adminLoadFailed';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> save(AdminSubcontentItem item) async {
    try {
      await repository.upsertPlaceSubcontent(
        placeId: placeId,
        kind: kind,
        item: item,
      );
      await load();
    } catch (_) {
      _errorKey = 'adminSaveFailed';
      notifyListeners();
    }
  }

  Future<void> delete(String itemId) async {
    try {
      await repository.deletePlaceSubcontent(
        placeId: placeId,
        kind: kind,
        itemId: itemId,
      );
      await load();
    } catch (_) {
      _errorKey = 'adminDeleteFailed';
      notifyListeners();
    }
  }

  Future<void> toggleEnabled(AdminSubcontentItem item) async {
    try {
      await repository.setPlaceSubcontentEnabled(
        placeId: placeId,
        kind: kind,
        itemId: item.id,
        enabled: !item.enabled,
      );
      await load();
    } catch (_) {
      _errorKey = 'adminSaveFailed';
      notifyListeners();
    }
  }

  Future<void> moveItem({
    required AdminSubcontentItem item,
    required int direction,
  }) async {
    final index = _items.indexWhere((entry) => entry.id == item.id);
    if (index < 0) return;
    final targetIndex = index + direction;
    if (targetIndex < 0 || targetIndex >= _items.length) {
      return;
    }

    final target = _items[targetIndex];
    final currentOrder = item.order;
    final targetOrder = target.order;
    try {
      // 通过交换 order 值完成上移/下移，保持现有 schema 不变。
      await repository.upsertPlaceSubcontent(
        placeId: placeId,
        kind: kind,
        item: item.copyWith(order: targetOrder),
      );
      await repository.upsertPlaceSubcontent(
        placeId: placeId,
        kind: kind,
        item: target.copyWith(order: currentOrder),
      );
      await load();
    } catch (_) {
      _errorKey = 'adminSaveFailed';
      notifyListeners();
    }
  }

  Future<String?> uploadImage(String localPath) async {
    _isUploadingImage = true;
    _errorKey = null;
    notifyListeners();
    try {
      return await repository.uploadPlaceSubcontentImage(
        localPath: localPath,
        placeId: placeId,
        kind: kind,
      );
    } catch (_) {
      _errorKey = 'adminImageUploadFailed';
      return null;
    } finally {
      _isUploadingImage = false;
      notifyListeners();
    }
  }
}
