import '../../domain/entities/auth_user.dart';

abstract class AuthRemoteDataSource {
  Future<void> signInWithEmail({
    required String email,
    required String password,
  });

  Future<void> signUpWithEmail({
    required String email,
    required String password,
  });

  Future<void> signInWithGoogle();

  Future<void> signInAnonymously();

  Future<void> sendPasswordResetEmail({required String email});

  Future<void> signOut();

  Stream<AuthUser?> authStateChanges();

  AuthUser? getCurrentUser();
}
