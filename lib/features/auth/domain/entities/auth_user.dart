class AuthUser {
  final String uid;
  final String? email;
  final String? displayName;
  final String? photoUrl;

  final bool isAnonymous;

  const AuthUser({
    required this.uid,
    this.email,
    this.displayName,
    this.photoUrl,
    required this.isAnonymous,
  });
}
