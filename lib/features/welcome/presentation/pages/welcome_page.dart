import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/app_router.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/error/app_exception.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../l10n/app_localizations.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  final List<String> _backgroundImages = [
    'assets/images/welcome/city_1.jpg',
    'assets/images/welcome/city_2.jpg',
    'assets/images/welcome/city_3.jpg',
  ];

  int _currentIndex = 0;
  Timer? _timer;

  bool _isGuestLoading = false;
  String? _errorCode;

  @override
  void initState() {
    super.initState();

    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;

      setState(() {
        _currentIndex = (_currentIndex + 1) % _backgroundImages.length;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _localizedError(AppLocalizations t, String code) {
    switch (code) {
      case 'operation_not_allowed':
        return t.errorOperationNotAllowed;
      default:
        return t.errorUnknown;
    }
  }

  Future<void> _continueAsGuest() async {
    setState(() {
      _isGuestLoading = true;
      _errorCode = null;
    });

    try {
      await ServiceLocator.authController.signInAnonymously();

      if (mounted) {
        // 游客登录成功后直接进入首页。
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

  void _goToLoginPage() {
    // 进入登录页（使用 push，便于用户返回欢迎页）。
    context.push(AppRouter.login);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    if (t == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: Stack(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 800),
            child: SizedBox.expand(
              key: ValueKey(_backgroundImages[_currentIndex]),
              child: Image.asset(
                _backgroundImages[_currentIndex],
                fit: BoxFit.cover,
              ),
            ),
          ),
          Container(color: Colors.black.withValues(alpha: 0.25)),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
              child: Column(
                children: [
                  const Spacer(),
                  const Text(
                    'Wandering',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    t.welcomeSubtitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  const SizedBox(height: 30),
                  if (_errorCode != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        _localizedError(t, _errorCode!),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  AppButton(
                    text: t.enterLoginOrRegister,
                    // 主入口按钮：进入登录/注册流程。
                    onPressed: _goToLoginPage,
                    styleType: AppButtonStyleType.whiteOutlined,
                  ),
                  const SizedBox(height: 12),
                  AppButton(
                    text: t.loginAsGuest,
                    // 游客体验按钮：不注册也可先使用应用。
                    onPressed: _continueAsGuest,
                    isLoading: _isGuestLoading,
                    styleType: AppButtonStyleType.whiteOutlined,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
