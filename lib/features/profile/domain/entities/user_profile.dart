class UserProfile {
  final String uid; // 用户唯一ID（Firebase生成）
  final String? email; // 用户邮箱（游客可能为null）
  final String authProvider; // 登录方式（google / email / anonymous）
  final bool isAnonymous; // 是否为游客登录

  final String? avatarUrl; // 头像图片URL（存储在Firebase Storage）
  final String nickname; // 用户昵称（需要唯一）
  final DateTime? birthday; // 出生日期

  final String gender; // 性别（male / female / other）

  final String? countryCode; // 国家代码（如 CN / US）
  final String? countryName; // 国家名称（如 China / United States）

  final String bio; // 个人简介（限制100字以内）
  final bool profileCompleted; // 是否已完成资料填写（用于判断是否进入主页）

  const UserProfile({
    required this.uid,
    required this.email,
    required this.authProvider,
    required this.isAnonymous,
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
