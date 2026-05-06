import 'package:flutter/foundation.dart';

import '../../../community/domain/entities/post.dart';
import '../../../community/domain/repositories/community_repository.dart';
import '../../domain/repositories/map_home_repository.dart';
import '../models/place_detail_ui_model.dart';

class PlaceDetailController extends ChangeNotifier {
  PlaceDetailController({
    required this.repository,
    required this.communityRepository,
  });

  final MapHomeRepository repository;
  final CommunityRepository communityRepository;

  bool _isLoading = false;
  bool _isCommunityLoading = false;
  String? _errorMessage;
  PlaceDetailUiModel? _detailModel;
  final Map<String, PlaceDetailUiModel> _cache = <String, PlaceDetailUiModel>{};
  List<Post> _communityPosts = const <Post>[];
  final Map<String, List<Post>> _communityCache = <String, List<Post>>{};

  bool get isLoading => _isLoading;
  bool get isCommunityLoading => _isCommunityLoading;
  String? get errorMessage => _errorMessage;
  PlaceDetailUiModel? get detailModel => _detailModel;
  List<Post> get communityPosts => _communityPosts;

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
      final cachedCommunityPosts = _communityCache[trimmedPlaceId];
      if (cached != null && cachedCommunityPosts != null) {
        _detailModel = cached;
        _communityPosts = cachedCommunityPosts;
        _errorMessage = null;
        notifyListeners();
        return;
      }
    }

    _isLoading = true;
    _isCommunityLoading = true;
    _errorMessage = null;
    notifyListeners();
    final detailSectionsFuture = repository.loadPlaceDetailSections(
      trimmedPlaceId,
    );
    final communityPostsFuture = communityRepository.fetchPostsByPlaceId(
      trimmedPlaceId,
      limit: 8,
    );
    try {
      final detailSections = await detailSectionsFuture;
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
    }

    try {
      _communityPosts = await communityPostsFuture;
      _communityCache[trimmedPlaceId] = _communityPosts;
    } catch (error) {
      _communityPosts = const <Post>[];
      debugPrint('[PlaceDetail] community posts load failed error=$error');
    } finally {
      _isCommunityLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshPlaceDetail(String placeId) async {
    await loadPlaceDetail(placeId, forceRefresh: true);
  }
}
