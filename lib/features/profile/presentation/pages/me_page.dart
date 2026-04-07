import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/app_router.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/domain/entities/auth_user.dart';
import '../../domain/entities/user_profile.dart';

class MePage extends StatefulWidget {
  const MePage({super.key});

  @override
  State<MePage> createState() => _MePageState();
}

class _MePageState extends State<MePage> {
  UserProfile? _profile;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    final user = ServiceLocator.authController.getCurrentUser();
    if (user != null) {
      _profile = ServiceLocator.profileSetupController.getCachedProfile(
        user.uid,
      );
      _refreshProfile();
    }
  }

  Future<void> _refreshProfile() async {
    final user = ServiceLocator.authController.getCurrentUser();
    if (user == null) return;

    setState(() {
      _isRefreshing = true;
    });

    final refreshed = await ServiceLocator.profileSetupController
        .refreshProfile(user.uid);

    if (!mounted) return;
    setState(() {
      _profile = refreshed;
      _isRefreshing = false;
    });
  }

  String _displayName(AuthUser? user, AppLocalizations t) {
    if (_profile?.nickname.isNotEmpty ?? false) {
      return _profile!.nickname;
    }
    if (user?.displayName?.isNotEmpty ?? false) {
      return user!.displayName!;
    }
    return t.defaultUserName;
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    if (t == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final user = ServiceLocator.authController.getCurrentUser();
    final avatarUrl = _profile?.avatarUrl ?? user?.photoUrl;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // 个人信息卡片：展示头像、昵称和编辑入口。
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                          ? NetworkImage(avatarUrl)
                          : null,
                      child: avatarUrl == null || avatarUrl.isEmpty
                          ? const Icon(Icons.person)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _displayName(user, t),
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (_isRefreshing)
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    IconButton(
                      // 进入资料编辑页；返回后刷新最新资料。
                      onPressed: () async {
                        await context.push(AppRouter.profileEdit);
                        if (!mounted) return;
                        await _refreshProfile();
                      },
                      icon: const Icon(Icons.chevron_right),
                      splashRadius: 20,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    await ServiceLocator.authController.signOut();
                    if (!mounted) return;
                    context.go(AppRouter.welcome);
                  },
                  child: Text(t.logout),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
