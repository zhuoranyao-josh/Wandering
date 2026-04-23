import 'package:flutter/foundation.dart';

import '../../domain/entities/admin_activity.dart';
import '../../domain/repositories/admin_repository.dart';

class AdminActivityEditController extends ChangeNotifier {
  AdminActivityEditController({required this.repository});

  final AdminRepository repository;

  bool _isLoading = false;
  bool _isSaving = false;
  bool _isDeleting = false;
  bool _isUploadingImage = false;
  String? _errorKey;
  AdminActivity? _activity;

  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  bool get isDeleting => _isDeleting;
  bool get isUploadingImage => _isUploadingImage;
  String? get errorKey => _errorKey;
  AdminActivity? get activity => _activity;

  Future<void> load(String activityId) async {
    _isLoading = true;
    _errorKey = null;
    notifyListeners();
    try {
      _activity = await repository.getActivityById(activityId);
    } catch (_) {
      _errorKey = 'adminLoadFailed';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> save(AdminActivity activity) async {
    _isSaving = true;
    _errorKey = null;
    notifyListeners();
    try {
      final savedId = await repository.upsertActivity(activity);
      _activity = activity.copyWith(id: savedId);
      return savedId;
    } catch (_) {
      _errorKey = 'adminSaveFailed';
      return null;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<bool> delete(String activityId) async {
    _isDeleting = true;
    _errorKey = null;
    notifyListeners();
    try {
      await repository.deleteActivity(activityId);
      return true;
    } catch (_) {
      _errorKey = 'adminDeleteFailed';
      return false;
    } finally {
      _isDeleting = false;
      notifyListeners();
    }
  }

  Future<String?> uploadCoverImage({
    required String localPath,
    String? activityIdHint,
  }) async {
    _isUploadingImage = true;
    _errorKey = null;
    notifyListeners();
    try {
      return await repository.uploadActivityCoverImage(
        localPath: localPath,
        activityIdHint: activityIdHint,
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
