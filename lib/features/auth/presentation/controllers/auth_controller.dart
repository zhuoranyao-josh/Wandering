import '../../../../core/error/app_exception.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthController {
  final AuthRepository authRepository;

  AuthController(this.authRepository);

  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    // ❗规则1：邮箱或密码不能为空
    // trim() 是去掉前后空格，防止用户输入空格也通过
    if (email.trim().isEmpty || password.trim().isEmpty) {
      throw AppException('empty_fields');
    }

    // 如果通过了上面的检查，就调用仓库去真正登录
    await authRepository.signInWithEmail(email: email, password: password);
  }

  Future<void> signUpWithEmail({
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    // ❗规则1：所有输入框都必须填写
    if (email.trim().isEmpty ||
        password.trim().isEmpty ||
        confirmPassword.trim().isEmpty) {
      throw AppException('empty_fields');
    }

    // ❗规则2：两次密码必须一致
    if (password != confirmPassword) {
      throw AppException('password_mismatch');
    }

    // ❗规则3：密码长度至少6位（Firebase默认要求）
    if (password.length < 6) {
      throw AppException('weak_password');
    }

    // 所有规则通过后，才真正去注册
    await authRepository.signUpWithEmail(email: email, password: password);
  }

  Future<void> signInWithGoogle() async {
    await authRepository.signInWithGoogle();
  }

  Future<void> signInAnonymously() async {
    await authRepository.signInAnonymously();
  }

  Future<void> sendPasswordResetEmail({required String email}) async {
    if (email.trim().isEmpty) {
      throw AppException('empty_fields');
    }

    await authRepository.sendPasswordResetEmail(email: email);
  }

  Future<void> signOut() async {
    await authRepository.signOut();
  }

  Stream<AuthUser?> authStateChanges() {
    return authRepository.authStateChanges();
  }

  AuthUser? getCurrentUser() {
    return authRepository.getCurrentUser();
  }
}
