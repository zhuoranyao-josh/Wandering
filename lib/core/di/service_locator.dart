import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

import '../../features/admin/data/datasources/admin_remote_data_source.dart';
import '../../features/admin/data/datasources/firebase_admin_remote_data_source.dart';
import '../../features/admin/data/repositories/admin_repository_impl.dart';
import '../../features/admin/domain/repositories/admin_repository.dart';
import '../../features/activity/data/datasources/activity_remote_data_source.dart';
import '../../features/activity/data/datasources/firebase_activity_remote_data_source.dart';
import '../../features/activity/data/repositories/activity_repository_impl.dart';
import '../../features/activity/domain/repositories/activity_repository.dart';
import '../../features/activity/presentation/controllers/activity_controller.dart';
import '../../features/auth/data/datasources/auth_remote_data_source.dart';
import '../../features/auth/data/datasources/firebase_auth_remote_data_source.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/presentation/controllers/auth_controller.dart';
import '../../features/checklist/data/datasources/checklist_remote_data_source.dart';
import '../../features/checklist/data/datasources/firebase_checklist_remote_data_source.dart';
import '../../features/checklist/data/datasources/gemini_grounding_remote_data_source.dart';
import '../../features/checklist/data/datasources/gemini_planning_remote_data_source.dart';
import '../../features/checklist/data/datasources/google_places_remote_data_source.dart';
import '../../features/checklist/data/datasources/open_weather_remote_data_source.dart';
import '../../features/checklist/data/datasources/weather_remote_data_source.dart';
import '../../features/checklist/data/repositories/checklist_repository_impl.dart';
import '../../features/checklist/domain/repositories/checklist_repository.dart';
import '../../features/checklist/presentation/controllers/checklist_controller.dart';
import '../../features/checklist/presentation/controllers/checklist_detail_controller.dart';
import '../../features/checklist/presentation/controllers/journey_wizard_controller.dart';
import '../../features/community/data/datasources/community_remote_data_source.dart';
import '../../features/community/data/datasources/firebase_community_remote_data_source.dart';
import '../../features/community/data/repositories/community_repository_impl.dart';
import '../../features/community/domain/repositories/community_repository.dart';
import '../../features/community/presentation/controllers/community_controller.dart';
import '../../features/map_home/data/datasources/device_location_data_source.dart';
import '../../features/map_home/data/datasources/firebase_map_home_remote_data_source.dart';
import '../../features/map_home/data/datasources/geolocator_device_location_data_source.dart';
import '../../features/map_home/data/datasources/map_home_city_search_remote_data_source.dart';
import '../../features/map_home/data/datasources/mapbox_city_search_remote_data_source.dart';
import '../../features/map_home/data/repositories/current_location_repository_impl.dart';
import '../../features/map_home/data/datasources/map_home_remote_data_source.dart';
import '../../features/map_home/data/repositories/map_home_repository_impl.dart';
import '../../features/map_home/domain/repositories/current_location_repository.dart';
import '../../features/map_home/domain/repositories/map_home_repository.dart';
import '../../features/map_home/presentation/controllers/map_home_controller.dart';
import '../../features/profile/data/datasources/firebase_profile_remote_data_source.dart';
import '../../features/profile/data/datasources/profile_remote_data_source.dart';
import '../../features/profile/data/repositories/profile_repository_impl.dart';
import '../../features/profile/domain/repositories/profile_repository.dart';
import '../../features/profile/presentation/controllers/profile_setup_controller.dart';

class ServiceLocator {
  static late final AuthController authController;
  static late final ActivityController activityController;
  static late final CommunityController communityController;
  static late final MapHomeRepository mapHomeRepository;
  static late final CurrentLocationRepository currentLocationRepository;
  static late final ProfileSetupController profileSetupController;
  static late final ChecklistRepository checklistRepository;
  static late final ChecklistController checklistController;
  static late final WeatherRemoteDataSource weatherRemoteDataSource;
  static late final AdminRepository adminRepository;
  static late final http.Client sharedHttpClient;

