import 'package:flutter/foundation.dart';

import '../../../../core/error/app_exception.dart';
import '../../../auth/domain/entities/auth_user.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../profile/domain/entities/user_profile.dart';
import '../../../profile/presentation/controllers/profile_setup_controller.dart';
import '../../domain/entities/post.dart';
import '../../domain/entities/post_location.dart';
import '../../domain/repositories/community_repository.dart';

enum CommunityFeedType { following, latest, trending }

class CommunityController extends ChangeNotifier {
  final CommunityRepository communityRepository;
  final AuthController authController;
  final ProfileSetupController profileSetupController;

  bool _isInitialized = false;
  bool _isSubmitting = false;
  final Map<CommunityFeedType, bool> _feedLoading = <CommunityFeedType, bool>{
    CommunityFeedType.following: false,
    CommunityFeedType.latest: false,
    CommunityFeedType.trending: false,
  };
  final Map<CommunityFeedType, String?> _feedErrors =
      <CommunityFeedType, String?>{
        CommunityFeedType.following: null,
        CommunityFeedType.latest: null,
        CommunityFeedType.trending: null,
      };
  List<Post> _followingPosts = const <Post>[];
  List<Post> _latestPosts = const <Post>[];
  List<Post> _trendingPosts = const <Post>[];
  final Set<String> _pendingLikePostIds = <String>{};

  CommunityController({
    required this.communityRepository,
    required this.authController,
    required this.profileSetupController,
  });

  bool get isLoading => isFeedLoading(CommunityFeedType.latest);
  bool get isSubmitting => _isSubmitting;
  String? get errorCode => feedErrorCode(CommunityFeedType.latest);
  List<Post> get latestPosts => _latestPosts;
  List<Post> get followingPosts => _followingPosts;
  List<Post> get trendingPosts => _trendingPosts;

  bool isFeedLoading(CommunityFeedType type) => _feedLoading[type] ?? false;

  String? feedErrorCode(CommunityFeedType type) => _feedErrors[type];

  List<Post> postsFor(CommunityFeedType type) {
    switch (type) {
      case CommunityFeedType.following:
        return _followingPosts;
      case CommunityFeedType.latest:
        return _latestPosts;
      case CommunityFeedType.trending:
        return _trendingPosts;
    }
  }

  bool isPostLikePending(String postId) {
    return _pendingLikePostIds.contains(postId);
  }

  Post? findPostById(String postId) {
    for (final posts in <List<Post>>[
      _latestPosts,
      _followingPosts,
      _trendingPosts,
    ]) {
      try {
        return posts.firstWhere((post) => post.id == postId);
      } catch (_) {
        continue;
      }
    }
    return null;
  }

  void upsertPost(Post post) {
    // 同步三类 feed 中已经存在的帖子，保持列表和详情页状态一致。
    _latestPosts = _upsertIntoList(_latestPosts, post);
    _followingPosts = _upsertIntoList(_followingPosts, post);
    _trendingPosts = _upsertIntoList(_trendingPosts, post);
    notifyListeners();
  }

  void removePost(String postId) {
    // 删除帖子后同步移除三类 feed 中的缓存，避免返回列表时还看到旧卡片。
    _latestPosts = _latestPosts.where((post) => post.id != postId).toList();
    _followingPosts = _followingPosts
        .where((post) => post.id != postId)
        .toList();
    _trendingPosts = _trendingPosts.where((post) => post.id != postId).toList();
    notifyListeners();
  }

  void ensureInitialized() {
    if (_isInitialized) return;
    _isInitialized = true;
    refreshAllFeeds();
  }

  Future<void> refreshAllFeeds() async {
    await Future.wait<void>(<Future<void>>[
      refreshLatestPosts(),
      refreshFollowingPosts(),
      refreshTrendingPosts(),
    ]);
  }

  Future<void> refreshLatestPosts() {
    return _refreshFeed(
      CommunityFeedType.latest,
      () => communityRepository.getLatestPosts(),
    );
  }

  Future<void> refreshFollowingPosts() async {
    final currentUser = authController.getCurrentUser();
    if (currentUser == null) {
      _followingPosts = const <Post>[];
      _feedErrors[CommunityFeedType.following] = null;
      notifyListeners();
      return;
    }

    await _refreshFeed(
      CommunityFeedType.following,
      () => communityRepository.getFollowingPosts(userId: currentUser.uid),
    );
  }

  Future<void> refreshTrendingPosts() {
    return _refreshFeed(
      CommunityFeedType.trending,
      () => communityRepository.getTrendingPosts(),
    );
  }

