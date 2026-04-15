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

  @override
  String get profileSetupTitle => 'Set up your profile';

  @override
  String get profileNickname => 'Nickname';

  @override
  String get profileNicknameHint => 'Nickname must be unique';

  @override
  String get profileBirthday => 'Birthday';

  @override
  String get profileGender => 'Gender';

  @override
  String get profileGenderMale => 'Male';

  @override
  String get profileGenderFemale => 'Female';

  @override
  String get profileGenderOther => 'Other';

  @override
  String get profileCountryOptional => 'Country (Optional)';

  @override
  String get profileBio => 'Bio';

  @override
  String get profileBioHint => 'Introduce yourself (max 100 characters)';

  @override
  String get profileContinue => 'Continue';

  @override
  String get profileErrorNicknameEmpty => 'Please enter your nickname.';

  @override
  String get profileErrorNicknameTooLong => 'Nickname cannot exceed 20 characters.';

  @override
  String get profileErrorBioTooLong => 'Bio cannot exceed 100 characters.';

  @override
  String get profileErrorNicknameTaken => 'Your nickname is already used by another user ~';

  @override
  String get profileErrorSaveFailed => 'Failed to save profile. Please try again later.';

  @override
  String get defaultUserName => 'User';

  @override
  String get language => 'Language';

  @override
  String get languageChinese => 'Chinese';

  @override
  String get languageEnglish => 'English';

  @override
  String get profileEditTitle => 'Edit Profile';

  @override
  String get save => 'Save';

  @override
  String get mapTabTitle => 'Map Tab';

  @override
  String get mapTabPlaceholder => 'Map feature placeholder';

  @override
  String get mapHomeLoadingTitle => 'Loading globe';

  @override
  String get mapHomeLoadingMessage => 'Initializing map resources. Please wait.';

  @override
  String get mapHomeLoadFailedTitle => 'Map failed to load';

  @override
  String get mapHomeLoadFailedMessage => 'The map could not be initialized right now. Please try again.';

  @override
  String get mapHomeRetry => 'Retry';

  @override
  String get mapHomeMissingTokenTitle => 'Missing Mapbox configuration';

  @override
  String get mapHomeMissingTokenMessage => 'Inject a Mapbox access token with dart-define before running the app.';

  @override
  String get mapHomeUnsupportedTitle => 'Map is not supported on this platform';

  @override
  String get mapHomeUnsupportedMessage => 'The Mapbox Flutter SDK currently supports Android and iOS only.';

  @override
  String get mapHomeSwitchToDay => 'Switch to day mode';

  @override
  String get mapHomeSwitchToNight => 'Switch to night mode';

  @override
  String get mapPlaceTokyoName => 'Tokyo';

  @override
  String get mapPlaceTokyoDescription => 'A neon-lit test city used to validate globe markers, camera transitions, and the floating preview card.';

  @override
  String get mapPlaceNewYorkName => 'New York';

  @override
  String get mapPlaceNewYorkDescription => 'A test city used to validate globe markers, camera transitions, and the floating preview card.';

  @override
  String get mapPlaceLosAngelesName => 'Los Angeles';

  @override
  String get mapPlaceLosAngelesDescription => 'A test city used to validate globe markers, camera transitions, and the floating preview card.';

  @override
  String get mapPlaceMoscowName => 'Moscow';

  @override
  String get mapPlaceMoscowDescription => 'A test city used to validate globe markers, camera transitions, and the floating preview card.';

  @override
  String get mapPlaceSaintPetersburgName => 'Saint Petersburg';

  @override
  String get mapPlaceSaintPetersburgDescription => 'A test city used to validate globe markers, camera transitions, and the floating preview card.';

  @override
  String get mapPlaceYokohamaName => 'Yokohama';

  @override
  String get mapPlaceYokohamaDescription => 'A test city used to validate globe markers, camera transitions, and the floating preview card.';

  @override
  String get mapPlaceOsakaName => 'Osaka';

  @override
  String get mapPlaceOsakaDescription => 'A test city used to validate globe markers, camera transitions, and the floating preview card.';

  @override
  String get mapPlaceBeijingName => 'Beijing';

  @override
  String get mapPlaceBeijingDescription => 'A test city used to validate globe markers, camera transitions, and the floating preview card.';

  @override
  String get mapPlaceShanghaiName => 'Shanghai';

  @override
  String get mapPlaceShanghaiDescription => 'A test city used to validate globe markers, camera transitions, and the floating preview card.';

  @override
  String get mapPlaceGuangzhouName => 'Guangzhou';

  @override
  String get mapPlaceGuangzhouDescription => 'A test city used to validate globe markers, camera transitions, and the floating preview card.';

  @override
  String get mapPlaceTianjinName => 'Tianjin';

  @override
  String get mapPlaceTianjinDescription => 'A test city used to validate globe markers, camera transitions, and the floating preview card.';

  @override
  String get mapPlaceLhasaName => 'Lhasa';

  @override
  String get mapPlaceLhasaDescription => 'A test city used to validate globe markers, camera transitions, and the floating preview card.';

  @override
  String get mapPlaceSuzhouName => 'Suzhou';

  @override
  String get mapPlaceSuzhouDescription => 'A test city used to validate globe markers, camera transitions, and the floating preview card.';

  @override
  String get mapPlaceMunichName => 'Munich';

  @override
  String get mapPlaceMunichDescription => 'A test city used to validate globe markers, camera transitions, and the floating preview card.';

  @override
  String get mapPlaceBerlinName => 'Berlin';

  @override
  String get mapPlaceBerlinDescription => 'A test city used to validate globe markers, camera transitions, and the floating preview card.';

  @override
  String get mapPlaceFrankfurtName => 'Frankfurt';

  @override
  String get mapPlaceFrankfurtDescription => 'A test city used to validate globe markers, camera transitions, and the floating preview card.';

  @override
  String get mapPlaceIstanbulName => 'Istanbul';

  @override
  String get mapPlaceIstanbulDescription => 'A test city used to validate globe markers, camera transitions, and the floating preview card.';

  @override
  String get mapPlaceTorontoName => 'Toronto';

  @override
  String get mapPlaceTorontoDescription => 'A test city used to validate globe markers, camera transitions, and the floating preview card.';

  @override
  String get mapPlaceBuenosAiresName => 'Buenos Aires';

  @override
  String get mapPlaceBuenosAiresDescription => 'A test city used to validate globe markers, camera transitions, and the floating preview card.';

  @override
  String get mapPlaceSaoPauloName => 'Sao Paulo';

  @override
  String get mapPlaceSaoPauloDescription => 'A test city used to validate globe markers, camera transitions, and the floating preview card.';

  @override
  String get mapPlaceCairoName => 'Cairo';

  @override
  String get mapPlaceCairoDescription => 'A test city used to validate globe markers, camera transitions, and the floating preview card.';

  @override
  String get mapPlaceCapeTownName => 'Cape Town';

  @override
  String get mapPlaceCapeTownDescription => 'A test city used to validate globe markers, camera transitions, and the floating preview card.';

  @override
  String get mapPlaceSydneyName => 'Sydney';

  @override
  String get mapPlaceSydneyDescription => 'A test city used to validate globe markers, camera transitions, and the floating preview card.';

  @override
  String get mapPlaceMelbourneName => 'Melbourne';

  @override
  String get mapPlaceMelbourneDescription => 'A test city used to validate globe markers, camera transitions, and the floating preview card.';

  @override
  String get mapPlaceWellingtonName => 'Wellington';

  @override
  String get mapPlaceWellingtonDescription => 'A test city used to validate globe markers, camera transitions, and the floating preview card.';

  @override
  String get mapPlaceHongKongName => 'Hong Kong';

  @override
  String get mapPlaceHongKongDescription => 'A test city used to validate globe markers, camera transitions, and the floating preview card.';

  @override
  String get mapPlaceParisName => 'Paris';

  @override
  String get mapPlaceParisDescription => 'A test city used to validate globe markers, camera transitions, and the floating preview card.';

  @override
  String get mapPlaceLondonName => 'London';

  @override
  String get mapPlaceLondonDescription => 'A test city used to validate globe markers, camera transitions, and the floating preview card.';

  @override
  String get activitySearchHint => 'Search by event title or city';

  @override
  String get activityUpcomingTitle => 'Coming soon:';

  @override
  String get activityLoadFailed => 'Failed to load events. Please try again later.';

  @override
  String get activityRetry => 'Retry';

  @override
  String get activityEmptyDefault => 'No published events yet.';

  @override
  String get activityEmptyFiltered => 'No events match the current filters.';

  @override
  String get activitySelectDateRange => 'Select date or date range';

  @override
  String get activityClearDateFilter => 'Clear date filter';

  @override
  String get activityDateFilterLabel => 'Date';

  @override
  String get activityCategoryAll => 'All';

  @override
  String get activityCategoryTraditionalFestival => 'Traditional Festival';

  @override
  String get activityCategoryMusic => 'Music';

  @override
  String get activityCategoryExhibition => 'Exhibition';

  @override
  String get activityCategoryEntertainment => 'Entertainment';

  @override
  String get activityCategoryNature => 'Nature';

  @override
  String get activityDetailTitle => 'Event details';

  @override
  String get activityDetailEmpty => 'Detailed information will be available soon.';

  @override
  String get activityDetailNotFound => 'This event could not be found.';

  @override
  String get activityBack => 'Back';

  @override
  String get activityAlwaysOpen => 'Always open';

  @override
  String activityLongTermOpenFrom(Object date) {
    return 'Open from $date';
  }

  @override
  String activityOpenUntil(Object date) {
    return 'Open until $date';
  }

  @override
  String get viewDetails => 'View details';
}
