import '../../domain/entities/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;

  AuthRepositoryImpl(this.remoteDataSource);

  @override
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) {
    return remoteDataSource.signInWithEmail(email: email, password: password);
  }

  @override
  Future<void> signUpWithEmail({
    required String email,
    required String password,
  }) {
    return remoteDataSource.signUpWithEmail(email: email, password: password);
  }

  @override
  Future<void> signInWithGoogle() {
    return remoteDataSource.signInWithGoogle();
  }

  @override
  Future<void> signInAnonymously() {
    return remoteDataSource.signInAnonymously();
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) {
    return remoteDataSource.sendPasswordResetEmail(email: email);
  }

  @override
  Future<void> signOut() {
    return remoteDataSource.signOut();
  }

  @override
  Stream<AuthUser?> authStateChanges() {
    return remoteDataSource.authStateChanges();
  }

  @override
  AuthUser? getCurrentUser() {
    return remoteDataSource.getCurrentUser();
  }
}
