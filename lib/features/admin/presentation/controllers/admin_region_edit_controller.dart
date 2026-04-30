import 'package:flutter/foundation.dart';

import '../../../../core/error/app_exception.dart';
import '../../domain/entities/admin_region.dart';
import '../../domain/repositories/admin_repository.dart';

class AdminRegionEditController extends ChangeNotifier {
  AdminRegionEditController({required this.repository});

  final AdminRepository repository;

  bool _isLoading = false;
  bool _isSaving = false;
  bool _isDeleting = false;
  String? _errorKey;
  AdminRegion? _region;
  static final RegExp _lowercaseLettersPattern = RegExp(r'^[a-z_]+$');

  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  bool get isDeleting => _isDeleting;
  String? get errorKey => _errorKey;
  AdminRegion? get region => _region;

  Future<void> load(String regionId) async {
    _isLoading = true;
    _errorKey = null;
    notifyListeners();
    try {
      _region = await repository.getRegionById(regionId);
    } catch (_) {
      _errorKey = 'adminLoadFailed';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> save(AdminRegion region) async {
    final trimmedId = region.id.trim();
    if (trimmedId.isEmpty) {
      _errorKey = 'adminRegionIdRequired';
      notifyListeners();
      return null;
    }
    // 兼容历史数据：若旧 regionId 非小写且当前仅做原 ID 保存，则放行。
    final isLegacyUnchangedId = _region != null && _region!.id == trimmedId;
    if (!isLegacyUnchangedId && !_lowercaseLettersPattern.hasMatch(trimmedId)) {
      _errorKey = 'adminRegionIdLowercaseOnly';
      notifyListeners();
      return null;
    }

    _isSaving = true;
    _errorKey = null;
    notifyListeners();
    try {
      final savedId = await repository.upsertRegion(
        region.copyWith(id: trimmedId),
      );
      _region = region.copyWith(id: savedId);
      return savedId;
    } catch (_) {
      _errorKey = 'adminSaveFailed';
      return null;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<bool> delete(String regionId) async {
    _isDeleting = true;
    _errorKey = null;
    notifyListeners();
    try {
      await repository.deleteRegion(regionId);
      return true;
    } catch (error) {
      if (error is AppException && error.code == 'adminRegionInUse') {
        _errorKey = 'adminRegionInUse';
      } else {
        _errorKey = 'adminDeleteFailed';
      }
      return false;
    } finally {
      _isDeleting = false;
      notifyListeners();
    }
  }
}
