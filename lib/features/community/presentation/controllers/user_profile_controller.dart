import 'package:flutter/foundation.dart';

import '../../../../core/error/app_exception.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../domain/entities/post.dart';
import '../../domain/entities/user_profile_summary.dart';
import '../../domain/repositories/community_repository.dart';
import 'community_controller.dart';

class UserProfileController extends ChangeNotifier {
  final String userId;
  final CommunityRepository communityRepository;
  final AuthController authController;
  final CommunityController communityController;

  bool _isLoading = false;
  bool _isFollowSubmitting = false;
  String? _errorCode;
  UserProfileSummary? _summary;
  List<Post> _posts = const <Post>[];
  List<UserProfileSummary> _followingUsers = const <UserProfileSummary>[];
  bool _isFollowing = false;

  UserProfileController({
    required this.userId,
    required this.communityRepository,
    required this.authController,
    required this.communityController,
  });

  bool get isLoading => _isLoading;
  bool get isFollowSubmitting => _isFollowSubmitting;
  String? get errorCode => _errorCode;
  UserProfileSummary? get summary => _summary;
  List<Post> get posts => _posts;
  List<UserProfileSummary> get followingUsers => _followingUsers;
  bool get isFollowing => _isFollowing;

  bool get isCurrentUser {
    return authController.getCurrentUser()?.uid == userId;
  }

  Future<void> load() async {
    _isLoading = true;
    _errorCode = null;
    notifyListeners();

    try {
      final currentUser = authController.getCurrentUser();
      final result = await Future.wait<Object?>(<Future<Object?>>[
        communityRepository.getUserProfileSummary(userId),
        communityRepository.getPostsByUserId(userId),
        communityRepository.getFollowingUsers(userId),
        if (currentUser == null || currentUser.uid == userId)
          Future<bool>.value(false)
        else
          communityRepository.isFollowingUser(
            currentUserId: currentUser.uid,
            targetUserId: userId,
          ),
      ]);

      _summary = result[0] as UserProfileSummary?;
      _posts = result[1] as List<Post>;
      _followingUsers = result[2] as List<UserProfileSummary>;
      _isFollowing = result[3] as bool;
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

  Future<void> toggleFollow() async {
    final currentUser = authController.getCurrentUser();
    if (currentUser == null ||
        currentUser.uid == userId ||
        _isFollowSubmitting) {
      throw AppException('community_follow_failed');
    }

    final originalIsFollowing = _isFollowing;
    final originalSummary = _summary;
    final nextIsFollowing = !originalIsFollowing;

    _isFollowSubmitting = true;
    _isFollowing = nextIsFollowing;
    if (_summary != null) {
      _summary = _summary!.copyWith(
        followerCount: nextIsFollowing
            ? _summary!.followerCount + 1
            : _safeDecrement(_summary!.followerCount),
      );
    }
    notifyListeners();

    try {
      if (nextIsFollowing) {
        await communityRepository.followUser(
          currentUserId: currentUser.uid,
          targetUserId: userId,
        );
      } else {
        await communityRepository.unfollowUser(
          currentUserId: currentUser.uid,
          targetUserId: userId,
        );
      }

      await communityController.refreshFollowingPosts();
    } catch (error) {
      _isFollowing = originalIsFollowing;
      _summary = originalSummary;
      notifyListeners();
      if (error is AppException) {
        rethrow;
      }
      throw AppException('community_follow_failed');
    } finally {
      _isFollowSubmitting = false;
      notifyListeners();
    }
  }

  int _safeDecrement(int value) {
    if (value <= 0) {
      return 0;
    }
    return value - 1;
  }
}
