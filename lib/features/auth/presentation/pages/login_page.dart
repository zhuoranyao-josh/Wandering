import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/app.dart';
import '../../../../app/app_router.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/error/app_exception.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_divider_with_text.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/social_login_button.dart';
import '../../../../l10n/app_localizations.dart';
import '../widgets/forgot_password_dialog.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _authController = ServiceLocator.authController;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isEmailLoading = false;
  bool _isGoogleLoading = false;
  bool _isGuestLoading = false;
  String? _errorCode;

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
        context.go(AppRouter.authGate);
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
        context.go(AppRouter.authGate);
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
        context.go(AppRouter.home);
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

  Future<void> _toggleLanguage() async {
    await MyApp.of(context)?.toggleAndSave();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    if (t == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF3F3F3),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(t.login),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            context.go(AppRouter.welcome);
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
                AppDividerWithText(text: t.orText),
                const SizedBox(height: 18),
                SocialLoginButton(
                  text: t.loginWithGoogle,
                  onPressed: _loginWithGoogle,
                  isLoading: _isGoogleLoading,
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
                    context.push(AppRouter.register);
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
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: FloatingActionButton.small(
        onPressed: _toggleLanguage,
        child: const Icon(Icons.language),
      ),
    );
  }
}