  Future<void> createPost({
    String? title,
    required String content,
    List<String> imageLocalPaths = const <String>[],
    String? placeNameFull,
    String? placeCity,
    String? placeCountry,
    String? placeType,
    double? latitude,
    double? longitude,
  }) async {
    final cleanContent = content.trim();
    if (cleanContent.isEmpty) {
      throw AppException('community_content_empty');
    }

    if (_isSubmitting) return;

    _isSubmitting = true;
    notifyListeners();

    try {
      final currentUser = authController.getCurrentUser();
      if (currentUser == null) {
        throw AppException('community_publish_failed');
      }

      final authorProfile = await _loadAuthorProfile(currentUser.uid);
      final cleanImageLocalPaths = imageLocalPaths
          .map((path) => path.trim())
          .where((path) => path.isNotEmpty)
          .take(20)
          .toList(growable: false);
      final createdPost = await communityRepository.createPost(
        authorId: currentUser.uid,
        authorName: _resolveAuthorName(
          currentUser: currentUser,
          profile: authorProfile,
        ),
        authorAvatarUrl: _resolveAuthorAvatarUrl(
          currentUser: currentUser,
          profile: authorProfile,
        ),
        title: _normalizeNullableText(title),
        content: cleanContent,
        // 控制器兜底限制图片数量，避免异常状态把超量图片送到数据层。
        imageLocalPaths: cleanImageLocalPaths,
        // 地点字段在 controller 先做一层清洗，减少 data layer 的兼容分支。
        placeName: _normalizeNullableText(placeNameFull),
        placeNameFull: _normalizeNullableText(placeNameFull),
        placeCity: _normalizeNullableText(placeCity),
        placeCountry: _normalizeNullableText(placeCountry),
        placeType: _normalizeNullableText(placeType),
        latitude: latitude,
        longitude: longitude,
      );

      // 发帖成功后先插入最新列表，避免回到社区页时出现闪烁。
      _latestPosts = <Post>[
        createdPost,
        ..._latestPosts.where((post) => post.id != createdPost.id),
      ];
      _feedErrors[CommunityFeedType.latest] = null;
      notifyListeners();
    } catch (error) {
      if (error is AppException) {
        rethrow;
      }
      throw AppException('community_publish_failed');
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<List<PostLocation>> searchLocations({
    required String query,
    required String sessionToken,
  }) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) {
      return const <PostLocation>[];
    }

    try {
      return communityRepository.searchLocations(
        query: cleanQuery,
        sessionToken: sessionToken,
      );
    } catch (error) {
      if (error is AppException) {
        rethrow;
      }
      throw AppException('community_location_search_failed');
    }
  }

  Future<PostLocation> retrieveLocation(PostLocation suggestion) async {
    try {
      return communityRepository.retrieveLocation(suggestion);
    } catch (error) {
      if (error is AppException) {
        rethrow;
      }
      throw AppException('community_location_search_failed');
    }
  }

  Future<void> togglePostLike(Post post) async {
    final currentUser = authController.getCurrentUser();
    if (currentUser == null) {
      throw AppException('community_like_failed');
    }
    if (_pendingLikePostIds.contains(post.id)) {
      return;
    }

    final isLiking = !post.isLikedByCurrentUser;
    final optimisticPost = post.copyWith(
      isLikedByCurrentUser: isLiking,
      likeCount: isLiking ? post.likeCount + 1 : _safeDecrement(post.likeCount),
    );

    _pendingLikePostIds.add(post.id);
    upsertPost(optimisticPost);

    try {
      if (isLiking) {
        await communityRepository.likePost(
          postId: post.id,
          userId: currentUser.uid,
        );
      } else {
        await communityRepository.unlikePost(
          postId: post.id,
          userId: currentUser.uid,
        );
      }
    } catch (error) {
      upsertPost(post);
      if (error is AppException) {
        rethrow;
      }
      throw AppException('community_like_failed');
    } finally {
      _pendingLikePostIds.remove(post.id);
      notifyListeners();
    }
  }

  Future<void> _refreshFeed(
    CommunityFeedType type,
    Future<List<Post>> Function() loader,
  ) async {
    _feedLoading[type] = true;
    _feedErrors[type] = null;
    notifyListeners();

    try {
      final posts = await loader();
      _setPostsFor(type, posts);
      _feedErrors[type] = null;
    } catch (error) {
      if (error is AppException) {
        _feedErrors[type] = error.code;
      } else {
        _feedErrors[type] = 'community_load_failed';
      }
    } finally {
      _feedLoading[type] = false;
      notifyListeners();
    }
  }

  void _setPostsFor(CommunityFeedType type, List<Post> posts) {
    switch (type) {
      case CommunityFeedType.following:
        _followingPosts = posts;
        break;
      case CommunityFeedType.latest:
        _latestPosts = posts;
        break;
      case CommunityFeedType.trending:
        _trendingPosts = posts;
        break;
    }
  }

  List<Post> _upsertIntoList(List<Post> source, Post post) {
    final existingIndex = source.indexWhere((item) => item.id == post.id);
    if (existingIndex == -1) {
      return source;
    }

    final updatedPosts = List<Post>.from(source);
    updatedPosts[existingIndex] = post;
    return updatedPosts;
  }

  Future<UserProfile?> _loadAuthorProfile(String uid) async {
    final cachedProfile = profileSetupController.getCachedProfile(uid);
    if (cachedProfile != null) {
      return cachedProfile;
    }
    return profileSetupController.getProfile(uid);
  }

  String _resolveAuthorName({
    required AuthUser currentUser,
    required UserProfile? profile,
  }) {
    final profileName = profile?.nickname.trim();
    if (profileName != null && profileName.isNotEmpty) {
      return profileName;
    }

    final authName = currentUser.displayName?.trim();
    if (authName != null && authName.isNotEmpty) {
      return authName;
    }

    final email = currentUser.email?.trim();
    if (email != null && email.isNotEmpty) {
      return email.split('@').first;
    }

    return currentUser.uid;
  }

  String? _resolveAuthorAvatarUrl({
    required AuthUser currentUser,
    required UserProfile? profile,
  }) {
    final profileAvatar = profile?.avatarUrl?.trim();
    if (profileAvatar != null && profileAvatar.isNotEmpty) {
      return profileAvatar;
    }

    final authAvatar = currentUser.photoUrl?.trim();
    if (authAvatar != null && authAvatar.isNotEmpty) {
      return authAvatar;
    }

    return null;
  }

  String? _normalizeNullableText(String? value) {
    if (value == null) {
      return null;
    }
    final cleanValue = value.trim();
    return cleanValue.isEmpty ? null : cleanValue;
  }

  int _safeDecrement(int value) {
    if (value <= 0) {
      return 0;
    }
    return value - 1;
  }
}
