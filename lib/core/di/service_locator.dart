import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../features/auth/data/datasources/auth_remote_data_source.dart';
import '../../features/auth/data/datasources/firebase_auth_remote_data_source.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/presentation/controllers/auth_controller.dart';

class ServiceLocator {
  static late final AuthController authController;

  static void setup() {
    // 最底层依赖
    final firebaseAuth = FirebaseAuth.instance;
    final googleSignIn = GoogleSignIn();

    // 数据源：只有这里会真正碰 Firebase / Google Sign-In
    final AuthRemoteDataSource remoteDataSource = FirebaseAuthRemoteDataSource(
      firebaseAuth: firebaseAuth,
      googleSignIn: googleSignIn,
    );

    // 仓库
    final AuthRepository authRepository = AuthRepositoryImpl(remoteDataSource);

    // 控制器
    authController = AuthController(authRepository);
  }
}
