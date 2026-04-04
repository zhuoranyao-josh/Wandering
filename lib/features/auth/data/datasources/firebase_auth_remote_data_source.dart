import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../../core/error/app_exception.dart';
import '../../domain/entities/auth_user.dart';
import 'auth_remote_data_source.dart';

class FirebaseAuthRemoteDataSource implements AuthRemoteDataSource {
  final FirebaseAuth firebaseAuth;
  final GoogleSignIn googleSignIn;

  FirebaseAuthRemoteDataSource({
    required this.firebaseAuth,
    required this.googleSignIn,
  });

  // 把 Firebase User 转成我们自己定义的 AuthUser
  AuthUser? _mapUser(User? user) {
    if (user == null) return null;

    return AuthUser(
      uid: user.uid,
      email: user.email,
      displayName: user.displayName,
      photoUrl: user.photoURL,
    );
  }

  @override
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      await firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
    } on FirebaseAuthException catch (e) {
      throw AppException(_mapFirebaseErrorCode(e.code));
    } catch (_) {
      throw AppException('unknown');
    }
  }

  @override
  Future<void> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      await firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
    } on FirebaseAuthException catch (e) {
      // 先把真实报错打印出来
      print('FirebaseAuthException code: ${e.code}');
      print('FirebaseAuthException message: ${e.message}');
      throw AppException(_mapFirebaseErrorCode(e.code));
    } catch (e) {
      // 非 Firebase 错误也打印
      print('Unknown sign up error: $e');
      throw AppException('unknown');
    }
  }

  @override
  Future<void> signInWithGoogle() async {
    try {
      // 触发 Google 登录弹窗
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      // 用户手动取消
      if (googleUser == null) {
        throw AppException('google_cancelled');
      }

      // 获取 Google 身份令牌
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // 用 Google 令牌创建 Firebase Credential
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      // 登录 Firebase
      await firebaseAuth.signInWithCredential(credential);
    } on AppException {
      rethrow;
    } on FirebaseAuthException catch (e) {
      throw AppException(_mapFirebaseErrorCode(e.code));
    } catch (_) {
      throw AppException('google_failed');
    }
  }

  @override
  Future<void> signInAnonymously() async {
    try {
      await firebaseAuth.signInAnonymously();
    } on FirebaseAuthException catch (e) {
      throw AppException(_mapFirebaseErrorCode(e.code));
    } catch (_) {
      throw AppException('unknown');
    }
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {
    try {
      await firebaseAuth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw AppException(_mapFirebaseErrorCode(e.code));
    } catch (_) {
      throw AppException('unknown');
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await firebaseAuth.signOut();

      // 同时退出 Google 账号，避免下次直接复用旧会话
      await googleSignIn.signOut();
    } catch (_) {
      throw AppException('unknown');
    }
  }

  @override
  Stream<AuthUser?> authStateChanges() {
    return firebaseAuth.authStateChanges().map(_mapUser);
  }

  @override
  AuthUser? getCurrentUser() {
    return _mapUser(firebaseAuth.currentUser);
  }

  String _mapFirebaseErrorCode(String code) {
    switch (code) {
      case 'invalid-email':
        return 'invalid_email';
      case 'user-not-found':
        return 'user_not_found';
      case 'wrong-password':
      case 'invalid-credential':
        return 'invalid_credential';
      case 'email-already-in-use':
        return 'email_already_in_use';
      case 'weak-password':
        return 'weak_password';
      case 'missing-email':
        return 'missing_email';
      case 'too-many-requests':
        return 'too_many_requests';
      case 'operation-not-allowed':
        return 'operation_not_allowed';
      default:
        return 'unknown';
    }
  }
}
