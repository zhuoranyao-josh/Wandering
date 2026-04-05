import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../features/auth/data/datasources/auth_remote_data_source.dart';
import '../../features/auth/data/datasources/firebase_auth_remote_data_source.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/presentation/controllers/auth_controller.dart';
import '../../features/profile/data/datasources/firebase_profile_remote_data_source.dart';
import '../../features/profile/data/datasources/profile_remote_data_source.dart';
import '../../features/profile/data/repositories/profile_repository_impl.dart';
import '../../features/profile/domain/repositories/profile_repository.dart';
import '../../features/profile/presentation/controllers/profile_setup_controller.dart';

class ServiceLocator {
  static late final AuthController authController;
  static late final ProfileSetupController profileSetupController;

  static void setup() {
    // 最底层依赖
    final firebaseAuth = FirebaseAuth.instance;
    final googleSignIn = GoogleSignIn();
    final firestore = FirebaseFirestore.instance;
    final storage = FirebaseStorage.instance;

    // Auth 模块
    // 数据源：只有这里会真正碰 Firebase / Google Sign-In
    final AuthRemoteDataSource remoteDataSource = FirebaseAuthRemoteDataSource(
      firebaseAuth: firebaseAuth,
      googleSignIn: googleSignIn,
    );

    // 仓库
    final AuthRepository authRepository = AuthRepositoryImpl(remoteDataSource);

    // 控制器
    authController = AuthController(authRepository);

    // Profile 模块
    // 数据源：只有这里会真正碰 Firestore / Storage
    final ProfileRemoteDataSource profileRemoteDataSource =
        FirebaseProfileRemoteDataSource(firestore: firestore, storage: storage);

    // 仓库
    final ProfileRepository profileRepository = ProfileRepositoryImpl(
      profileRemoteDataSource,
    );

    // 控制器
    profileSetupController = ProfileSetupController(profileRepository);
  }
}
