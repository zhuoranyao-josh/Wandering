import 'package:flutter/foundation.dart';

import '../../domain/entities/admin_place.dart';
import '../../domain/repositories/admin_repository.dart';

class AdminPlaceEditController extends ChangeNotifier {
  AdminPlaceEditController({required this.repository});

  final AdminRepository repository;

  bool _isLoading = false;
  bool _isSaving = false;
  bool _isDeleting = false;
  bool _isUploadingImage = false;
  String? _errorKey;
  AdminPlace? _place;

  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  bool get isDeleting => _isDeleting;
  bool get isUploadingImage => _isUploadingImage;
  String? get errorKey => _errorKey;
  AdminPlace? get place => _place;

  Future<void> load(String placeId) async {
    _isLoading = true;
    _errorKey = null;
    notifyListeners();
    try {
      _place = await repository.getPlaceById(placeId);
    } catch (_) {
      _errorKey = 'adminLoadFailed';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> save(AdminPlace place) async {
    _isSaving = true;
    _errorKey = null;
    notifyListeners();
    try {
      final savedId = await repository.upsertPlace(place);
      _place = place.copyWith(id: savedId);
      return savedId;
    } catch (_) {
      _errorKey = 'adminSaveFailed';
      return null;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<bool> delete(String placeId) async {
    _isDeleting = true;
    _errorKey = null;
    notifyListeners();
    try {
      await repository.deletePlace(placeId);
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
    String? placeIdHint,
  }) async {
    _isUploadingImage = true;
    _errorKey = null;
    notifyListeners();
    try {
      return await repository.uploadPlaceCoverImage(
        localPath: localPath,
        placeIdHint: placeIdHint,
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
