import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/router.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/error/app_exception.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _authController = ServiceLocator.authController;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
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
      default:
        return t.errorUnknown;
    }
  }

  Future<void> _register() async {
    setState(() {
      _isLoading = true;
      _errorCode = null;
    });

    try {
      await _authController.signUpWithEmail(
        email: _emailController.text,
        password: _passwordController.text,
        confirmPassword: _confirmPasswordController.text,
      );

      if (mounted) {
        Navigator.pushReplacementNamed(context, AppRouter.authGate);
      }
    } on AppException catch (e) {
      setState(() {
        _errorCode = e.code;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
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
        title: Text(t.register),
        centerTitle: true,
        // 让 AppBar 透明
        backgroundColor: Colors.transparent,
        // 去掉阴影（否则会有一条线）
        elevation: 0,
        // 状态栏沉浸（背景延伸到顶部）
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
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

                AppTextField(
                  label: t.confirmPassword,
                  controller: _confirmPasswordController,
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
                  text: t.register,
                  onPressed: _register,
                  isLoading: _isLoading,
                  styleType: AppButtonStyleType.blackFilled,
                ),

                const SizedBox(height: 12),

                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text(t.backToLogin),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
