// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get login => 'Login';

  @override
  String get register => 'Register';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get confirmPassword => 'Confirm Password';

  @override
  String get goToRegister => 'Don\'t have an account? Register';

  @override
  String get backToLogin => 'Already have an account? Back to Login';

  @override
  String get loginWithGoogle => 'Continue with Google';

  @override
  String get logout => 'Log out';

  @override
  String get homeTitle => 'Home';

  @override
  String get loginSuccess => 'Login successful';

  @override
  String get uidLabel => 'UID';

  @override
  String get emailLabel => 'Email';

  @override
  String get nameLabel => 'Name';

  @override
  String get errorEmptyFields => 'Please fill in all fields.';

  @override
  String get errorPasswordMismatch => 'Passwords do not match.';

  @override
  String get errorInvalidEmail => 'Invalid email format.';

  @override
  String get errorUserNotFound => 'User not found.';

  @override
  String get errorInvalidCredential => 'Incorrect email or password.';

  @override
  String get errorEmailAlreadyInUse => 'This email is already in use.';

  @override
  String get errorWeakPassword => 'Password must be at least 6 characters.';

  @override
  String get errorGoogleCancelled => 'Google sign-in was cancelled.';

  @override
  String get errorGoogleFailed => 'Google sign-in failed.';

  @override
  String get errorUnknown => 'Something went wrong.';

  @override
  String get loginAsGuest => 'Continue as Guest';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get sendResetEmail => 'Send reset email';

  @override
  String get resetPasswordHint => 'Enter your email and we will send you a password reset email.';

  @override
  String get resetPasswordEmailSent => 'Password reset email sent. Please check your inbox.';

  @override
  String get cancel => 'Cancel';

  @override
  String get errorMissingEmail => 'Please enter your email address.';

  @override
  String get errorTooManyRequests => 'Too many attempts. Please try again later.';

  @override
  String get errorOperationNotAllowed => 'This sign-in method is not enabled.';

  @override
  String get welcomeSubtitle => 'Discover cities, stories, and journeys around the world.';

  @override
  String get enterLoginOrRegister => 'Register / Log in';

  @override
  String get orText => 'or';
}
