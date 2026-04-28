import 'package:flutter/foundation.dart';

import '../../../../core/error/app_exception.dart';
import '../../domain/entities/admin_place.dart';
import '../../domain/entities/admin_region.dart';
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
  List<AdminRegion> _regions = const <AdminRegion>[];

  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  bool get isDeleting => _isDeleting;
  bool get isUploadingImage => _isUploadingImage;
  String? get errorKey => _errorKey;
  AdminPlace? get place => _place;
  List<AdminRegion> get regions => _regions;
  Set<String> get regionIds =>
      _regions.map((region) => region.id.trim()).where((id) => id.isNotEmpty).toSet();

  Future<void> load(String placeId) async {
    _isLoading = true;
    _errorKey = null;
    notifyListeners();
    try {
      final results = await Future.wait<dynamic>([
        repository.getPlaceById(placeId),
        repository.getRegions(),
      ]);
      _place = results[0] as AdminPlace?;
      _regions = (results[1] as List<AdminRegion>).toList(growable: false);
    } catch (_) {
      _errorKey = 'adminLoadFailed';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadRegions() async {
    try {
      _regions = await repository.getRegions();
      notifyListeners();
    } catch (_) {
      _errorKey = 'adminLoadFailed';
      notifyListeners();
    }
  }

  Future<String?> save(AdminPlace place) async {
    final regionId = place.regionId.trim();
    if (regionId.isEmpty) {
      _errorKey = 'adminPlaceRegionRequired';
      notifyListeners();
      return null;
    }

    _isSaving = true;
    _errorKey = null;
    notifyListeners();
    try {
      final exists = await repository.regionExists(regionId);
      if (!exists) {
        _errorKey = 'adminPlaceRegionInvalid';
        return null;
      }

      final savedId = await repository.upsertPlace(place.copyWith(regionId: regionId));
      _place = place.copyWith(id: savedId, regionId: regionId);
      return savedId;
    } catch (error) {
      if (error is AppException && error.code == 'adminPlaceRegionRequired') {
        _errorKey = 'adminPlaceRegionRequired';
      } else if (error is AppException && error.code == 'adminPlaceRegionInvalid') {
        _errorKey = 'adminPlaceRegionInvalid';
      } else {
        _errorKey = 'adminSaveFailed';
      }
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
