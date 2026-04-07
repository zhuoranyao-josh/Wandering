import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../core/error/app_exception.dart';
import '../../../auth/domain/entities/auth_user.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/profile_repository.dart';

class ProfileSetupController extends ChangeNotifier {
  final ProfileRepository profileRepository;
  String? _cachedUid;
  bool? _cachedIsCompleted;
  UserProfile? _cachedProfile;
  Future<void>? _warmupFuture;

  ProfileSetupController(this.profileRepository);

  String? get cachedUid => _cachedUid;
  bool? get cachedIsCompleted => _cachedIsCompleted;

  bool hasCompletionCacheFor(String uid) {
    return _cachedUid == uid && _cachedIsCompleted != null;
  }

  UserProfile? getCachedProfile(String uid) {
    if (_cachedUid != uid) return null;
    return _cachedProfile;
  }

  Future<void> warmUpProfileStatus(String uid, {bool forceRefresh = false}) {
    if (!forceRefresh && hasCompletionCacheFor(uid)) {
      return Future<void>.value();
    }

    final running = _warmupFuture;
    if (running != null) {
      return running;
    }

    _warmupFuture = _loadAndCacheProfile(uid).whenComplete(() {
      _warmupFuture = null;
    });
    return _warmupFuture!;
  }

  Future<UserProfile?> refreshProfile(String uid) async {
    await _loadAndCacheProfile(uid);
    return getCachedProfile(uid);
  }

  void clearCache() {
    _cachedUid = null;
    _cachedIsCompleted = null;
    _cachedProfile = null;
    notifyListeners();
  }

  Future<bool> isProfileCompleted(String uid) {
    return profileRepository.isProfileCompleted(uid);
  }

  Future<UserProfile?> getProfile(String uid) {
    return profileRepository.getProfile(uid);
  }

  Future<void> submitProfile({
    required AuthUser currentUser,
    required String nickname,
    required DateTime? birthday,
    required String gender,
    required String? countryCode,
    required String? countryName,
    required String bio,
    String? avatarLocalPath,
  }) async {
    final cleanNickname = nickname.trim();
    final cleanBio = bio.trim();

    if (cleanNickname.isEmpty) {
      throw AppException('nickname_empty');
    }

    if (cleanNickname.length > 20) {
      throw AppException('nickname_too_long');
    }

    if (cleanBio.length > 100) {
      throw AppException('bio_too_long');
    }

    final authProvider = currentUser.isAnonymous
        ? 'anonymous'
        : (currentUser.email != null ? 'email_or_google' : 'unknown');

    final profile = UserProfile(
      uid: currentUser.uid,
      email: currentUser.email,
      authProvider: authProvider,
      isAnonymous: currentUser.isAnonymous,
      avatarUrl: currentUser.photoUrl,
      nickname: cleanNickname,
      birthday: birthday,
      gender: gender,
      countryCode: countryCode,
      countryName: countryName,
      bio: cleanBio,
      profileCompleted: true,
    );

    await profileRepository.saveProfile(
      profile,
      avatarLocalPath: avatarLocalPath,
    );

    _cachedUid = currentUser.uid;
    _cachedIsCompleted = true;
    _cachedProfile = profile;
    notifyListeners();
  }

  Future<void> _loadAndCacheProfile(String uid) async {
    try {
      final profile = await profileRepository.getProfile(uid);
      _cachedUid = uid;
      _cachedProfile = profile;
      _cachedIsCompleted = profile?.profileCompleted ?? false;
      notifyListeners();
    } catch (_) {
      _cachedUid = uid;
      _cachedProfile = null;
      _cachedIsCompleted = false;
      notifyListeners();
    }
  }
}
