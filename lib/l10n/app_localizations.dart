import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh')
  ];

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// No description provided for @goToRegister.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? Register'**
  String get goToRegister;

  /// No description provided for @backToLogin.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Back to Login'**
  String get backToLogin;

  /// No description provided for @loginWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get loginWithGoogle;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get logout;

  /// No description provided for @homeTitle.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get homeTitle;

  /// No description provided for @loginSuccess.
  ///
  /// In en, this message translates to:
  /// **'Login successful'**
  String get loginSuccess;

  /// No description provided for @uidLabel.
  ///
  /// In en, this message translates to:
  /// **'UID'**
  String get uidLabel;

  /// No description provided for @emailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailLabel;

  /// No description provided for @nameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get nameLabel;

  /// No description provided for @errorEmptyFields.
  ///
  /// In en, this message translates to:
  /// **'Please fill in all fields.'**
  String get errorEmptyFields;

  /// No description provided for @errorPasswordMismatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match.'**
  String get errorPasswordMismatch;

  /// No description provided for @errorInvalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Invalid email format.'**
  String get errorInvalidEmail;

  /// No description provided for @errorUserNotFound.
  ///
  /// In en, this message translates to:
  /// **'User not found.'**
  String get errorUserNotFound;

  /// No description provided for @errorInvalidCredential.
  ///
  /// In en, this message translates to:
  /// **'Incorrect email or password.'**
  String get errorInvalidCredential;

  /// No description provided for @errorEmailAlreadyInUse.
  ///
  /// In en, this message translates to:
  /// **'This email is already in use.'**
  String get errorEmailAlreadyInUse;

  /// No description provided for @errorWeakPassword.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters.'**
  String get errorWeakPassword;

  /// No description provided for @errorGoogleCancelled.
  ///
  /// In en, this message translates to:
  /// **'Google sign-in was cancelled.'**
  String get errorGoogleCancelled;

  /// No description provided for @errorGoogleFailed.
  ///
  /// In en, this message translates to:
  /// **'Google sign-in failed.'**
  String get errorGoogleFailed;

  /// No description provided for @errorUnknown.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong.'**
  String get errorUnknown;

  /// No description provided for @loginAsGuest.
  ///
  /// In en, this message translates to:
  /// **'Continue as Guest'**
  String get loginAsGuest;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// No description provided for @sendResetEmail.
  ///
  /// In en, this message translates to:
  /// **'Send reset email'**
  String get sendResetEmail;

  /// No description provided for @resetPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your email and we will send you a password reset email.'**
  String get resetPasswordHint;

  /// No description provided for @resetPasswordEmailSent.
  ///
  /// In en, this message translates to:
  /// **'Password reset email sent. Please check your inbox.'**
  String get resetPasswordEmailSent;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @errorMissingEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email address.'**
  String get errorMissingEmail;

  /// No description provided for @errorTooManyRequests.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Please try again later.'**
  String get errorTooManyRequests;

  /// No description provided for @errorOperationNotAllowed.
  ///
  /// In en, this message translates to:
  /// **'This sign-in method is not enabled.'**
  String get errorOperationNotAllowed;

  /// No description provided for @welcomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Discover cities, stories, and journeys around the world.'**
  String get welcomeSubtitle;

  /// No description provided for @enterLoginOrRegister.
  ///
  /// In en, this message translates to:
  /// **'Register / Log in'**
  String get enterLoginOrRegister;

  /// No description provided for @orText.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get orText;

  /// No description provided for @profileSetupTitle.
  ///
  /// In en, this message translates to:
  /// **'Set up your profile'**
  String get profileSetupTitle;

  /// No description provided for @profileNickname.
  ///
  /// In en, this message translates to:
  /// **'Nickname'**
  String get profileNickname;

  /// No description provided for @profileNicknameHint.
  ///
  /// In en, this message translates to:
  /// **'Nickname must be unique'**
  String get profileNicknameHint;

  /// No description provided for @profileBirthday.
  ///
  /// In en, this message translates to:
  /// **'Birthday'**
  String get profileBirthday;

  /// No description provided for @profileGender.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get profileGender;

  /// No description provided for @profileGenderMale.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get profileGenderMale;

  /// No description provided for @profileGenderFemale.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get profileGenderFemale;

  /// No description provided for @profileGenderOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get profileGenderOther;

  /// No description provided for @profileCountryOptional.
  ///
  /// In en, this message translates to:
  /// **'Country (Optional)'**
  String get profileCountryOptional;

  /// No description provided for @profileBio.
  ///
  /// In en, this message translates to:
  /// **'Bio'**
  String get profileBio;

  /// No description provided for @profileBioHint.
  ///
  /// In en, this message translates to:
  /// **'Introduce yourself (max 100 characters)'**
  String get profileBioHint;

  /// No description provided for @profileContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get profileContinue;

  /// No description provided for @profileErrorNicknameEmpty.
  ///
  /// In en, this message translates to:
  /// **'Please enter your nickname.'**
  String get profileErrorNicknameEmpty;

  /// No description provided for @profileErrorNicknameTooLong.
  ///
  /// In en, this message translates to:
  /// **'Nickname cannot exceed 20 characters.'**
  String get profileErrorNicknameTooLong;

  /// No description provided for @profileErrorBioTooLong.
  ///
  /// In en, this message translates to:
  /// **'Bio cannot exceed 100 characters.'**
  String get profileErrorBioTooLong;

  /// No description provided for @profileErrorNicknameTaken.
  ///
  /// In en, this message translates to:
  /// **'Your nickname is already used by another user ~'**
  String get profileErrorNicknameTaken;

  /// No description provided for @profileErrorSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to save profile. Please try again later.'**
  String get profileErrorSaveFailed;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'zh': return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
