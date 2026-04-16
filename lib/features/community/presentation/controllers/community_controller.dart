import 'package:flutter/foundation.dart';

import '../../../../core/error/app_exception.dart';
import '../../../auth/domain/entities/auth_user.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../profile/domain/entities/user_profile.dart';
import '../../../profile/presentation/controllers/profile_setup_controller.dart';
import '../../domain/entities/post.dart';
import '../../domain/repositories/community_repository.dart';

class CommunityController extends ChangeNotifier {
  final CommunityRepository communityRepository;
  final AuthController authController;
  final ProfileSetupController profileSetupController;

  bool _isInitialized = false;
  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _errorCode;
  List<Post> _latestPosts = const <Post>[];

  CommunityController({
    required this.communityRepository,
    required this.authController,
    required this.profileSetupController,
  });

  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get errorCode => _errorCode;
  List<Post> get latestPosts => _latestPosts;

  void upsertPost(Post post) {
    final existingIndex = _latestPosts.indexWhere((item) => item.id == post.id);
    if (existingIndex == -1) {
      _latestPosts = <Post>[post, ..._latestPosts];
    } else {
      final updatedPosts = List<Post>.from(_latestPosts);
      updatedPosts[existingIndex] = post;
      _latestPosts = updatedPosts;
    }
    notifyListeners();
  }

  void ensureInitialized() {
    if (_isInitialized) return;
    _isInitialized = true;
    refreshLatestPosts();
  }

  Future<void> refreshLatestPosts() async {
    _isLoading = true;
    _errorCode = null;
    notifyListeners();

    try {
      _latestPosts = await communityRepository.getLatestPosts();
      _errorCode = null;
    } catch (error) {
      if (error is AppException) {
        _errorCode = error.code;
      } else {
        _errorCode = 'community_load_failed';
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createPost({String? title, required String content}) async {
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
      );

      // 发布成功后先本地插入，确保返回列表页时能立即看到新帖子。
      _latestPosts = <Post>[
        createdPost,
        ..._latestPosts.where((post) => post.id != createdPost.id),
      ];
      _errorCode = null;
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
}
