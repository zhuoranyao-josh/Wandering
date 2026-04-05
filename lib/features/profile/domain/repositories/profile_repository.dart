import '../entities/user_profile.dart';

abstract class ProfileRepository {
  Future<bool> isProfileCompleted(String uid);

  Future<void> saveProfile(UserProfile profile, {String? avatarLocalPath});

  Future<UserProfile?> getProfile(String uid);
}
