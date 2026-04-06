import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/error/app_exception.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../l10n/app_localizations.dart';

class ForgotPasswordDialog extends StatefulWidget {
  const ForgotPasswordDialog({super.key});

  @override
  State<ForgotPasswordDialog> createState() => _ForgotPasswordDialogState();
}

class _ForgotPasswordDialogState extends State<ForgotPasswordDialog> {
  final TextEditingController _emailController = TextEditingController();

  bool _isLoading = false;
  String? _errorCode;
  bool _isSuccess = false;

  String _localizedError(AppLocalizations t, String code) {
    switch (code) {
      case 'empty_fields':
        return t.errorEmptyFields;
      case 'invalid_email':
        return t.errorInvalidEmail;
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

  Future<void> _sendResetEmail() async {
    setState(() {
      _isLoading = true;
      _errorCode = null;
      _isSuccess = false;
    });

    try {
      await ServiceLocator.authController.sendPasswordResetEmail(
        email: _emailController.text,
      );

      setState(() {
        _isSuccess = true;
      });
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    if (t == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return AlertDialog(
      title: Text(t.forgotPassword),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(t.resetPasswordHint, style: const TextStyle(fontSize: 14)),
          const SizedBox(height: 16),
          AppTextField(
            label: t.email,
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 12),
          if (_errorCode != null)
            Text(
              _localizedError(t, _errorCode!),
              style: const TextStyle(color: Colors.red),
            ),
          if (_isSuccess)
            Text(
              t.resetPasswordEmailSent,
              style: const TextStyle(color: Colors.green),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading
              ? null
              : () {
                  if (context.canPop()) {
                    context.pop();
                  }
                },
          child: Text(t.cancel),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _sendResetEmail,
          child: _isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(t.sendResetEmail),
        ),
      ],
    );
  }
}
