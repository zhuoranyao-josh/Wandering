import '../../../../core/error/app_exception.dart';
import '../../../auth/domain/entities/auth_user.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/profile_repository.dart';

class ProfileSetupController {
  final ProfileRepository profileRepository;

  ProfileSetupController(this.profileRepository);

  Future<bool> isProfileCompleted(String uid) {
    return profileRepository.isProfileCompleted(uid);
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
  }
}
