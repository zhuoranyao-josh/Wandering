import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/app.dart';
import '../../../../app/app_router.dart';
import '../../../../app/language_controller.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/widgets/app_network_image.dart';
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

  String _languageLabel(AppLocalizations t, Locale locale) {
    if (locale.languageCode == 'zh') {
      return t.languageChinese;
    }
    return t.languageEnglish;
  }

  // 语言选择弹窗：展示当前支持语言，并对当前项做高亮标记。
  Future<void> _showLanguageDialog(AppLocalizations t) async {
    final languageController = MyApp.of(context);
    if (languageController == null) {
      return;
    }

    final currentLocale = languageController.locale;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(t.language),
          contentPadding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildLanguageOption(
                dialogContext: dialogContext,
                controller: languageController,
                locale: const Locale('zh'),
                currentLocale: currentLocale,
                label: t.languageChinese,
              ),
              _buildLanguageOption(
                dialogContext: dialogContext,
                controller: languageController,
                locale: const Locale('en'),
                currentLocale: currentLocale,
                label: t.languageEnglish,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLanguageOption({
    required BuildContext dialogContext,
    required LanguageController controller,
    required Locale locale,
    required Locale currentLocale,
    required String label,
  }) {
    final isSelected = currentLocale.languageCode == locale.languageCode;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      leading: Icon(
        isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
        color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF9CA3AF),
      ),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
      onTap: () async {
        // 切换后立即生效，并由现有 languageController 完成本地持久化。
        if (!isSelected) {
          await controller.setLocaleAndSave(locale);
        }
        if (!dialogContext.mounted) return;
        Navigator.of(dialogContext).pop();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    if (t == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final user = ServiceLocator.authController.getCurrentUser();
    final avatarUrl = _profile?.avatarUrl ?? user?.photoUrl;
    final languageController = MyApp.of(context);
    final currentLocale = languageController?.locale ?? const Locale('en');

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // 个人信息卡片：展示头像、昵称和资料编辑入口。
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
                    _ProfileAvatar(avatarUrl: avatarUrl),
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
              // 语言设置入口：保持现有卡片风格，仅插入一个轻量操作项。
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  leading: const Icon(Icons.language_rounded),
                  title: Text(t.language),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _languageLabel(t, currentLocale),
                        style: const TextStyle(
                          color: Color(0xFF6B7280),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                  onTap: () => _showLanguageDialog(t),
                ),
              ),
              if ((_profile?.role ?? 'user') == 'admin') ...[
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.admin_panel_settings_outlined),
                    title: Text(t.adminMode),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push(AppRouter.adminDashboard),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    await ServiceLocator.authController.signOut();
                    if (!context.mounted) return;
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

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.avatarUrl});

  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    final cleanAvatarUrl = avatarUrl?.trim() ?? '';
    return CircleAvatar(
      radius: 24,
      backgroundColor: const Color(0xFFE5E7EB),
      child: cleanAvatarUrl.isNotEmpty
          ? ClipOval(
              child: SizedBox.expand(
                child: AppNetworkImage(
                  imageUrl: cleanAvatarUrl,
                  pageName: 'profile.meAvatar',
                  fit: BoxFit.cover,
                  placeholderBuilder: (context) => _buildFallback(),
                  errorBuilder: (context, error) => _buildFallback(),
                ),
              ),
            )
          : _buildFallback(),
    );
  }

  Widget _buildFallback() {
    return const Icon(Icons.person);
  }
}
