import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_remote_data_source.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDataSource remoteDataSource;

  ProfileRepositoryImpl(this.remoteDataSource);

  @override
  Future<bool> isProfileCompleted(String uid) {
    return remoteDataSource.isProfileCompleted(uid);
  }

  @override
  Future<UserProfile?> getProfile(String uid) {
    return remoteDataSource.getProfile(uid);
  }

  @override
  Future<void> saveProfile(UserProfile profile, {String? avatarLocalPath}) {
    return remoteDataSource.saveProfile(
      profile,
      avatarLocalPath: avatarLocalPath,
    );
  }
}
