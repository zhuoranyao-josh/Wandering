import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/app_router.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../l10n/app_localizations.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    if (t == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final user = ServiceLocator.authController.getCurrentUser();

    return Scaffold(
      appBar: AppBar(title: Text(t.homeTitle), centerTitle: true),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                t.loginSuccess,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text('${t.uidLabel}: ${user?.uid ?? "-"}'),
              const SizedBox(height: 8),
              Text('${t.emailLabel}: ${user?.email ?? "-"}'),
              const SizedBox(height: 8),
              Text('${t.nameLabel}: ${user?.displayName ?? "-"}'),
              const SizedBox(height: 24),
              ElevatedButton(
                // 退出登录按钮：清除当前登录状态并返回登录页。
                onPressed: () async {
                  await ServiceLocator.authController.signOut();
                  if (context.mounted) {
                    // 退出后用 go 跳转，避免回退再回到已登录页面。
                    context.go(AppRouter.login);
                  }
                },
                child: Text(t.logout),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
