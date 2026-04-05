import 'package:flutter/material.dart';

import '../../../../app/router.dart';
import '../../../../core/di/service_locator.dart';
import '../../../auth/domain/entities/auth_user.dart';
import '../../../home/presentation/pages/home_page.dart';
import '../../../profile/presentation/pages/profile_setup_page.dart';
import '../../../welcome/presentation/pages/welcome_page.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final _authController = ServiceLocator.authController;
  final _profileController = ServiceLocator.profileSetupController;

  @override
  Widget build(BuildContext context) {
    final AuthUser? user = _authController.getCurrentUser();

    // 没登录 → WelcomePage
    if (user == null) {
      return const WelcomePage();
    }

    // 游客 → 直接进 Home
    if (user.isAnonymous) {
      return const HomePage();
    }

    // 非游客用户 → 检查资料是否完成
    return FutureBuilder<bool>(
      future: _profileController.isProfileCompleted(user.uid),
      builder: (context, snapshot) {
        // 加载中
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // 出错
        if (snapshot.hasError) {
          return const Scaffold(
            body: Center(child: Text('Something went wrong')),
          );
        }

        final completed = snapshot.data ?? false;

        if (completed) {
          return const HomePage();
        } else {
          return const ProfileSetupPage();
        }
      },
    );
  }
}
