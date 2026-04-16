import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';

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
import '../../features/community/data/datasources/community_remote_data_source.dart';
import '../../features/community/data/datasources/firebase_community_remote_data_source.dart';
import '../../features/community/data/repositories/community_repository_impl.dart';
import '../../features/community/domain/repositories/community_repository.dart';
import '../../features/community/presentation/controllers/community_controller.dart';
import '../../features/profile/data/datasources/firebase_profile_remote_data_source.dart';
import '../../features/profile/data/datasources/profile_remote_data_source.dart';
import '../../features/profile/data/repositories/profile_repository_impl.dart';
import '../../features/profile/domain/repositories/profile_repository.dart';
import '../../features/profile/presentation/controllers/profile_setup_controller.dart';

class ServiceLocator {
  static late final AuthController authController;
  static late final ActivityController activityController;
  static late final CommunityController communityController;
  static late final ProfileSetupController profileSetupController;

  static void setup() {
    // 最底层依赖
    final firebaseAuth = FirebaseAuth.instance;
    final googleSignIn = GoogleSignIn();
    final firestore = FirebaseFirestore.instance;
    final storage = FirebaseStorage.instance;

    // Auth 模块
    // 数据源：只有这里会真正接触 Firebase / Google Sign-In。
    final AuthRemoteDataSource authRemoteDataSource =
        FirebaseAuthRemoteDataSource(
          firebaseAuth: firebaseAuth,
          googleSignIn: googleSignIn,
        );

    // 仓库
    final AuthRepository authRepository = AuthRepositoryImpl(
      authRemoteDataSource,
    );

    // 控制器
    authController = AuthController(authRepository);

    // Activity 模块
    final ActivityRemoteDataSource activityRemoteDataSource =
        FirebaseActivityRemoteDataSource(firestore: firestore);
    final ActivityRepository activityRepository = ActivityRepositoryImpl(
      activityRemoteDataSource,
    );
    activityController = ActivityController(activityRepository);

    // Profile 模块
    // 数据源：只有这里会真正接触 Firestore / Storage。
    final ProfileRemoteDataSource profileRemoteDataSource =
        FirebaseProfileRemoteDataSource(firestore: firestore, storage: storage);
    final ProfileRepository profileRepository = ProfileRepositoryImpl(
      profileRemoteDataSource,
    );
    profileSetupController = ProfileSetupController(profileRepository);

    // Community 模块
    // 数据源：只有这里会真正接触 Firestore。
    final CommunityRemoteDataSource communityRemoteDataSource =
        FirebaseCommunityRemoteDataSource(firestore: firestore);
    final CommunityRepository communityRepository = CommunityRepositoryImpl(
      communityRemoteDataSource,
    );
    communityController = CommunityController(
      communityRepository: communityRepository,
      authController: authController,
      profileSetupController: profileSetupController,
    );
  }
}
