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

  @override
  String get placeDetailsUniqueExperiences => 'Unique Experiences';

  @override
  String get placeDetailsNativeFlavors => 'Native Flavors';

  @override
  String get placeDetailsCuratedStays => 'Curated Stays';

  @override
  String get placeDetailsCommunityMoments => 'Community Moments';

  @override
  String get placeDetailsGallery => 'Gallery';

  @override
  String get placeDetailsFindNearMe => 'Find Near Me';

  @override
  String get placeDetailsViewMap => 'View Map';

  @override
  String get placeDetailsViewMore => 'View more';

  @override
  String get placeDetailsViewFeed => 'View Feed';

  @override
  String get placeDetailsViewAll => 'View All';

  @override
  String get placeDetailsStartJourney => 'Start Journey';

  @override
  String get communityTabFollowing => 'Following';

  @override
  String get communityTabLatest => 'Latest';

  @override
  String get communityTabPopular => 'Popular';

  @override
  String get communityTabNearby => 'Nearby';

  @override
  String get communitySearchTooltip => 'Search';

  @override
  String get communityCreatePostTitle => 'Create post';

  @override
  String get communityCreatePostTitleOptional => 'Title (Optional)';

  @override
  String get communityCreatePostTitleHint => 'Add a short title';

  @override
  String get communityCreatePostContentRequired => 'Content (Required)';

  @override
  String get communityCreatePostContentHint => 'Share what you discovered today';

  @override
  String get communityCreatePostAddImage => 'Add image';

  @override
  String get communityCreatePostAddLocation => 'Add location';

  @override
  String get communityCreatePostRemoveLocation => 'Remove location';

  @override
  String get communityCreatePostDragToRemove => 'Drag here to remove';

  @override
  String communityCreatePostSelectedImages(Object current, Object max) {
    return 'Selected images ($current/$max)';
  }

  @override
  String communityCreatePostImageLimitReached(Object max) {
    return 'You can add up to $max images. Kept the first $max.';
  }

  @override
  String get communityCreatePostRemoveImage => 'Remove image';

  @override
  String communityImageMoreCount(Object count) {
    return '+$count';
  }

  @override
  String communityImageMoreHint(Object count) {
    return 'View $count more images in post details';
  }

  @override
  String get commonImageViewerClose => 'Close image viewer';

  @override
  String commonImageViewerPageLabel(Object current, Object total) {
    return '$current / $total';
  }

  @override
  String get communityCreatePostSubmit => 'Post';

  @override
  String get communityLocationSearchTitle => 'Search location';

  @override
  String get communityLocationSearchHint => 'Search by city or place name';

  @override
  String get communityLocationSearchEmptyHint => 'Enter a keyword to search locations.';

  @override
  String get communityLocationSearchEmptyResult => 'No matching locations found.';

  @override
  String get communityLocationSearchFailed => 'Failed to search locations. Please try again.';

  @override
  String get communityRetry => 'Retry';

  @override
  String get communityLoadFailed => 'Failed to load posts. Please try again later.';

  @override
  String get communityEmptyPosts => 'No posts yet.';

  @override
  String get communityContentEmpty => 'Please enter post content.';

  @override
  String get communityPublishFailed => 'Failed to publish post. Please try again later.';

  @override
  String get communityCommentsEmpty => 'No comments yet.';

  @override
  String get communityCommentHint => 'Write a comment...';

  @override
  String get communityCommentSend => 'Send';

  @override
  String get communityReplyAction => 'Reply';

  @override
  String get communityCancelReply => 'Cancel';

  @override
  String get communityHideReplies => 'Hide replies';

  @override
  String get communityCommentEmpty => 'Please enter comment content.';

  @override
  String get communityCommentSubmitFailed => 'Failed to send comment. Please try again later.';

  @override
  String communityReplyingToUser(Object name) {
    return 'Replying to $name';
  }

  @override
  String communityViewAllReplies(Object count) {
    return 'View all $count replies';
  }

  @override
  String communityReplyPreview(Object userName, Object replyToUserName, Object content) {
    return '$userName replied to $replyToUserName: $content';
  }

  @override
  String get communityPostDetailTitle => 'Post details';

  @override
  String get communityCommentsTitle => 'Comments';

  @override
  String get communityDeleteAction => 'Delete';

  @override
  String get communityDeletePostAction => 'Delete post';

  @override
  String get communityDeleteCommentAction => 'Delete comment';

  @override
  String get communityDeletePostTitle => 'Delete this post?';

  @override
  String get communityDeletePostMessage => 'This action cannot be undone.';

  @override
  String get communityDeleteCommentTitle => 'Delete this comment?';

  @override
  String get communityDeleteCommentMessage => 'This action cannot be undone.';

  @override
  String get communityDeletePostFailed => 'Failed to delete post. Please try again later.';

  @override
  String get communityDeleteCommentFailed => 'Failed to delete comment. Please try again later.';

  @override
  String get communityUserProfileTitle => 'Profile';

  @override
  String get communityFollowAction => 'Follow';

  @override
  String get communityUnfollowAction => 'Unfollow';

  @override
  String get communityFollowFailed => 'Failed to update follow status. Please try again later.';

  @override
  String get communityLikeFailed => 'Failed to update like status. Please try again later.';

  @override
  String get communityStatPosts => 'Posts';

  @override
  String get communityStatFollowers => 'Followers';

  @override
  String get communityStatFollowing => 'Following';

  @override
  String get communityStatLikesReceived => 'Likes';

  @override
  String get communityFollowingListTitle => 'Following';

  @override
  String get communityFollowingListEmpty => 'This user is not following anyone yet.';

  @override
  String get communityUserPostsTitle => 'Posts';

  @override
  String get communityPostNotFound => 'Post not found.';

  @override
  String get communityUserNotFound => 'User not found.';

  @override
  String get communityMockUserLuna => 'Luna';

  @override
  String get communityMockUserNoah => 'Noah';

  @override
  String get communityMockUserIris => 'Iris';

  @override
  String get communityMockPostOneTitle => 'Night market snapshot guide';

  @override
  String get communityMockPostOneSummary => 'Street snacks, neon signs, and a route worth saving.';

  @override
  String get communityMockPostOneContent => 'I walked from the old bridge to the riverside night market and found a surprisingly smooth photo route. The seafood stall near the entrance gets crowded after sunset, but the handmade dessert cart is still underrated. If you like warm lights and easy street shots, this corner is worth staying for an extra hour.';

  @override
  String get communityMockPostOneTime => '2h ago';

  @override
  String get communityMockPostOneLocation => 'Huangpu Riverside';

  @override
  String get communityMockPostTwoTitle => 'Morning run by the river';

  @override
  String get communityMockPostTwoSummary => 'Cool breeze, open track, and a great sunrise reflection.';

  @override
  String get communityMockPostTwoContent => 'The riverside path was almost empty at 6:30 this morning, so the whole route felt calm and clean. There are several benches with a clear skyline view, which makes it a nice place to run slowly or just sit down for ten minutes.';

  @override
  String get communityMockPostTwoTime => '5h ago';

  @override
  String get communityMockPostTwoLocation => 'West Bund';

  @override
  String get communityMockPostThreeTitle => 'Cafe with the best window light';

  @override
  String get communityMockPostThreeSummary => 'Soft sunlight, quiet seats, and a corner for slow afternoons.';

  @override
  String get communityMockPostThreeContent => 'I stayed in this cafe for nearly an entire afternoon because the window light kept changing in a really gentle way. The second-floor corner seat is the best choice if you want photos, reading time, or a quiet chat with friends.';

  @override
  String get communityMockPostThreeTime => 'Yesterday';

  @override
  String get communityMockPostThreeLocation => 'Anfu Road';
}
