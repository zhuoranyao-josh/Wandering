import 'package:flutter/foundation.dart';

import '../../domain/entities/checklist_detail.dart';
import '../../domain/repositories/checklist_repository.dart';

class ChecklistDetailController extends ChangeNotifier {
  ChecklistDetailController({required this.repository});

  final ChecklistRepository repository;

  bool _isLoading = false;
  String? _errorMessage;
  ChecklistDetail? _checklistDetail;
  String _currentChecklistId = '';

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  ChecklistDetail? get checklistDetail => _checklistDetail;

  Future<void> loadChecklistDetail(String checklistId) async {
    final trimmedChecklistId = checklistId.trim();
    _currentChecklistId = trimmedChecklistId;
    if (trimmedChecklistId.isEmpty) {
      _checklistDetail = null;
      _errorMessage = null;
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _checklistDetail = await repository.getChecklistDetail(
        trimmedChecklistId,
      );
    } catch (_) {
      _errorMessage = 'checklistLoadFailed';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> retry() async {
    if (_currentChecklistId.isEmpty) {
      return;
    }
    await loadChecklistDetail(_currentChecklistId);
  }

  Future<void> updateBudget({
    double? totalBudget,
    String? currencySymbol,
  }) async {
    if (_currentChecklistId.isEmpty) {
      return;
    }
    try {
      await repository.updateBudget(
        checklistId: _currentChecklistId,
        totalBudget: totalBudget,
        currencySymbol: currencySymbol,
      );
      if (_checklistDetail != null) {
        _checklistDetail = _checklistDetail!.copyWith(
          totalBudget: totalBudget,
          currencySymbol: currencySymbol,
        );
        notifyListeners();
      }
    } catch (_) {
      _errorMessage = 'checklistLoadFailed';
      notifyListeners();
    }
  }

  Future<void> updateBudgetSplit({
    double? transportRatio,
    double? stayRatio,
    double? foodActivityRatio,
  }) async {
    if (_currentChecklistId.isEmpty) {
      return;
    }
    try {
      await repository.updateBudgetSplit(
        checklistId: _currentChecklistId,
        transportRatio: transportRatio,
        stayRatio: stayRatio,
        foodActivityRatio: foodActivityRatio,
      );
      if (_checklistDetail != null) {
        _checklistDetail = _checklistDetail!.copyWith(
          budgetSplit: ChecklistBudgetSplit(
            transportRatio: transportRatio,
            stayRatio: stayRatio,
            foodActivityRatio: foodActivityRatio,
          ),
        );
        notifyListeners();
      }
    } catch (_) {
      _errorMessage = 'checklistLoadFailed';
      notifyListeners();
    }
  }

  Future<void> toggleItemCompleted(String itemId) async {
    if (_currentChecklistId.isEmpty || _checklistDetail == null) {
      return;
    }
    final trimmedId = itemId.trim();
    if (trimmedId.isEmpty) {
      return;
    }

    final currentItems = _checklistDetail!.items;
    final index = currentItems.indexWhere((item) => item.id == trimmedId);
    if (index < 0) {
      return;
    }

    // 先在本地切换勾选状态，失败时再回滚，提升操作反馈速度。
    final nextItems = currentItems.toList(growable: false);
    final target = nextItems[index];
    nextItems[index] = target.copyWith(isCompleted: !target.isCompleted);
    _checklistDetail = _checklistDetail!.copyWith(items: nextItems);
    notifyListeners();

    try {
      await repository.toggleItemCompleted(
        checklistId: _currentChecklistId,
        itemId: trimmedId,
      );
    } catch (_) {
      nextItems[index] = target;
      _checklistDetail = _checklistDetail!.copyWith(items: nextItems);
      _errorMessage = 'checklistLoadFailed';
      notifyListeners();
    }
  }

  Future<void> updatePlan() async {
    if (_currentChecklistId.isEmpty) {
      return;
    }
    try {
      await repository.updatePlan(_currentChecklistId);
    } catch (_) {
      _errorMessage = 'checklistLoadFailed';
      notifyListeners();
    }
  }
}
