import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../l10n/app_localizations.dart';
import '../features/navigation/presentation/pages/auth_gate.dart';
import '../l10n/l10n.dart';
import 'language_controller.dart';
import 'router.dart';

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  // 让子页面可以拿到全局语言控制器
  static LanguageController? of(BuildContext context) {
    final _MyAppState? state = context.findAncestorStateOfType<_MyAppState>();
    return state?.languageController;
  }

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final LanguageController languageController = LanguageController();

  @override
  void initState() {
    super.initState();
    // 初始化语言（异步）
    _initLanguage();

    // 监听语言变化 → 刷新 UI
    languageController.addListener(_onLanguageChanged);
  }

  Future<void> _initLanguage() async {
    final systemLocale = WidgetsBinding.instance.platformDispatcher.locale;

    await languageController.init(systemLocale);

    if (!mounted) return;
    setState(() {});
  }

  void _onLanguageChanged() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  void dispose() {
    languageController.removeListener(_onLanguageChanged);
    languageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Travel App',
      debugShowCheckedModeBanner: false,

      // 多语言
      locale: languageController.locale,
      supportedLocales: L10n.all,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      // 路由表（供 pushNamed 使用）
      routes: AppRouter.routes,

      // 防止未知路由直接崩溃
      onUnknownRoute: (settings) {
        print('❌ Unknown route: ${settings.name}');
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('Route not found: ${settings.name}')),
          ),
        );
      },

      // App入口
      home: const AuthGate(),
    );
  }
}
