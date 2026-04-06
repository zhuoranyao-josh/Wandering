import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/app/app_router.dart';

void main() {
  test('AppRouter exposes the expected routes', () {
    expect(AppRouter.authGate, '/');
    expect(AppRouter.welcome, '/welcome');
    expect(AppRouter.login, '/login');
    expect(AppRouter.register, '/register');
    expect(AppRouter.home, '/home');
    expect(AppRouter.profileSetup, '/profile-setup');
  });
}
