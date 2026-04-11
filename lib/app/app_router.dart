import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/di/service_locator.dart';
import '../features/auth/domain/entities/auth_user.dart';
import '../features/auth/presentation/pages/login_page.dart';
import '../features/auth/presentation/pages/register_page.dart';
import '../features/main_container/presentation/pages/main_container_page.dart';
import '../features/main_container/presentation/pages/map_tab_page.dart';
import '../features/main_container/presentation/pages/placeholder_tab_page.dart';
import '../features/profile/presentation/pages/me_page.dart';
import '../features/profile/presentation/pages/profile_edit_page.dart';
import '../features/profile/presentation/pages/profile_setup_page.dart';
import '../features/welcome/presentation/pages/welcome_page.dart';

class AppRouter {
  static final RouteObserver<PageRoute<dynamic>> routeObserver =
      RouteObserver<PageRoute<dynamic>>();

  static const String authGate = '/';
  static const String welcome = '/welcome';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String profileSetup = '/profile-setup';
  static const String profileEdit = '/profile-edit';

  static const String tabOne = '/tab-1';
  static const String tabTwo = '/tab-2';
  static const String tabThree = home;
  static const String tabFour = '/tab-4';
  static const String tabMe = '/me';

  static final Set<String> _publicRoutes = <String>{welcome, login, register};

  static final Set<String> _authenticatedExactRoutes = <String>{
    authGate,
    home,
    profileSetup,
    profileEdit,
    tabOne,
    tabTwo,
    tabFour,
    tabMe,
  };

  static final GoRouter router = GoRouter(
    initialLocation: authGate,
    observers: <NavigatorObserver>[routeObserver],
    refreshListenable: AppRouterRefreshListenable(
      authChanges: ServiceLocator.authController.authStateChanges(),
      profileController: ServiceLocator.profileSetupController,
    ),
    redirect: (BuildContext context, GoRouterState state) {
      final String location = state.matchedLocation;
      final AuthUser? user = ServiceLocator.authController.getCurrentUser();
      final profileController = ServiceLocator.profileSetupController;

      if (user == null) {
        if (profileController.cachedUid != null) {
          profileController.clearCache();
        }
        return _redirectUnauthenticated(location);
      }

      if (user.isAnonymous) {
        return _redirectAuthenticated(location: location, target: home);
      }

      if (!profileController.hasCompletionCacheFor(user.uid)) {
        if (location == authGate) {
          return null;
        }
        return authGate;
      }

      final bool completed = profileController.cachedIsCompleted ?? false;
      if (!completed) {
        return _redirectAuthenticated(location: location, target: profileSetup);
      }

      return _redirectAuthenticated(location: location, target: home);
    },
    routes: <RouteBase>[
      GoRoute(
        path: authGate,
        builder: (context, state) => const _RouteResolverPage(),
      ),
      GoRoute(path: welcome, builder: (context, state) => const WelcomePage()),
      GoRoute(path: login, builder: (context, state) => const LoginPage()),
      GoRoute(
        path: register,
        builder: (context, state) => const RegisterPage(),
      ),
      StatefulShellRoute.indexedStack(
        builder:
            (
              BuildContext context,
              GoRouterState state,
              StatefulNavigationShell navigationShell,
            ) {
              return MainContainerPage(navigationShell: navigationShell);
            },
        branches: <StatefulShellBranch>[
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: tabOne,
                builder: (context, state) =>
                    const PlaceholderTabPage(title: 'Tab 1'),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: tabTwo,
                builder: (context, state) =>
                    const PlaceholderTabPage(title: 'Tab 2'),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: tabThree,
                builder: (context, state) => const MapTabPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: tabFour,
                builder: (context, state) =>
                    const PlaceholderTabPage(title: 'Tab 4'),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(path: tabMe, builder: (context, state) => const MePage()),
            ],
          ),
        ],
      ),
      GoRoute(
        path: profileSetup,
        builder: (context, state) => const ProfileSetupPage(),
      ),
      GoRoute(
        path: profileEdit,
        builder: (context, state) => const ProfileEditPage(),
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

    if (target == profileSetup) {
      if (location == profileSetup) {
        return null;
      }
      return profileSetup;
    }

    final bool canStayInAuthenticatedArea =
        _authenticatedExactRoutes.contains(location) ||
        location.startsWith('/me/');
    if (canStayInAuthenticatedArea) {
      return null;
    }

    return home;
  }
}

class AppRouterRefreshListenable extends ChangeNotifier {
  final Stream<AuthUser?> authChanges;
  final ChangeNotifier profileController;
  late final StreamSubscription<AuthUser?> _authSubscription;

  AppRouterRefreshListenable({
    required this.authChanges,
    required this.profileController,
  }) {
    _authSubscription = authChanges.asBroadcastStream().listen((_) {
      notifyListeners();
    });
    profileController.addListener(notifyListeners);
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    profileController.removeListener(notifyListeners);
    super.dispose();
  }
}

class _RouteResolverPage extends StatefulWidget {
  const _RouteResolverPage();

  @override
  State<_RouteResolverPage> createState() => _RouteResolverPageState();
}

class _RouteResolverPageState extends State<_RouteResolverPage> {
  bool _requested = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_requested) return;
    _requested = true;
    _warmUpProfileCompletion();
  }

  Future<void> _warmUpProfileCompletion() async {
    final user = ServiceLocator.authController.getCurrentUser();
    if (user == null || user.isAnonymous) return;
    await ServiceLocator.profileSetupController.warmUpProfileStatus(user.uid);
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