  static void setup() {
    // 最底层依赖统一在这里创建，避免页面直接接触 Firebase。
    final firebaseAuth = FirebaseAuth.instance;
    final googleSignIn = GoogleSignIn();
    final firestore = FirebaseFirestore.instance;
    final storage = FirebaseStorage.instance;
    sharedHttpClient = http.Client();

    // Auth 模块
    final AuthRemoteDataSource authRemoteDataSource =
        FirebaseAuthRemoteDataSource(
          firebaseAuth: firebaseAuth,
          googleSignIn: googleSignIn,
        );
    final AuthRepository authRepository = AuthRepositoryImpl(
      authRemoteDataSource,
    );
    authController = AuthController(authRepository);

    // Activity 模块
    final ActivityRemoteDataSource activityRemoteDataSource =
        FirebaseActivityRemoteDataSource(firestore: firestore);
    final ActivityRepository activityRepository = ActivityRepositoryImpl(
      activityRemoteDataSource,
    );
    activityController = ActivityController(activityRepository);

    // Map Home 模块
    final MapHomeRemoteDataSource mapHomeRemoteDataSource =
        FirebaseMapHomeRemoteDataSource(firestore: firestore);
    final MapHomeCitySearchRemoteDataSource citySearchRemoteDataSource =
        MapboxCitySearchRemoteDataSource(httpClient: sharedHttpClient);
    mapHomeRepository = MapHomeRepositoryImpl(
      mapHomeRemoteDataSource,
      citySearchRemoteDataSource,
    );
    final DeviceLocationDataSource deviceLocationDataSource =
        GeolocatorDeviceLocationDataSource();
    currentLocationRepository = CurrentLocationRepositoryImpl(
      deviceLocationDataSource,
    );

    // Profile 模块
    final ProfileRemoteDataSource profileRemoteDataSource =
        FirebaseProfileRemoteDataSource(firestore: firestore, storage: storage);
    final ProfileRepository profileRepository = ProfileRepositoryImpl(
      profileRemoteDataSource,
    );
    profileSetupController = ProfileSetupController(profileRepository);

    // Checklist 模块
    final geminiPlanningRemoteDataSource = GeminiPlanningRemoteDataSource();
    final geminiGroundingRemoteDataSource = GeminiGroundingRemoteDataSource();
    final googlePlacesRemoteDataSource = GooglePlacesRemoteDataSource(
      client: sharedHttpClient,
    );
    final ChecklistRemoteDataSource checklistRemoteDataSource =
        FirebaseChecklistRemoteDataSource(
          firestore: firestore,
          firebaseAuth: firebaseAuth,
          geminiPlanningRemoteDataSource: geminiPlanningRemoteDataSource,
          geminiGroundingRemoteDataSource: geminiGroundingRemoteDataSource,
          googlePlacesRemoteDataSource: googlePlacesRemoteDataSource,
        );
    checklistRepository = ChecklistRepositoryImpl(checklistRemoteDataSource);
    checklistController = ChecklistController(repository: checklistRepository);
    weatherRemoteDataSource = OpenWeatherRemoteDataSource();

    // Community 模块
    final CommunityRemoteDataSource communityRemoteDataSource =
        FirebaseCommunityRemoteDataSource(
          firestore: firestore,
          firebaseAuth: firebaseAuth,
          storage: storage,
        );
    final CommunityRepository communityRepository = CommunityRepositoryImpl(
      communityRemoteDataSource,
    );
    communityController = CommunityController(
      communityRepository: communityRepository,
      authController: authController,
      profileSetupController: profileSetupController,
    );

    // Admin 妯″潡
    final AdminRemoteDataSource adminRemoteDataSource =
        FirebaseAdminRemoteDataSource(firestore: firestore, storage: storage);
    adminRepository = AdminRepositoryImpl(adminRemoteDataSource);
  }

  static MapHomeController createMapHomeController({
    required double initialMarkerZoom,
  }) {
    return MapHomeController(
      mapHomeRepository: mapHomeRepository,
      currentLocationRepository: currentLocationRepository,
      initialMarkerZoom: initialMarkerZoom,
    );
  }

  static ChecklistDetailController createChecklistDetailController() {
    return ChecklistDetailController(
      repository: checklistRepository,
      weatherRemoteDataSource: weatherRemoteDataSource,
    );
  }

  static JourneyWizardController createJourneyWizardController({
    required String checklistId,
  }) {
    return JourneyWizardController(
      repository: checklistRepository,
      checklistId: checklistId,
    );
  }
}
