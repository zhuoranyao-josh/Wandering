import 'package:flutter/material.dart';

import '../features/auth/presentation/pages/login_page.dart';
import '../features/auth/presentation/pages/register_page.dart';
import '../features/home/presentation/pages/home_page.dart';
import '../features/navigation/presentation/pages/auth_gate.dart';
import '../features/welcome/presentation/pages/welcome_page.dart';
import '../features/profile/presentation/pages/profile_setup_page.dart';

class AppRouter {
  static const String authGate = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String welcome = '/welcome';
  static const String profileSetup = '/profile-setup';

  static final Map<String, WidgetBuilder> routes = {
    login: (context) => const LoginPage(),
    register: (context) => const RegisterPage(),
    home: (context) => const HomePage(),
    welcome: (context) => const WelcomePage(),
    profileSetup: (context) => const ProfileSetupPage(),
  };
}
