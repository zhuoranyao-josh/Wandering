import 'package:flutter/foundation.dart';

import '../../domain/entities/admin_place.dart';
import '../../domain/repositories/admin_repository.dart';

class AdminPlaceListController extends ChangeNotifier {
  AdminPlaceListController({required this.repository});

  final AdminRepository repository;

  bool _isLoading = false;
  String? _errorKey;
  String _keyword = '';
  List<AdminPlace> _items = const <AdminPlace>[];

  bool get isLoading => _isLoading;
  String? get errorKey => _errorKey;
  String get keyword => _keyword;
  List<AdminPlace> get items => _items;

  List<AdminPlace> get filteredItems {
    final query = _keyword.trim().toLowerCase();
    if (query.isEmpty) {
      return _items;
    }
    return _items
        .where((item) {
          final id = item.id.toLowerCase();
          final zh = (item.name['zh'] ?? '').toLowerCase();
          final en = (item.name['en'] ?? '').toLowerCase();
          return id.contains(query) || zh.contains(query) || en.contains(query);
        })
        .toList(growable: false);
  }

  Future<void> load() async {
    _isLoading = true;
    _errorKey = null;
    notifyListeners();
    try {
      _items = await repository.getPlaces();
    } catch (_) {
      _errorKey = 'adminLoadFailed';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setKeyword(String value) {
    _keyword = value;
    notifyListeners();
  }

  Future<void> toggleEnabled(AdminPlace place) async {
    try {
      await repository.setPlaceEnabled(
        placeId: place.id,
        enabled: !place.enabled,
      );
      await load();
    } catch (_) {
      _errorKey = 'adminSaveFailed';
      notifyListeners();
    }
  }

  Future<void> deletePlace(String placeId) async {
    try {
      await repository.deletePlace(placeId);
      await load();
    } catch (_) {
      _errorKey = 'adminDeleteFailed';
      notifyListeners();
    }
  }
}
