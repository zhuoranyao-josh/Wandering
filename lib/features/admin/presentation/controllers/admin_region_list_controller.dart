import 'package:flutter/foundation.dart';

import '../../domain/entities/admin_region.dart';
import '../../domain/repositories/admin_repository.dart';

class AdminRegionListController extends ChangeNotifier {
  AdminRegionListController({required this.repository});

  final AdminRepository repository;

  bool _isLoading = false;
  String? _errorKey;
  String _keyword = '';
  List<AdminRegion> _items = const <AdminRegion>[];

  bool get isLoading => _isLoading;
  String? get errorKey => _errorKey;
  String get keyword => _keyword;
  List<AdminRegion> get items => _items;

  List<AdminRegion> get filteredItems {
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
      _items = await repository.getRegions();
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

  Future<void> toggleEnabled(AdminRegion region) async {
    if (!region.supportsEnabledFlag) {
      return;
    }
    try {
      await repository.setRegionEnabled(
        regionId: region.id,
        enabled: !(region.enabled ?? true),
      );
      await load();
    } catch (_) {
      _errorKey = 'adminSaveFailed';
      notifyListeners();
    }
  }

  Future<void> deleteRegion(String regionId) async {
    try {
      await repository.deleteRegion(regionId);
      await load();
    } catch (error) {
      if (error.toString().contains('adminRegionInUse')) {
        _errorKey = 'adminRegionInUse';
      } else {
        _errorKey = 'adminDeleteFailed';
      }
      notifyListeners();
    }
  }
}
