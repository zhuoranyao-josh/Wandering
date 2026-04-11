import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'app/app.dart';
import 'core/config/mapbox_config.dart';
import 'core/di/service_locator.dart';
import 'core/system_ui/app_system_ui.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 应用默认保持顶部状态栏常驻，底部系统导航栏正常显示。
  await AppSystemUi.applyDefaultSystemUi();

  MapboxConfig.initialize();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  ServiceLocator.setup();

  runApp(const MyApp());
}
