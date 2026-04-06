import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

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
    return MaterialApp.router(
      title: 'Travel App',
      debugShowCheckedModeBanner: false,
      locale: languageController.locale,
      supportedLocales: L10n.all,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: AppRouter.router,
    );
  }
}
