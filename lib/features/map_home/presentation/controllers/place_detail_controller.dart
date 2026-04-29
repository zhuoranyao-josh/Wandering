import 'package:flutter/foundation.dart';

import '../../domain/repositories/map_home_repository.dart';
import '../models/place_detail_ui_model.dart';

class PlaceDetailController extends ChangeNotifier {
  PlaceDetailController({required this.repository});

  final MapHomeRepository repository;

  bool _isLoading = false;
  String? _errorMessage;
  PlaceDetailUiModel? _detailModel;
  final Map<String, PlaceDetailUiModel> _cache = <String, PlaceDetailUiModel>{};

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  PlaceDetailUiModel? get detailModel => _detailModel;

  Future<void> loadPlaceDetail(
    String placeId, {
    bool forceRefresh = false,
  }) async {
    final trimmedPlaceId = placeId.trim();
    if (trimmedPlaceId.isEmpty) {
      _detailModel = null;
      _errorMessage = null;
      notifyListeners();
      return;
    }

    if (!forceRefresh) {
      final cached = _cache[trimmedPlaceId];
      if (cached != null) {
        _detailModel = cached;
        _errorMessage = null;
        notifyListeners();
        return;
      }
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final detailSections = await repository.loadPlaceDetailSections(
        trimmedPlaceId,
      );
      if (detailSections != null) {
        final model = PlaceDetailUiModel.fromDetailSections(
          detail: detailSections,
        );
        _detailModel = model;
        _cache[trimmedPlaceId] = model;
      } else {
        _detailModel = null;
      }
    } catch (error) {
      _errorMessage = 'placeDetailLoadFailed';
      debugPrint('[PlaceDetail] load failed error=$error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshPlaceDetail(String placeId) async {
    await loadPlaceDetail(placeId, forceRefresh: true);
  }
}
