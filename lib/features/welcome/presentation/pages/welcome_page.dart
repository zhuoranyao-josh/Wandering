import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../app/router.dart';
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
  // 这里放欢迎页轮播用的城市背景图
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

    // 页面一打开，就每隔 4 秒切换一张背景图
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;

      setState(() {
        _currentIndex = (_currentIndex + 1) % _backgroundImages.length;
      });
    });
  }

  @override
  void dispose() {
    // 页面销毁时记得取消定时器，避免内存泄漏
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
      // 这里没有直接写 Firebase，而是走 controller
      // 这样仍然遵守“页面层不碰 Firebase”的规则
      await ServiceLocator.authController.signInAnonymously();

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

  void _goToLoginPage() {
    Navigator.pushNamed(context, AppRouter.login);
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
          // 背景图切换
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

          // 加一层半透明黑色遮罩，保证白色按钮和文字更清楚
          Container(color: Colors.black.withValues(alpha: 0.25)),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
              child: Column(
                children: [
                  const Spacer(),

                  // 这里可以放 app 名字或 slogan
                  Text(
                    'Wandering',
                    style: const TextStyle(
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

                  // 注册 / 登录按钮
                  AppButton(
                    text: t.enterLoginOrRegister,
                    onPressed: _goToLoginPage,
                    styleType: AppButtonStyleType.whiteOutlined,
                  ),

                  const SizedBox(height: 12),

                  // 游客身份登录按钮
                  AppButton(
                    text: t.loginAsGuest,
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
