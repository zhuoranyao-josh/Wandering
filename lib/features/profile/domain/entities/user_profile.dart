class UserProfile {
  final String uid;
  final String? email;
  final String authProvider;
  final bool isAnonymous;
  final String role;
  final String? avatarUrl;
  final String nickname;
  final DateTime? birthday;
  final String gender;
  final String? countryCode;
  final String? countryName;
  final String bio;
  final bool profileCompleted;

  const UserProfile({
    required this.uid,
    required this.email,
    required this.authProvider,
    required this.isAnonymous,
    required this.role,
    required this.avatarUrl,
    required this.nickname,
    required this.birthday,
    required this.gender,
    required this.countryCode,
    required this.countryName,
    required this.bio,
    required this.profileCompleted,
  });
}
