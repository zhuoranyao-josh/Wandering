import 'package:flutter/foundation.dart';

import '../../domain/entities/admin_activity.dart';
import '../../domain/repositories/admin_repository.dart';

class AdminActivityListController extends ChangeNotifier {
  AdminActivityListController({required this.repository});

  final AdminRepository repository;

  bool _isLoading = false;
  String? _errorKey;
  String _keyword = '';
  List<AdminActivity> _items = const <AdminActivity>[];

  bool get isLoading => _isLoading;
  String? get errorKey => _errorKey;
  String get keyword => _keyword;
  List<AdminActivity> get items => _items;

  List<AdminActivity> get filteredItems {
    final query = _keyword.trim().toLowerCase();
    if (query.isEmpty) {
      return _items;
    }
    return _items
        .where((item) {
          final titleMatches = item.title.values.any(
            (value) => value.toLowerCase().contains(query),
          );
          final cityMatches = item.cityName.values.any(
            (value) => value.toLowerCase().contains(query),
          );
          return item.id.toLowerCase().contains(query) ||
              titleMatches ||
              cityMatches;
        })
        .toList(growable: false);
  }

  Future<void> load() async {
    _isLoading = true;
    _errorKey = null;
    notifyListeners();
    try {
      _items = await repository.getActivities();
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

  Future<void> togglePublished(AdminActivity item) async {
    try {
      await repository.setActivityPublished(
        activityId: item.id,
        isPublished: !item.isPublished,
      );
      await load();
    } catch (_) {
      _errorKey = 'adminSaveFailed';
      notifyListeners();
    }
  }

  Future<void> deleteActivity(String activityId) async {
    try {
      await repository.deleteActivity(activityId);
      await load();
    } catch (_) {
      _errorKey = 'adminDeleteFailed';
      notifyListeners();
    }
  }
}
