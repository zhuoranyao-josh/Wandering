import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/app.dart';
import '../../../../app/router.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/error/app_exception.dart';
import '../widgets/forgot_password_dialog.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/social_login_button.dart';
import '../../../../core/widgets/app_divider_with_text.dart';
import '../../../../l10n/app_localizations.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // 页面只依赖 Controller，不依赖 Firebase
  final _authController = ServiceLocator.authController;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isEmailLoading = false;
  bool _isGoogleLoading = false;
  bool _isGuestLoading = false;
  String? _errorCode;

  // 把错误码翻译成当前语言
  String _localizedError(AppLocalizations t, String code) {
    switch (code) {
      case 'empty_fields':
        return t.errorEmptyFields;
      case 'password_mismatch':
        return t.errorPasswordMismatch;
      case 'invalid_email':
        return t.errorInvalidEmail;
      case 'user_not_found':
        return t.errorUserNotFound;
      case 'invalid_credential':
        return t.errorInvalidCredential;
      case 'email_already_in_use':
        return t.errorEmailAlreadyInUse;
      case 'weak_password':
        return t.errorWeakPassword;
      case 'google_cancelled':
        return t.errorGoogleCancelled;
      case 'google_failed':
        return t.errorGoogleFailed;
      case 'missing_email':
        return t.errorMissingEmail;
      case 'too_many_requests':
        return t.errorTooManyRequests;
      case 'operation_not_allowed':
        return t.errorOperationNotAllowed;
      default:
        return t.errorUnknown;
    }
  }

  Future<void> _loginWithEmail() async {
    setState(() {
      _isEmailLoading = true;
      _errorCode = null;
    });

    try {
      await _authController.signInWithEmail(
        email: _emailController.text,
        password: _passwordController.text,
      );

      if (mounted) {
        Navigator.pushReplacementNamed(context, AppRouter.home);
      }
    } on AppException catch (e) {
      setState(() {
        _errorCode = e.code;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isEmailLoading = false;
        });
      }
    }
  }

  Future<void> _loginWithGoogle() async {
    setState(() {
      _isGoogleLoading = true;
      _errorCode = null;
    });

    try {
      await _authController.signInWithGoogle();

      if (mounted) {
        Navigator.pushReplacementNamed(context, AppRouter.home);
      }
    } on AppException catch (e) {
      setState(() {
        _errorCode = e.code;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isGoogleLoading = false;
        });
      }
    }
  }

  Future<void> _loginAsGuest() async {
    setState(() {
      _isGuestLoading = true;
      _errorCode = null;
    });

    try {
      await _authController.signInAnonymously();

      if (mounted) {
        Navigator.pushReplacementNamed(context, AppRouter.home);
      }
    } on AppException catch (e) {
      setState(() {
        _errorCode = e.code;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isGuestLoading = false;
        });
      }
    }
  }

  void _openForgotPasswordDialog() {
    showDialog(context: context, builder: (_) => const ForgotPasswordDialog());
  }

  void _toggleLanguage() {
    MyApp.of(context)?.toggle();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F3F3),
      extendBodyBehindAppBar: true,

      appBar: AppBar(
        title: Text(t.login),
        centerTitle: true,
        // 让 AppBar 透明
        backgroundColor: Colors.transparent,
        // 去掉阴影（否则会有一条线）
        elevation: 0,
        // 状态栏沉浸（背景延伸到顶部）
        systemOverlayStyle: SystemUiOverlayStyle.dark,

        // 左上角返回按钮
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          // 点击返回 welcome page
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 90),
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 20),

                AppTextField(
                  label: t.email,
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),

                AppTextField(
                  label: t.password,
                  controller: _passwordController,
                  obscureText: true,
                ),
                const SizedBox(height: 16),

                if (_errorCode != null)
                  Text(
                    _localizedError(t, _errorCode!),
                    style: const TextStyle(color: Colors.red),
                  ),

                const SizedBox(height: 16),

                AppButton(
                  text: t.login,
                  onPressed: _loginWithEmail,
                  isLoading: _isEmailLoading,
                  styleType: AppButtonStyleType.blackFilled,
                ),

                const SizedBox(height: 18),

                // 这里是一条横线，中间写 or
                // 常用于表示“下面还有其他登录方式”
                AppDividerWithText(text: t.orText),

                const SizedBox(height: 18),

                SocialLoginButton(
                  text: t.loginWithGoogle,
                  onPressed: _loginWithGoogle,
                  isLoading: _isGoogleLoading,

                  // 这里使用本地图标资源作为 Google logo
                  icon: Image.asset(
                    'assets/icons/google_logo.png',
                    width: 20,
                    height: 20,
                  ),
                ),

                const SizedBox(height: 12),

                AppButton(
                  text: t.loginAsGuest,
                  onPressed: _loginAsGuest,
                  isLoading: _isGuestLoading,
                  styleType: AppButtonStyleType.whiteOutlined,
                ),

                const SizedBox(height: 12),

                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, AppRouter.register);
                  },
                  child: Text(t.goToRegister),
                ),

                TextButton(
                  onPressed: _openForgotPasswordDialog,
                  child: Text(t.forgotPassword),
                ),
              ],
            ),
          ),
        ),
      ),

      // 右下角地球按钮：切换中英文
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: FloatingActionButton.small(
        onPressed: _toggleLanguage,
        child: const Icon(Icons.language),
      ),
    );
  }
}
