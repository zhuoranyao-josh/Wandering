import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/di/service_locator.dart';
import '../features/auth/domain/entities/auth_user.dart';
import '../features/auth/presentation/pages/login_page.dart';
import '../features/auth/presentation/pages/register_page.dart';
import '../features/home/presentation/pages/home_page.dart';
import '../features/profile/presentation/pages/profile_setup_page.dart';
import '../features/welcome/presentation/pages/welcome_page.dart';

class AppRouter {
  static const String authGate = '/';
  static const String welcome = '/welcome';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String profileSetup = '/profile-setup';

  static final Set<String> _publicRoutes = <String>{
    welcome,
    login,
    register,
  };

  static final GoRouter router = GoRouter(
    initialLocation: authGate,
    refreshListenable: GoRouterRefreshStream(
      ServiceLocator.authController.authStateChanges(),
    ),
    redirect: (BuildContext context, GoRouterState state) async {
      final String location = state.matchedLocation;
      final AuthUser? user = ServiceLocator.authController.getCurrentUser();

      if (user == null) {
        return _redirectUnauthenticated(location);
      }

      if (user.isAnonymous) {
        return _redirectAuthenticated(
          location: location,
          target: home,
        );
      }

      final bool isCompleted;

      try {
        isCompleted = await ServiceLocator
            .profileSetupController
            .isProfileCompleted(user.uid);
      } catch (_) {
        return _redirectAuthenticated(
          location: location,
          target: profileSetup,
        );
      }

      if (!isCompleted) {
        return _redirectAuthenticated(
          location: location,
          target: profileSetup,
        );
      }

      return _redirectAuthenticated(
        location: location,
        target: home,
      );
    },
    routes: <RouteBase>[
      GoRoute(
        path: authGate,
        builder: (BuildContext context, GoRouterState state) {
          return const _RouteResolverPage();
        },
      ),
      GoRoute(
        path: welcome,
        builder: (BuildContext context, GoRouterState state) {
          return const WelcomePage();
        },
      ),
      GoRoute(
        path: login,
        builder: (BuildContext context, GoRouterState state) {
          return const LoginPage();
        },
      ),
      GoRoute(
        path: register,
        builder: (BuildContext context, GoRouterState state) {
          return const RegisterPage();
        },
      ),
      GoRoute(
        path: home,
        builder: (BuildContext context, GoRouterState state) {
          return const HomePage();
        },
      ),
      GoRoute(
        path: profileSetup,
        builder: (BuildContext context, GoRouterState state) {
          return const ProfileSetupPage();
        },
      ),
    ],
    errorBuilder: (BuildContext context, GoRouterState state) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Route not found: ${state.uri}'),
          ),
        ),
      );
    },
  );

  static String? _redirectUnauthenticated(String location) {
    if (_publicRoutes.contains(location)) {
      return null;
    }

    if (location == authGate) {
      return welcome;
    }

    return welcome;
  }

  static String? _redirectAuthenticated({
    required String location,
    required String target,
  }) {
    if (location == target) {
      return null;
    }

    if (location == authGate) {
      return target;
    }

    if (_publicRoutes.contains(location)) {
      return target;
    }

    if (target == profileSetup && location != profileSetup) {
      return profileSetup;
    }

    if (target == home && location != home) {
      return home;
    }

    return null;
  }
}

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.asBroadcastStream().listen(
      (_) => notifyListeners(),
    );
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

class _RouteResolverPage extends StatelessWidget {
  const _RouteResolverPage();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
