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

  /// No description provided for @defaultUserName.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get defaultUserName;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageChinese.
  ///
  /// In en, this message translates to:
  /// **'Chinese'**
  String get languageChinese;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @profileEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get profileEditTitle;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @mapTabTitle.
  ///
  /// In en, this message translates to:
  /// **'Map Tab'**
  String get mapTabTitle;

  /// No description provided for @mapTabPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Map feature placeholder'**
  String get mapTabPlaceholder;

  /// No description provided for @mapHomeLoadingTitle.
  ///
  /// In en, this message translates to:
  /// **'Loading globe'**
  String get mapHomeLoadingTitle;

  /// No description provided for @mapHomeLoadingMessage.
  ///
  /// In en, this message translates to:
  /// **'Initializing map resources. Please wait.'**
  String get mapHomeLoadingMessage;

  /// No description provided for @mapHomeLoadFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Map failed to load'**
  String get mapHomeLoadFailedTitle;

  /// No description provided for @mapHomeLoadFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'The map could not be initialized right now. Please try again.'**
  String get mapHomeLoadFailedMessage;

  /// No description provided for @mapHomeRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get mapHomeRetry;

  /// No description provided for @mapHomeMissingTokenTitle.
  ///
  /// In en, this message translates to:
  /// **'Missing Mapbox configuration'**
  String get mapHomeMissingTokenTitle;

  /// No description provided for @mapHomeMissingTokenMessage.
  ///
  /// In en, this message translates to:
  /// **'Inject a Mapbox access token with dart-define before running the app.'**
  String get mapHomeMissingTokenMessage;

  /// No description provided for @mapHomeUnsupportedTitle.
  ///
  /// In en, this message translates to:
  /// **'Map is not supported on this platform'**
  String get mapHomeUnsupportedTitle;

  /// No description provided for @mapHomeUnsupportedMessage.
  ///
  /// In en, this message translates to:
  /// **'The Mapbox Flutter SDK currently supports Android and iOS only.'**
  String get mapHomeUnsupportedMessage;

  /// No description provided for @mapHomeSwitchToDay.
  ///
  /// In en, this message translates to:
  /// **'Switch to day mode'**
  String get mapHomeSwitchToDay;

  /// No description provided for @mapHomeSwitchToNight.
  ///
  /// In en, this message translates to:
  /// **'Switch to night mode'**
  String get mapHomeSwitchToNight;

  /// No description provided for @mapPlaceTokyoName.
  ///
  /// In en, this message translates to:
  /// **'Tokyo'**
  String get mapPlaceTokyoName;

  /// No description provided for @mapPlaceTokyoDescription.
  ///
  /// In en, this message translates to:
  /// **'A neon-lit test city used to validate globe markers, camera transitions, and the floating preview card.'**
  String get mapPlaceTokyoDescription;

  /// No description provided for @mapPlaceNewYorkName.
  ///
  /// In en, this message translates to:
  /// **'New York'**
  String get mapPlaceNewYorkName;

  /// No description provided for @mapPlaceNewYorkDescription.
  ///
  /// In en, this message translates to:
  /// **'A test city used to validate globe markers, camera transitions, and the floating preview card.'**
  String get mapPlaceNewYorkDescription;

  /// No description provided for @mapPlaceLosAngelesName.
  ///
  /// In en, this message translates to:
  /// **'Los Angeles'**
  String get mapPlaceLosAngelesName;

  /// No description provided for @mapPlaceLosAngelesDescription.
  ///
  /// In en, this message translates to:
  /// **'A test city used to validate globe markers, camera transitions, and the floating preview card.'**
  String get mapPlaceLosAngelesDescription;

  /// No description provided for @mapPlaceMoscowName.
  ///
  /// In en, this message translates to:
  /// **'Moscow'**
  String get mapPlaceMoscowName;

  /// No description provided for @mapPlaceMoscowDescription.
  ///
  /// In en, this message translates to:
  /// **'A test city used to validate globe markers, camera transitions, and the floating preview card.'**
  String get mapPlaceMoscowDescription;

  /// No description provided for @mapPlaceSaintPetersburgName.
  ///
  /// In en, this message translates to:
  /// **'Saint Petersburg'**
  String get mapPlaceSaintPetersburgName;

  /// No description provided for @mapPlaceSaintPetersburgDescription.
  ///
  /// In en, this message translates to:
  /// **'A test city used to validate globe markers, camera transitions, and the floating preview card.'**
  String get mapPlaceSaintPetersburgDescription;

  /// No description provided for @mapPlaceYokohamaName.
  ///
  /// In en, this message translates to:
  /// **'Yokohama'**
  String get mapPlaceYokohamaName;

  /// No description provided for @mapPlaceYokohamaDescription.
  ///
  /// In en, this message translates to:
  /// **'A test city used to validate globe markers, camera transitions, and the floating preview card.'**
  String get mapPlaceYokohamaDescription;

  /// No description provided for @mapPlaceOsakaName.
  ///
  /// In en, this message translates to:
  /// **'Osaka'**
  String get mapPlaceOsakaName;

  /// No description provided for @mapPlaceOsakaDescription.
  ///
  /// In en, this message translates to:
  /// **'A test city used to validate globe markers, camera transitions, and the floating preview card.'**
  String get mapPlaceOsakaDescription;

  /// No description provided for @mapPlaceBeijingName.
  ///
  /// In en, this message translates to:
  /// **'Beijing'**
  String get mapPlaceBeijingName;

  /// No description provided for @mapPlaceBeijingDescription.
  ///
  /// In en, this message translates to:
  /// **'A test city used to validate globe markers, camera transitions, and the floating preview card.'**
  String get mapPlaceBeijingDescription;

  /// No description provided for @mapPlaceShanghaiName.
  ///
  /// In en, this message translates to:
  /// **'Shanghai'**
  String get mapPlaceShanghaiName;

  /// No description provided for @mapPlaceShanghaiDescription.
  ///
  /// In en, this message translates to:
  /// **'A test city used to validate globe markers, camera transitions, and the floating preview card.'**
  String get mapPlaceShanghaiDescription;

  /// No description provided for @mapPlaceGuangzhouName.
  ///
  /// In en, this message translates to:
  /// **'Guangzhou'**
  String get mapPlaceGuangzhouName;

  /// No description provided for @mapPlaceGuangzhouDescription.
  ///
  /// In en, this message translates to:
  /// **'A test city used to validate globe markers, camera transitions, and the floating preview card.'**
  String get mapPlaceGuangzhouDescription;

  /// No description provided for @mapPlaceTianjinName.
  ///
  /// In en, this message translates to:
  /// **'Tianjin'**
  String get mapPlaceTianjinName;

  /// No description provided for @mapPlaceTianjinDescription.
  ///
  /// In en, this message translates to:
  /// **'A test city used to validate globe markers, camera transitions, and the floating preview card.'**
  String get mapPlaceTianjinDescription;

  /// No description provided for @mapPlaceLhasaName.
  ///
  /// In en, this message translates to:
  /// **'Lhasa'**
  String get mapPlaceLhasaName;

  /// No description provided for @mapPlaceLhasaDescription.
  ///
  /// In en, this message translates to:
  /// **'A test city used to validate globe markers, camera transitions, and the floating preview card.'**
  String get mapPlaceLhasaDescription;

  /// No description provided for @mapPlaceSuzhouName.
  ///
  /// In en, this message translates to:
  /// **'Suzhou'**
  String get mapPlaceSuzhouName;

  /// No description provided for @mapPlaceSuzhouDescription.
  ///
  /// In en, this message translates to:
  /// **'A test city used to validate globe markers, camera transitions, and the floating preview card.'**
  String get mapPlaceSuzhouDescription;

  /// No description provided for @mapPlaceMunichName.
  ///
  /// In en, this message translates to:
  /// **'Munich'**
  String get mapPlaceMunichName;

  /// No description provided for @mapPlaceMunichDescription.
  ///
  /// In en, this message translates to:
  /// **'A test city used to validate globe markers, camera transitions, and the floating preview card.'**
  String get mapPlaceMunichDescription;

  /// No description provided for @mapPlaceBerlinName.
  ///
  /// In en, this message translates to:
  /// **'Berlin'**
  String get mapPlaceBerlinName;

  /// No description provided for @mapPlaceBerlinDescription.
  ///
  /// In en, this message translates to:
  /// **'A test city used to validate globe markers, camera transitions, and the floating preview card.'**
  String get mapPlaceBerlinDescription;

  /// No description provided for @mapPlaceFrankfurtName.
  ///
  /// In en, this message translates to:
  /// **'Frankfurt'**
  String get mapPlaceFrankfurtName;

  /// No description provided for @mapPlaceFrankfurtDescription.
  ///
  /// In en, this message translates to:
  /// **'A test city used to validate globe markers, camera transitions, and the floating preview card.'**
  String get mapPlaceFrankfurtDescription;

  /// No description provided for @mapPlaceIstanbulName.
  ///
  /// In en, this message translates to:
  /// **'Istanbul'**
  String get mapPlaceIstanbulName;

  /// No description provided for @mapPlaceIstanbulDescription.
  ///
  /// In en, this message translates to:
  /// **'A test city used to validate globe markers, camera transitions, and the floating preview card.'**
  String get mapPlaceIstanbulDescription;

  /// No description provided for @mapPlaceTorontoName.
  ///
  /// In en, this message translates to:
  /// **'Toronto'**
  String get mapPlaceTorontoName;

  /// No description provided for @mapPlaceTorontoDescription.
  ///
  /// In en, this message translates to:
  /// **'A test city used to validate globe markers, camera transitions, and the floating preview card.'**
  String get mapPlaceTorontoDescription;

  /// No description provided for @mapPlaceBuenosAiresName.
  ///
  /// In en, this message translates to:
  /// **'Buenos Aires'**
  String get mapPlaceBuenosAiresName;

  /// No description provided for @mapPlaceBuenosAiresDescription.
  ///
  /// In en, this message translates to:
  /// **'A test city used to validate globe markers, camera transitions, and the floating preview card.'**
  String get mapPlaceBuenosAiresDescription;

  /// No description provided for @mapPlaceSaoPauloName.
  ///
  /// In en, this message translates to:
  /// **'Sao Paulo'**
  String get mapPlaceSaoPauloName;

  /// No description provided for @mapPlaceSaoPauloDescription.
  ///
  /// In en, this message translates to:
  /// **'A test city used to validate globe markers, camera transitions, and the floating preview card.'**
  String get mapPlaceSaoPauloDescription;

  /// No description provided for @mapPlaceCairoName.
  ///
  /// In en, this message translates to:
  /// **'Cairo'**
  String get mapPlaceCairoName;

  /// No description provided for @mapPlaceCairoDescription.
  ///
  /// In en, this message translates to:
  /// **'A test city used to validate globe markers, camera transitions, and the floating preview card.'**
  String get mapPlaceCairoDescription;

  /// No description provided for @mapPlaceCapeTownName.
  ///
  /// In en, this message translates to:
  /// **'Cape Town'**
  String get mapPlaceCapeTownName;

  /// No description provided for @mapPlaceCapeTownDescription.
  ///
  /// In en, this message translates to:
  /// **'A test city used to validate globe markers, camera transitions, and the floating preview card.'**
  String get mapPlaceCapeTownDescription;

  /// No description provided for @mapPlaceSydneyName.
  ///
  /// In en, this message translates to:
  /// **'Sydney'**
  String get mapPlaceSydneyName;

  /// No description provided for @mapPlaceSydneyDescription.
  ///
  /// In en, this message translates to:
  /// **'A test city used to validate globe markers, camera transitions, and the floating preview card.'**
  String get mapPlaceSydneyDescription;

  /// No description provided for @mapPlaceMelbourneName.
  ///
  /// In en, this message translates to:
  /// **'Melbourne'**
  String get mapPlaceMelbourneName;

  /// No description provided for @mapPlaceMelbourneDescription.
  ///
  /// In en, this message translates to:
  /// **'A test city used to validate globe markers, camera transitions, and the floating preview card.'**
  String get mapPlaceMelbourneDescription;

  /// No description provided for @mapPlaceWellingtonName.
  ///
  /// In en, this message translates to:
  /// **'Wellington'**
  String get mapPlaceWellingtonName;

  /// No description provided for @mapPlaceWellingtonDescription.
  ///
  /// In en, this message translates to:
  /// **'A test city used to validate globe markers, camera transitions, and the floating preview card.'**
  String get mapPlaceWellingtonDescription;

  /// No description provided for @mapPlaceHongKongName.
  ///
  /// In en, this message translates to:
  /// **'Hong Kong'**
  String get mapPlaceHongKongName;

  /// No description provided for @mapPlaceHongKongDescription.
  ///
  /// In en, this message translates to:
  /// **'A test city used to validate globe markers, camera transitions, and the floating preview card.'**
  String get mapPlaceHongKongDescription;

  /// No description provided for @mapPlaceParisName.
  ///
  /// In en, this message translates to:
  /// **'Paris'**
  String get mapPlaceParisName;

  /// No description provided for @mapPlaceParisDescription.
  ///
  /// In en, this message translates to:
  /// **'A test city used to validate globe markers, camera transitions, and the floating preview card.'**
  String get mapPlaceParisDescription;

  /// No description provided for @mapPlaceLondonName.
  ///
  /// In en, this message translates to:
  /// **'London'**
  String get mapPlaceLondonName;

  /// No description provided for @mapPlaceLondonDescription.
  ///
  /// In en, this message translates to:
  /// **'A test city used to validate globe markers, camera transitions, and the floating preview card.'**
  String get mapPlaceLondonDescription;

  /// No description provided for @activitySearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search by event title or city'**
  String get activitySearchHint;

  /// No description provided for @activityUpcomingTitle.
  ///
  /// In en, this message translates to:
  /// **'Coming soon:'**
  String get activityUpcomingTitle;

  /// No description provided for @activityLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load events. Please try again later.'**
  String get activityLoadFailed;

  /// No description provided for @activityRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get activityRetry;

  /// No description provided for @activityEmptyDefault.
  ///
  /// In en, this message translates to:
  /// **'No published events yet.'**
  String get activityEmptyDefault;

  /// No description provided for @activityEmptyFiltered.
  ///
  /// In en, this message translates to:
  /// **'No events match the current filters.'**
  String get activityEmptyFiltered;

  /// No description provided for @activitySelectDateRange.
  ///
  /// In en, this message translates to:
  /// **'Select date or date range'**
  String get activitySelectDateRange;

  /// No description provided for @activityClearDateFilter.
  ///
  /// In en, this message translates to:
  /// **'Clear date filter'**
  String get activityClearDateFilter;

  /// No description provided for @activityDateFilterLabel.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get activityDateFilterLabel;

  /// No description provided for @activityCategoryAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get activityCategoryAll;

  /// No description provided for @activityCategoryTraditionalFestival.
  ///
  /// In en, this message translates to:
  /// **'Traditional Festival'**
  String get activityCategoryTraditionalFestival;

  /// No description provided for @activityCategoryMusic.
  ///
  /// In en, this message translates to:
  /// **'Music'**
  String get activityCategoryMusic;

  /// No description provided for @activityCategoryExhibition.
  ///
  /// In en, this message translates to:
  /// **'Exhibition'**
  String get activityCategoryExhibition;

  /// No description provided for @activityCategoryEntertainment.
  ///
  /// In en, this message translates to:
  /// **'Entertainment'**
  String get activityCategoryEntertainment;

  /// No description provided for @activityCategoryNature.
  ///
  /// In en, this message translates to:
  /// **'Nature'**
  String get activityCategoryNature;

  /// No description provided for @activityDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Event details'**
  String get activityDetailTitle;

  /// No description provided for @activityDetailEmpty.
  ///
  /// In en, this message translates to:
  /// **'Detailed information will be available soon.'**
  String get activityDetailEmpty;

  /// No description provided for @activityDetailNotFound.
  ///
  /// In en, this message translates to:
  /// **'This event could not be found.'**
  String get activityDetailNotFound;

  /// No description provided for @activityBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get activityBack;

  /// No description provided for @activityAlwaysOpen.
  ///
  /// In en, this message translates to:
  /// **'Always open'**
  String get activityAlwaysOpen;

  /// No description provided for @activityLongTermOpenFrom.
  ///
  /// In en, this message translates to:
  /// **'Open from {date}'**
  String activityLongTermOpenFrom(Object date);

  /// No description provided for @activityOpenUntil.
  ///
  /// In en, this message translates to:
  /// **'Open until {date}'**
  String activityOpenUntil(Object date);

  /// No description provided for @viewDetails.
  ///
  /// In en, this message translates to:
  /// **'View details'**
  String get viewDetails;

  /// No description provided for @placeDetailsUniqueExperiences.
  ///
  /// In en, this message translates to:
  /// **'Unique Experiences'**
  String get placeDetailsUniqueExperiences;

  /// No description provided for @placeDetailsNativeFlavors.
  ///
  /// In en, this message translates to:
  /// **'Native Flavors'**
  String get placeDetailsNativeFlavors;

  /// No description provided for @placeDetailsCuratedStays.
  ///
  /// In en, this message translates to:
  /// **'Curated Stays'**
  String get placeDetailsCuratedStays;

  /// No description provided for @placeDetailsCommunityMoments.
  ///
  /// In en, this message translates to:
  /// **'Community Moments'**
  String get placeDetailsCommunityMoments;

  /// No description provided for @placeDetailsGallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get placeDetailsGallery;

  /// No description provided for @placeDetailsFindNearMe.
  ///
  /// In en, this message translates to:
  /// **'Find Near Me'**
  String get placeDetailsFindNearMe;

  /// No description provided for @placeDetailsViewMap.
  ///
  /// In en, this message translates to:
  /// **'View Map'**
  String get placeDetailsViewMap;

  /// No description provided for @placeDetailsViewMore.
  ///
  /// In en, this message translates to:
  /// **'View more'**
  String get placeDetailsViewMore;

  /// No description provided for @placeDetailsViewFeed.
  ///
  /// In en, this message translates to:
  /// **'View Feed'**
  String get placeDetailsViewFeed;

  /// No description provided for @placeDetailsViewAll.
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get placeDetailsViewAll;

  /// No description provided for @placeDetailsStartJourney.
  ///
  /// In en, this message translates to:
  /// **'Start Journey'**
  String get placeDetailsStartJourney;

  /// No description provided for @adminMode.
  ///
  /// In en, this message translates to:
  /// **'Admin Mode'**
  String get adminMode;

  /// No description provided for @adminDashboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Admin Dashboard'**
  String get adminDashboardTitle;

  /// No description provided for @adminManagePlaces.
  ///
  /// In en, this message translates to:
  /// **'Manage Places'**
  String get adminManagePlaces;

  /// No description provided for @adminManageActivities.
  ///
  /// In en, this message translates to:
  /// **'Manage Activities'**
  String get adminManageActivities;

  /// No description provided for @adminPlaceListTitle.
  ///
  /// In en, this message translates to:
  /// **'Places'**
  String get adminPlaceListTitle;

  /// No description provided for @adminPlaceEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Place'**
  String get adminPlaceEditTitle;

  /// No description provided for @adminActivityListTitle.
  ///
  /// In en, this message translates to:
  /// **'Activities'**
  String get adminActivityListTitle;

  /// No description provided for @adminActivityEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Activity'**
  String get adminActivityEditTitle;

  /// No description provided for @adminCreatePlace.
  ///
  /// In en, this message translates to:
  /// **'Create Place'**
  String get adminCreatePlace;

  /// No description provided for @adminCreateActivity.
  ///
  /// In en, this message translates to:
  /// **'Create Activity'**
  String get adminCreateActivity;

  /// No description provided for @adminCreate.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get adminCreate;

  /// No description provided for @adminEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get adminEdit;

  /// No description provided for @adminEnable.
  ///
  /// In en, this message translates to:
  /// **'Enable'**
  String get adminEnable;

  /// No description provided for @adminDisable.
  ///
  /// In en, this message translates to:
  /// **'Disable'**
  String get adminDisable;

  /// No description provided for @adminEnabled.
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get adminEnabled;

  /// No description provided for @adminDisabled.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get adminDisabled;

  /// No description provided for @adminSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search by id or name'**
  String get adminSearchHint;

  /// No description provided for @adminNoData.
  ///
  /// In en, this message translates to:
  /// **'No data'**
  String get adminNoData;

  /// No description provided for @adminLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load admin data.'**
  String get adminLoadFailed;

  /// No description provided for @adminSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to save changes.'**
  String get adminSaveFailed;

  /// No description provided for @adminDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete item.'**
  String get adminDeleteFailed;

  /// No description provided for @adminDeleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this item?'**
  String get adminDeleteConfirmTitle;

  /// No description provided for @adminDeleteConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone.'**
  String get adminDeleteConfirmMessage;

  /// No description provided for @adminBasicInfo.
  ///
  /// In en, this message translates to:
  /// **'Basic Info'**
  String get adminBasicInfo;

  /// No description provided for @adminMapSettings.
  ///
  /// In en, this message translates to:
  /// **'Map Settings'**
  String get adminMapSettings;

  /// No description provided for @adminMarkerSettings.
  ///
  /// In en, this message translates to:
  /// **'Marker Settings'**
  String get adminMarkerSettings;

  /// No description provided for @adminPreviewCard.
  ///
  /// In en, this message translates to:
  /// **'Preview Card'**
  String get adminPreviewCard;

  /// No description provided for @adminPlaceDetails.
  ///
  /// In en, this message translates to:
  /// **'Place Details'**
  String get adminPlaceDetails;

  /// No description provided for @adminSubcontent.
  ///
  /// In en, this message translates to:
  /// **'Subcontent'**
  String get adminSubcontent;

  /// No description provided for @adminExperiences.
  ///
  /// In en, this message translates to:
  /// **'Experiences'**
  String get adminExperiences;

  /// No description provided for @adminFlavors.
  ///
  /// In en, this message translates to:
  /// **'Flavors'**
  String get adminFlavors;

  /// No description provided for @adminStays.
  ///
  /// In en, this message translates to:
  /// **'Stays'**
  String get adminStays;

  /// No description provided for @adminGallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get adminGallery;

  /// No description provided for @adminName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get adminName;

  /// No description provided for @adminTags.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get adminTags;

  /// No description provided for @adminTagsHint.
  ///
  /// In en, this message translates to:
  /// **'Separate tags with commas'**
  String get adminTagsHint;

  /// No description provided for @adminRegionId.
  ///
  /// In en, this message translates to:
  /// **'Region ID'**
  String get adminRegionId;

  /// No description provided for @adminLatitude.
  ///
  /// In en, this message translates to:
  /// **'Latitude'**
  String get adminLatitude;

  /// No description provided for @adminLongitude.
  ///
  /// In en, this message translates to:
  /// **'Longitude'**
  String get adminLongitude;

  /// No description provided for @adminFlyToZoom.
  ///
  /// In en, this message translates to:
  /// **'Fly To Zoom'**
  String get adminFlyToZoom;

  /// No description provided for @adminFlyToPitch.
  ///
  /// In en, this message translates to:
  /// **'Fly To Pitch'**
  String get adminFlyToPitch;

  /// No description provided for @adminFlyToBearing.
  ///
  /// In en, this message translates to:
  /// **'Fly To Bearing'**
  String get adminFlyToBearing;

  /// No description provided for @adminMarkerType.
  ///
  /// In en, this message translates to:
  /// **'Marker Type'**
  String get adminMarkerType;

  /// No description provided for @adminMarkerLatitude.
  ///
  /// In en, this message translates to:
  /// **'Marker Latitude'**
  String get adminMarkerLatitude;

  /// No description provided for @adminMarkerLongitude.
  ///
  /// In en, this message translates to:
  /// **'Marker Longitude'**
  String get adminMarkerLongitude;

  /// No description provided for @adminCoverImageUrl.
  ///
  /// In en, this message translates to:
  /// **'Cover Image URL'**
  String get adminCoverImageUrl;

  /// No description provided for @adminQuote.
  ///
  /// In en, this message translates to:
  /// **'Quote'**
  String get adminQuote;

  /// No description provided for @adminShortDescription.
  ///
  /// In en, this message translates to:
  /// **'Short Description'**
  String get adminShortDescription;

  /// No description provided for @adminLongDescription.
  ///
  /// In en, this message translates to:
  /// **'Long Description'**
  String get adminLongDescription;

  /// No description provided for @adminOrder.
  ///
  /// In en, this message translates to:
  /// **'Order'**
  String get adminOrder;

  /// No description provided for @adminTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get adminTitle;

  /// No description provided for @adminBadge.
  ///
  /// In en, this message translates to:
  /// **'Badge'**
  String get adminBadge;

  /// No description provided for @adminSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Subtitle'**
  String get adminSubtitle;

  /// No description provided for @adminImageUrl.
  ///
  /// In en, this message translates to:
  /// **'Image URL'**
  String get adminImageUrl;

  /// No description provided for @adminUploadImage.
  ///
  /// In en, this message translates to:
  /// **'Select and upload image'**
  String get adminUploadImage;

  /// No description provided for @adminUploadingImage.
  ///
  /// In en, this message translates to:
  /// **'Uploading image...'**
  String get adminUploadingImage;

  /// No description provided for @adminImageUploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to upload image.'**
  String get adminImageUploadFailed;

  /// No description provided for @adminImageUploadSuccess.
  ///
  /// In en, this message translates to:
  /// **'Image uploaded.'**
  String get adminImageUploadSuccess;

  /// No description provided for @adminPriceRange.
  ///
  /// In en, this message translates to:
  /// **'Price Range'**
  String get adminPriceRange;

  /// No description provided for @adminCaption.
  ///
  /// In en, this message translates to:
  /// **'Caption'**
  String get adminCaption;

  /// No description provided for @adminSchedule.
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get adminSchedule;

  /// No description provided for @adminCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get adminCategory;

  /// No description provided for @adminCityName.
  ///
  /// In en, this message translates to:
  /// **'City Name'**
  String get adminCityName;

  /// No description provided for @adminCountryName.
  ///
  /// In en, this message translates to:
  /// **'Country Name'**
  String get adminCountryName;

  /// No description provided for @adminCityCode.
  ///
  /// In en, this message translates to:
  /// **'City Code'**
  String get adminCityCode;

  /// No description provided for @adminPlaceId.
  ///
  /// In en, this message translates to:
  /// **'Place ID'**
  String get adminPlaceId;

  /// No description provided for @adminStartAtIso.
  ///
  /// In en, this message translates to:
  /// **'Start At (ISO-8601)'**
  String get adminStartAtIso;

  /// No description provided for @adminEndAtIso.
  ///
  /// In en, this message translates to:
  /// **'End At (ISO-8601)'**
  String get adminEndAtIso;

  /// No description provided for @adminFeatured.
  ///
  /// In en, this message translates to:
  /// **'Featured'**
  String get adminFeatured;

  /// No description provided for @adminDetailText.
  ///
  /// In en, this message translates to:
  /// **'Detail Text'**
  String get adminDetailText;

  /// No description provided for @communityTabFollowing.
  ///
  /// In en, this message translates to:
  /// **'Following'**
  String get communityTabFollowing;

  /// No description provided for @communityTabLatest.
  ///
  /// In en, this message translates to:
  /// **'Latest'**
  String get communityTabLatest;

  /// No description provided for @communityTabPopular.
  ///
  /// In en, this message translates to:
  /// **'Popular'**
  String get communityTabPopular;

  /// No description provided for @communityTabNearby.
  ///
  /// In en, this message translates to:
  /// **'Nearby'**
  String get communityTabNearby;

  /// No description provided for @communitySearchTooltip.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get communitySearchTooltip;

  /// No description provided for @communityCreatePostTitle.
  ///
  /// In en, this message translates to:
  /// **'Create post'**
  String get communityCreatePostTitle;

  /// No description provided for @communityCreatePostTitleOptional.
  ///
  /// In en, this message translates to:
  /// **'Title (Optional)'**
  String get communityCreatePostTitleOptional;

  /// No description provided for @communityCreatePostTitleHint.
  ///
  /// In en, this message translates to:
  /// **'Add a short title'**
  String get communityCreatePostTitleHint;

  /// No description provided for @communityCreatePostContentRequired.
  ///
  /// In en, this message translates to:
  /// **'Content (Required)'**
  String get communityCreatePostContentRequired;

  /// No description provided for @communityCreatePostContentHint.
  ///
  /// In en, this message translates to:
  /// **'Share what you discovered today'**
  String get communityCreatePostContentHint;

  /// No description provided for @communityCreatePostAddImage.
  ///
  /// In en, this message translates to:
  /// **'Add image'**
  String get communityCreatePostAddImage;

  /// No description provided for @communityCreatePostAddLocation.
  ///
  /// In en, this message translates to:
  /// **'Add location'**
  String get communityCreatePostAddLocation;

  /// No description provided for @communityCreatePostRemoveLocation.
  ///
  /// In en, this message translates to:
  /// **'Remove location'**
  String get communityCreatePostRemoveLocation;

  /// No description provided for @communityCreatePostDragToRemove.
  ///
  /// In en, this message translates to:
  /// **'Drag here to remove'**
  String get communityCreatePostDragToRemove;

  /// No description provided for @communityCreatePostSelectedImages.
  ///
  /// In en, this message translates to:
  /// **'Selected images ({current}/{max})'**
  String communityCreatePostSelectedImages(Object current, Object max);

  /// No description provided for @communityCreatePostImageLimitReached.
  ///
  /// In en, this message translates to:
  /// **'You can add up to {max} images. Kept the first {max}.'**
  String communityCreatePostImageLimitReached(Object max);

  /// No description provided for @communityCreatePostRemoveImage.
  ///
  /// In en, this message translates to:
  /// **'Remove image'**
  String get communityCreatePostRemoveImage;

  /// No description provided for @communityImageMoreCount.
  ///
  /// In en, this message translates to:
  /// **'+{count}'**
  String communityImageMoreCount(Object count);

  /// No description provided for @communityImageMoreHint.
  ///
  /// In en, this message translates to:
  /// **'View {count} more images in post details'**
  String communityImageMoreHint(Object count);

  /// No description provided for @commonImageViewerClose.
  ///
  /// In en, this message translates to:
  /// **'Close image viewer'**
  String get commonImageViewerClose;

  /// No description provided for @commonImageViewerPageLabel.
  ///
  /// In en, this message translates to:
  /// **'{current} / {total}'**
  String commonImageViewerPageLabel(Object current, Object total);

  /// No description provided for @communityCreatePostSubmit.
  ///
  /// In en, this message translates to:
  /// **'Post'**
  String get communityCreatePostSubmit;

  /// No description provided for @communityLocationSearchTitle.
  ///
  /// In en, this message translates to:
  /// **'Search location'**
  String get communityLocationSearchTitle;

  /// No description provided for @communityLocationSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search by city or place name'**
  String get communityLocationSearchHint;

  /// No description provided for @communityLocationSearchEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Enter a keyword to search locations.'**
  String get communityLocationSearchEmptyHint;

  /// No description provided for @communityLocationSearchEmptyResult.
  ///
  /// In en, this message translates to:
  /// **'No matching locations found.'**
  String get communityLocationSearchEmptyResult;

  /// No description provided for @communityLocationSearchFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to search locations. Please try again.'**
  String get communityLocationSearchFailed;

  /// No description provided for @communityRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get communityRetry;

  /// No description provided for @communityLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load posts. Please try again later.'**
  String get communityLoadFailed;

  /// No description provided for @communityEmptyPosts.
  ///
  /// In en, this message translates to:
  /// **'No posts yet.'**
  String get communityEmptyPosts;

  /// No description provided for @communityContentEmpty.
  ///
  /// In en, this message translates to:
  /// **'Please enter post content.'**
  String get communityContentEmpty;

  /// No description provided for @communityPublishFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to publish post. Please try again later.'**
  String get communityPublishFailed;

  /// No description provided for @communityCommentsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No comments yet.'**
  String get communityCommentsEmpty;

  /// No description provided for @communityCommentHint.
  ///
  /// In en, this message translates to:
  /// **'Write a comment...'**
  String get communityCommentHint;

  /// No description provided for @communityCommentSend.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get communityCommentSend;

  /// No description provided for @communityReplyAction.
  ///
  /// In en, this message translates to:
  /// **'Reply'**
  String get communityReplyAction;

  /// No description provided for @communityCancelReply.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get communityCancelReply;

  /// No description provided for @communityHideReplies.
  ///
  /// In en, this message translates to:
  /// **'Hide replies'**
  String get communityHideReplies;

  /// No description provided for @communityCommentEmpty.
  ///
  /// In en, this message translates to:
  /// **'Please enter comment content.'**
  String get communityCommentEmpty;

  /// No description provided for @communityCommentSubmitFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to send comment. Please try again later.'**
  String get communityCommentSubmitFailed;

  /// No description provided for @communityReplyingToUser.
  ///
  /// In en, this message translates to:
  /// **'Replying to {name}'**
  String communityReplyingToUser(Object name);

  /// No description provided for @communityViewAllReplies.
  ///
  /// In en, this message translates to:
  /// **'View all {count} replies'**
  String communityViewAllReplies(Object count);

  /// No description provided for @communityReplyPreview.
  ///
  /// In en, this message translates to:
  /// **'{userName} replied to {replyToUserName}: {content}'**
  String communityReplyPreview(Object userName, Object replyToUserName, Object content);

  /// No description provided for @communityPostDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Post details'**
  String get communityPostDetailTitle;

  /// No description provided for @communityCommentsTitle.
  ///
  /// In en, this message translates to:
  /// **'Comments'**
  String get communityCommentsTitle;

  /// No description provided for @communityDeleteAction.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get communityDeleteAction;

  /// No description provided for @communityDeletePostAction.
  ///
  /// In en, this message translates to:
  /// **'Delete post'**
  String get communityDeletePostAction;

  /// No description provided for @communityDeleteCommentAction.
  ///
  /// In en, this message translates to:
  /// **'Delete comment'**
  String get communityDeleteCommentAction;

  /// No description provided for @communityDeletePostTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this post?'**
  String get communityDeletePostTitle;

  /// No description provided for @communityDeletePostMessage.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone.'**
  String get communityDeletePostMessage;

  /// No description provided for @communityDeleteCommentTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this comment?'**
  String get communityDeleteCommentTitle;

  /// No description provided for @communityDeleteCommentMessage.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone.'**
  String get communityDeleteCommentMessage;

  /// No description provided for @communityDeletePostFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete post. Please try again later.'**
  String get communityDeletePostFailed;

  /// No description provided for @communityDeleteCommentFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete comment. Please try again later.'**
  String get communityDeleteCommentFailed;

  /// No description provided for @communityUserProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get communityUserProfileTitle;

  /// No description provided for @communityFollowAction.
  ///
  /// In en, this message translates to:
  /// **'Follow'**
  String get communityFollowAction;

  /// No description provided for @communityUnfollowAction.
  ///
  /// In en, this message translates to:
  /// **'Unfollow'**
  String get communityUnfollowAction;

  /// No description provided for @communityFollowFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to update follow status. Please try again later.'**
  String get communityFollowFailed;

  /// No description provided for @communityLikeFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to update like status. Please try again later.'**
  String get communityLikeFailed;

  /// No description provided for @communityStatPosts.
  ///
  /// In en, this message translates to:
  /// **'Posts'**
  String get communityStatPosts;

  /// No description provided for @communityStatFollowers.
  ///
  /// In en, this message translates to:
  /// **'Followers'**
  String get communityStatFollowers;

  /// No description provided for @communityStatFollowing.
  ///
  /// In en, this message translates to:
  /// **'Following'**
  String get communityStatFollowing;

  /// No description provided for @communityStatLikesReceived.
  ///
  /// In en, this message translates to:
  /// **'Likes'**
  String get communityStatLikesReceived;

  /// No description provided for @communityFollowingListTitle.
  ///
  /// In en, this message translates to:
  /// **'Following'**
  String get communityFollowingListTitle;

  /// No description provided for @communityFollowingListEmpty.
  ///
  /// In en, this message translates to:
  /// **'This user is not following anyone yet.'**
  String get communityFollowingListEmpty;

  /// No description provided for @communityUserPostsTitle.
  ///
  /// In en, this message translates to:
  /// **'Posts'**
  String get communityUserPostsTitle;

  /// No description provided for @communityPostNotFound.
  ///
  /// In en, this message translates to:
  /// **'Post not found.'**
  String get communityPostNotFound;

  /// No description provided for @communityUserNotFound.
  ///
  /// In en, this message translates to:
  /// **'User not found.'**
  String get communityUserNotFound;

  /// No description provided for @communityMockUserLuna.
  ///
  /// In en, this message translates to:
  /// **'Luna'**
  String get communityMockUserLuna;

  /// No description provided for @communityMockUserNoah.
  ///
  /// In en, this message translates to:
  /// **'Noah'**
  String get communityMockUserNoah;

  /// No description provided for @communityMockUserIris.
  ///
  /// In en, this message translates to:
  /// **'Iris'**
  String get communityMockUserIris;

  /// No description provided for @communityMockPostOneTitle.
  ///
  /// In en, this message translates to:
  /// **'Night market snapshot guide'**
  String get communityMockPostOneTitle;

  /// No description provided for @communityMockPostOneSummary.
  ///
  /// In en, this message translates to:
  /// **'Street snacks, neon signs, and a route worth saving.'**
  String get communityMockPostOneSummary;

  /// No description provided for @communityMockPostOneContent.
  ///
  /// In en, this message translates to:
  /// **'I walked from the old bridge to the riverside night market and found a surprisingly smooth photo route. The seafood stall near the entrance gets crowded after sunset, but the handmade dessert cart is still underrated. If you like warm lights and easy street shots, this corner is worth staying for an extra hour.'**
  String get communityMockPostOneContent;

  /// No description provided for @communityMockPostOneTime.
  ///
  /// In en, this message translates to:
  /// **'2h ago'**
  String get communityMockPostOneTime;

  /// No description provided for @communityMockPostOneLocation.
  ///
  /// In en, this message translates to:
  /// **'Huangpu Riverside'**
  String get communityMockPostOneLocation;

  /// No description provided for @communityMockPostTwoTitle.
  ///
  /// In en, this message translates to:
  /// **'Morning run by the river'**
  String get communityMockPostTwoTitle;

  /// No description provided for @communityMockPostTwoSummary.
  ///
  /// In en, this message translates to:
  /// **'Cool breeze, open track, and a great sunrise reflection.'**
  String get communityMockPostTwoSummary;

  /// No description provided for @communityMockPostTwoContent.
  ///
  /// In en, this message translates to:
  /// **'The riverside path was almost empty at 6:30 this morning, so the whole route felt calm and clean. There are several benches with a clear skyline view, which makes it a nice place to run slowly or just sit down for ten minutes.'**
  String get communityMockPostTwoContent;

  /// No description provided for @communityMockPostTwoTime.
  ///
  /// In en, this message translates to:
  /// **'5h ago'**
  String get communityMockPostTwoTime;

  /// No description provided for @communityMockPostTwoLocation.
  ///
  /// In en, this message translates to:
  /// **'West Bund'**
  String get communityMockPostTwoLocation;

  /// No description provided for @communityMockPostThreeTitle.
  ///
  /// In en, this message translates to:
  /// **'Cafe with the best window light'**
  String get communityMockPostThreeTitle;

  /// No description provided for @communityMockPostThreeSummary.
  ///
  /// In en, this message translates to:
  /// **'Soft sunlight, quiet seats, and a corner for slow afternoons.'**
  String get communityMockPostThreeSummary;

  /// No description provided for @communityMockPostThreeContent.
  ///
  /// In en, this message translates to:
  /// **'I stayed in this cafe for nearly an entire afternoon because the window light kept changing in a really gentle way. The second-floor corner seat is the best choice if you want photos, reading time, or a quiet chat with friends.'**
  String get communityMockPostThreeContent;

  /// No description provided for @communityMockPostThreeTime.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get communityMockPostThreeTime;

  /// No description provided for @communityMockPostThreeLocation.
  ///
  /// In en, this message translates to:
  /// **'Anfu Road'**
  String get communityMockPostThreeLocation;
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
