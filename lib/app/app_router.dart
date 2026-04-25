import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/di/service_locator.dart';
import '../features/activity/domain/entities/activity_event.dart';
import '../features/activity/presentation/pages/activity_detail_page.dart';
import '../features/activity/presentation/pages/activity_page.dart';
import '../features/auth/domain/entities/auth_user.dart';
import '../features/auth/presentation/pages/login_page.dart';
import '../features/auth/presentation/pages/register_page.dart';
import '../features/community/presentation/models/community_models.dart';
import '../features/community/presentation/pages/community_page.dart';
import '../features/community/presentation/pages/create_post_page.dart';
import '../features/community/presentation/pages/location_search_page.dart';
import '../features/community/presentation/pages/post_detail_page.dart';
import '../features/community/presentation/pages/user_profile_page.dart';
import '../features/checklist/presentation/pages/checklist_create_page.dart';
import '../features/checklist/presentation/pages/checklist_detail_page.dart';
import '../features/checklist/presentation/pages/checklist_list_page.dart';
import '../features/checklist/presentation/pages/journey_wizard_page.dart';
import '../features/admin/domain/entities/admin_subcontent_kind.dart';
import '../features/admin/presentation/pages/activity_admin_edit_page.dart';
import '../features/admin/presentation/pages/activity_admin_list_page.dart';
import '../features/admin/presentation/pages/admin_dashboard_page.dart';
import '../features/admin/presentation/pages/place_admin_edit_page.dart';
import '../features/admin/presentation/pages/place_admin_list_page.dart';
import '../features/admin/presentation/pages/place_subcontent_admin_page.dart';
import '../features/main_container/presentation/pages/main_container_page.dart';
import '../features/main_container/presentation/pages/map_tab_page.dart';
import '../features/map_home/presentation/models/place_detail_ui_model.dart';
import '../features/map_home/presentation/pages/place_details_page.dart';
import '../features/profile/domain/entities/user_profile.dart';
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
  static const String activities = '/activities';
  static const String activityDetailPath = 'detail/:eventId';
  static const String community = '/community';
  static const String createPost = 'create-post';
  static const String locationSearch = 'location-search';
  static const String postDetail = 'post/:postId';
  static const String userProfile = 'user/:userId';
  static const String checklists = '/checklists';
  static const String checklistCreatePath = 'create';
  static const String checklistDetailPath = 'detail/:checklistId';
  static const String checklistWizardPath = 'wizard/:checklistId';
  static const String adminDashboard = '/admin';
  static const String adminPlaces = '/admin/places';
  static const String adminPlaceEditPath = '/admin/places/edit/:placeId';
  static const String adminPlaceSubcontentPath =
      '/admin/places/:placeId/content/:kind';
  static const String adminActivities = '/admin/activities';
  static const String adminActivityEditPath =
      '/admin/activities/edit/:activityId';

  static const String tabOne = '/tab-1';
  static const String tabTwo = activities;
  static const String tabThree = home;
  static const String placeDetailsPath = 'place/:placeId';
  static const String tabFour = community;
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
    checklists,
    adminDashboard,
    adminPlaces,
    adminActivities,
  };

  static String activityDetail(String eventId) {
    return '$activities/detail/$eventId';
  }

  static String communityCreatePost() {
    return '$community/$createPost';
  }

  static String communityLocationSearch() {
    return '$community/$locationSearch';
  }

  static String communityPostDetail(String postId) {
    return '$community/${postDetail.replaceFirst(':postId', postId)}';
  }

  static String communityUserProfile(String userId) {
    return '$community/${userProfile.replaceFirst(':userId', userId)}';
  }

  static String checklistCreate() {
    return '$checklists/$checklistCreatePath';
  }

  static String checklistDetail(String checklistId) {
    return '$checklists/${checklistDetailPath.replaceFirst(':checklistId', checklistId)}';
  }

  static String checklistWizard(String checklistId) {
    return '$checklists/${checklistWizardPath.replaceFirst(':checklistId', checklistId)}';
  }

  static String placeDetails(String placeId) {
    return '$home/${placeDetailsPath.replaceFirst(':placeId', placeId)}';
  }

  static String adminPlaceEdit(String placeId) {
    return adminPlaceEditPath.replaceFirst(':placeId', placeId);
  }

  static String adminPlaceSubcontent(String placeId, String kind) {
    return adminPlaceSubcontentPath
        .replaceFirst(':placeId', placeId)
        .replaceFirst(':kind', kind);
  }

  static String adminActivityEdit(String activityId) {
    return adminActivityEditPath.replaceFirst(':activityId', activityId);
  }

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

      final UserProfile? profile = profileController.getCachedProfile(user.uid);
      final bool isAdmin = (profile?.role ?? 'user') == 'admin';
      // 管理员权限统一在路由层拦截，避免页面内零散判断。
      if (_isAdminRoute(location) && !isAdmin) {
        return home;
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
                builder: (context, state) => const ChecklistListPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: tabTwo,
                builder: (context, state) => const ActivityPage(),
                routes: <RouteBase>[
                  GoRoute(
                    path: activityDetailPath,
                    builder: (context, state) {
                      final initialEvent = state.extra as ActivityEvent?;
                      final eventId = state.pathParameters['eventId'] ?? '';
                      return ActivityDetailPage(
                        eventId: eventId,
                        initialEvent: initialEvent,
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: tabThree,
                builder: (context, state) => const MapTabPage(),
                routes: <RouteBase>[
                  GoRoute(
                    path: placeDetailsPath,
                    builder: (context, state) {
                      final placeId = state.pathParameters['placeId'] ?? '';
                      final extra = state.extra;
                      final initialModel = extra is PlaceDetailUiModel
                          ? extra
                          : null;
                      return PlaceDetailsPage(
                        placeId: placeId,
                        initialModel: initialModel,
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: tabFour,
                builder: (context, state) => const CommunityPage(),
                routes: <RouteBase>[
                  GoRoute(
                    path: createPost,
                    builder: (context, state) => const CreatePostPage(),
                  ),
                  GoRoute(
                    path: locationSearch,
                    builder: (context, state) => const LocationSearchPage(),
                  ),
                  GoRoute(
                    path: postDetail,
                    builder: (context, state) {
                      final initialPost = state.extra as CommunityPost?;
                      final postId = state.pathParameters['postId'] ?? '';
                      return PostDetailPage(
                        postId: postId,
                        initialPost: initialPost,
                      );
                    },
                  ),
                  GoRoute(
                    path: userProfile,
                    builder: (context, state) {
                      final initialUser = state.extra as CommunityUser?;
                      final userId = state.pathParameters['userId'] ?? '';
                      return UserProfilePage(
                        userId: userId,
                        initialUser: initialUser,
                      );
                    },
                  ),
                ],
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
      GoRoute(
        path: checklists,
        builder: (context, state) => const ChecklistListPage(),
        routes: <RouteBase>[
          GoRoute(
            path: checklistCreatePath,
            builder: (context, state) => const ChecklistCreatePage(),
          ),
          GoRoute(
            path: checklistDetailPath,
            builder: (context, state) {
              final checklistId = state.pathParameters['checklistId'] ?? '';
              return ChecklistDetailPage(checklistId: checklistId);
            },
          ),
          GoRoute(
            path: checklistWizardPath,
            builder: (context, state) {
              final checklistId = state.pathParameters['checklistId'] ?? '';
              return JourneyWizardPage(checklistId: checklistId);
            },
          ),
        ],
      ),
      GoRoute(
        path: adminDashboard,
        builder: (context, state) => const AdminDashboardPage(),
      ),
      GoRoute(
        path: adminPlaces,
        builder: (context, state) => const PlaceAdminListPage(),
      ),
      GoRoute(
        path: adminPlaceEditPath,
        builder: (context, state) {
          final placeId = state.pathParameters['placeId'] ?? 'new';
          return PlaceAdminEditPage(placeId: placeId);
        },
      ),
      GoRoute(
        path: adminPlaceSubcontentPath,
        builder: (context, state) {
          final placeId = state.pathParameters['placeId'] ?? '';
          final rawKind = state.pathParameters['kind'] ?? '';
          final kind =
              AdminSubcontentKind.fromRaw(rawKind) ??
              AdminSubcontentKind.experiences;
          return PlaceSubcontentAdminPage(placeId: placeId, kind: kind);
        },
      ),
      GoRoute(
        path: adminActivities,
        builder: (context, state) => const ActivityAdminListPage(),
      ),
      GoRoute(
        path: adminActivityEditPath,
        builder: (context, state) {
          final activityId = state.pathParameters['activityId'] ?? 'new';
          return ActivityAdminEditPage(activityId: activityId);
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

    if (target == profileSetup) {
      if (location == profileSetup) {
        return null;
      }
      return profileSetup;
    }

    final bool canStayInAuthenticatedArea =
        _authenticatedExactRoutes.contains(location) ||
        location.startsWith('$adminDashboard/') ||
        location.startsWith('$checklists/') ||
        location.startsWith('$home/') ||
        location.startsWith('/me/') ||
        location.startsWith('$activities/') ||
        location.startsWith('$community/');
    if (canStayInAuthenticatedArea) {
      return null;
    }

    return home;
  }

  static bool _isAdminRoute(String location) {
    return location == adminDashboard ||
        location.startsWith('$adminDashboard/');
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
