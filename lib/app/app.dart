import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../l10n/app_localizations.dart';
import '../l10n/l10n.dart';
import 'language_controller.dart';
import 'router.dart';

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  // 让页面可以拿到全局语言控制器
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

    // 第一次启动时，根据系统语言决定 app 语言
    final Locale systemLocale =
        WidgetsBinding.instance.platformDispatcher.locale;
    languageController.initFromSystem(systemLocale);

    // 语言改变时，刷新整个 MaterialApp
    languageController.addListener(_onLanguageChanged);
  }

  void _onLanguageChanged() {
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

      // 当前 app 使用的语言
      locale: languageController.locale,

      // 支持的语言列表
      supportedLocales: L10n.all,

      // Flutter 本地化委托
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      // 路由
      initialRoute: AppRouter.authGate,
      routes: AppRouter.routes,
    );
  }
}
