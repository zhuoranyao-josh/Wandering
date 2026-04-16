import 'package:flutter/foundation.dart';

import '../../../../core/error/app_exception.dart';
import '../../../auth/domain/entities/auth_user.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../profile/domain/entities/user_profile.dart';
import '../../../profile/presentation/controllers/profile_setup_controller.dart';
import '../../domain/entities/comment.dart';
import '../../domain/entities/post.dart';
import '../../domain/repositories/community_repository.dart';
import 'community_controller.dart';

class PostDetailController extends ChangeNotifier {
  final String postId;
  final CommunityRepository communityRepository;
  final AuthController authController;
  final ProfileSetupController profileSetupController;
  final CommunityController communityController;

  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _errorCode;
  Post? _post;
  List<Comment> _comments = const <Comment>[];
  Comment? _replyTarget;
  final Set<String> _expandedCommentIds = <String>{};

  PostDetailController({
    required this.postId,
    required this.communityRepository,
    required this.authController,
    required this.profileSetupController,
    required this.communityController,
  });

  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get errorCode => _errorCode;
  Post? get post => _post;
  List<Comment> get comments => _comments;
  Comment? get replyTarget => _replyTarget;

  List<Comment> get topLevelComments {
    return _comments
        .where((comment) => comment.isTopLevel)
        .toList(growable: false)
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  Future<void> load() async {
    _isLoading = true;
    _errorCode = null;
    notifyListeners();

    try {
      await _loadPostAndComments();
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

  Future<void> refresh() async {
    try {
      await _loadPostAndComments();
      _errorCode = null;
      notifyListeners();
    } catch (error) {
      if (error is AppException) {
        _errorCode = error.code;
      } else {
        _errorCode = 'community_load_failed';
      }
      notifyListeners();
    }
  }

  void startReply(Comment target) {
    _replyTarget = target;
    notifyListeners();
  }

  void clearReplyTarget() {
    if (_replyTarget == null) return;
    _replyTarget = null;
    notifyListeners();
  }

  bool isExpanded(String commentId) {
    return _expandedCommentIds.contains(commentId);
  }

  void toggleReplies(String commentId) {
    if (_expandedCommentIds.contains(commentId)) {
      _expandedCommentIds.remove(commentId);
    } else {
      _expandedCommentIds.add(commentId);
    }
    notifyListeners();
  }

  List<Comment> repliesFor(String commentId) {
    return _comments
        .where((comment) => comment.parentCommentId == commentId)
        .toList(growable: false)
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  Future<void> submitComment(String content) async {
    final cleanContent = content.trim();
    if (cleanContent.isEmpty) {
      throw AppException('community_comment_empty');
    }

    if (_isSubmitting) return;

    _isSubmitting = true;
    notifyListeners();

    try {
      final currentUser = authController.getCurrentUser();
      if (currentUser == null) {
        throw AppException('community_comment_submit_failed');
      }

      final authorProfile = await _loadAuthorProfile(currentUser.uid);
      final authorName = _resolveAuthorName(
        currentUser: currentUser,
        profile: authorProfile,
      );
      final authorAvatarUrl = _resolveAuthorAvatarUrl(
        currentUser: currentUser,
        profile: authorProfile,
      );

      if (_replyTarget == null) {
        await communityRepository.addComment(
          postId: postId,
          userId: currentUser.uid,
          userName: authorName,
          userAvatarUrl: authorAvatarUrl,
          content: cleanContent,
        );
      } else {
        await communityRepository.replyToComment(
          postId: postId,
          parentCommentId: _replyTarget!.id,
          userId: currentUser.uid,
          userName: authorName,
          userAvatarUrl: authorAvatarUrl,
          content: cleanContent,
          replyToUserName: _replyTarget!.userName,
        );
      }

      _replyTarget = null;
      await _loadPostAndComments();
      _errorCode = null;
      notifyListeners();
    } catch (error) {
      if (error is AppException) {
        rethrow;
      }
      throw AppException('community_comment_submit_failed');
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<void> _loadPostAndComments() async {
    final results = await Future.wait<Object?>(<Future<Object?>>[
      communityRepository.getPostById(postId),
      communityRepository.getCommentsByPostId(postId),
    ]);

    _post = results[0] as Post?;
    _comments = (results[1] as List<Comment>).toList(growable: false);

    if (_post != null) {
      communityController.upsertPost(_post!);
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
}
