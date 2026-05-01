import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/services.dart';

import '../core/system_ui/app_system_ui.dart';
import '../l10n/app_localizations.dart';
import '../l10n/l10n.dart';
import 'app_router.dart';
import 'language_controller.dart';

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  static LanguageController? of(BuildContext context) {
    final _MyAppState? state = context.findAncestorStateOfType<_MyAppState>();
    return state?.languageController;
  }

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final LanguageController languageController = LanguageController();
  static const List<String> _zhModeCjkFallbackFonts = <String>[
    'PingFang SC',
    'Hiragino Sans GB',
    'Noto Sans CJK SC',
    'Noto Sans SC',
    'Microsoft YaHei',
    'WenQuanYi Micro Hei',
  ];
  static const List<String> _enModeCjkFallbackFonts = <String>[
    'Noto Sans CJK SC',
    'Noto Sans SC',
    'PingFang SC',
    'Hiragino Sans GB',
    'Microsoft YaHei',
    'WenQuanYi Micro Hei',
  ];

  @override
  void initState() {
    super.initState();
    _initLanguage();
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
    final bool isEnglishMode = languageController.locale.languageCode == 'en';
    final fallbackFonts = isEnglishMode
        ? _enModeCjkFallbackFonts
        : _zhModeCjkFallbackFonts;
    final baseTheme = ThemeData.light();
    final themed = baseTheme.copyWith(
      // Keep default Latin font behavior, but ensure CJK characters
      // resolve to a consistent Chinese-capable fallback chain.
      textTheme: baseTheme.textTheme.apply(
        fontFamilyFallback: fallbackFonts,
      ),
      primaryTextTheme: baseTheme.primaryTextTheme.apply(
        fontFamilyFallback: fallbackFonts,
      ),
    );

    return MaterialApp.router(
      title: 'wandering',
      debugShowCheckedModeBanner: false,
      locale: languageController.locale,
      theme: themed,
      supportedLocales: L10n.all,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        // 全局默认系统栏样式：状态栏透明常驻，普通页面使用深色图标。
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: AppSystemUi.defaultOverlayStyle,
          child: child ?? const SizedBox.shrink(),
        );
      },
      routerConfig: AppRouter.router,
    );
  }
}
