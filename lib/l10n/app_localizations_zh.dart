// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get login => '登录';

  @override
  String get register => '注册';

  @override
  String get email => '邮箱';

  @override
  String get password => '密码';

  @override
  String get confirmPassword => '确认密码';

  @override
  String get goToRegister => '没有账号？去注册';

  @override
  String get backToLogin => '已有账号？返回登录';

  @override
  String get loginWithGoogle => '使用 Google 登录';

  @override
  String get logout => '退出登录';

  @override
  String get homeTitle => '主页';

  @override
  String get loginSuccess => '登录成功';

  @override
  String get uidLabel => 'UID';

  @override
  String get emailLabel => '邮箱';

  @override
  String get nameLabel => '昵称';

  @override
  String get errorEmptyFields => '请填写完整信息。';

  @override
  String get errorPasswordMismatch => '两次输入的密码不一致。';

  @override
  String get errorInvalidEmail => '邮箱格式不正确。';

  @override
  String get errorUserNotFound => '用户不存在。';

  @override
  String get errorInvalidCredential => '邮箱或密码错误。';

  @override
  String get errorEmailAlreadyInUse => '该邮箱已被注册。';

  @override
  String get errorWeakPassword => '密码至少需要 6 位。';

  @override
  String get errorGoogleCancelled => '你已取消 Google 登录。';

  @override
  String get errorGoogleFailed => 'Google 登录失败。';

  @override
  String get errorUnknown => '发生未知错误。';

  @override
  String get loginAsGuest => '游客登录';

  @override
  String get forgotPassword => '忘记密码？';

  @override
  String get sendResetEmail => '发送重置邮件';

  @override
  String get resetPasswordHint => '请输入你的邮箱，我们会向该邮箱发送重置密码邮件。';

  @override
  String get resetPasswordEmailSent => '重置密码邮件已发送，请检查你的邮箱。';

  @override
  String get cancel => '取消';

  @override
  String get errorMissingEmail => '请输入邮箱地址。';

  @override
  String get errorTooManyRequests => '请求过于频繁，请稍后再试。';

  @override
  String get errorOperationNotAllowed => '该登录方式尚未启用。';

  @override
  String get welcomeSubtitle => '探索世界各地的城市、故事与旅行。';

  @override
  String get enterLoginOrRegister => '注册 / 登录';

  @override
  String get orText => '或';
}
