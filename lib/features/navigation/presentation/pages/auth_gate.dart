import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../../auth/domain/entities/auth_user.dart';
import '../../../home/presentation/pages/home_page.dart';
import '../../../welcome/presentation/pages/welcome_page.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    // 用 StreamBuilder 监听登录状态
    return StreamBuilder<AuthUser?>(
      stream: ServiceLocator.authController.authStateChanges(),
      builder: (context, snapshot) {
        // 等待 Firebase 返回当前登录状态
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // 有用户：进主页
        if (snapshot.data != null) {
          return const HomePage();
        }

        // 如果还没有用户，就进入欢迎页
        return const WelcomePage();
      },
    );
  }
}
