import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../../app/router.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/error/app_exception.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/domain/entities/auth_user.dart';
import '../widgets/avatar_picker.dart';

class ProfileSetupPage extends StatefulWidget {
  const ProfileSetupPage({super.key});

  @override
  State<ProfileSetupPage> createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends State<ProfileSetupPage> {
  // 资料设置页对应的 controller
  // 注意：这里拿的是 controller，不是 Firebase
  // 所以仍然遵守“页面层不直接碰 Firebase”的规则
  final _controller = ServiceLocator.profileSetupController;

  // 当前登录用户
  // 如果是 Google 登录，displayName / photoUrl 往往会有值
  final AuthUser? _currentUser = ServiceLocator.authController.getCurrentUser();

  // 文本输入控制器
  final _nicknameController = TextEditingController();
  final _bioController = TextEditingController();

  // 用户选择的生日
  DateTime? _birthday;

  // 性别默认先给 other
  String _gender = 'other';

  // 国家信息是可选的
  String? _countryCode;
  String? _countryName;
  String? _countryFlag;

  // 用户从相册新选择的头像本地路径
  String? _selectedAvatarPath;

  // 提交时的加载状态
  bool _isSaving = false;

  // 用来存错误码
  // 页面不会直接处理 Firebase 异常，而是只处理统一的 AppException.code
  String? _errorCode;

  @override
  void initState() {
    super.initState();

    final name = _currentUser?.displayName?.trim();

    if (name != null && name.isNotEmpty && _nicknameController.text.isEmpty) {
      _nicknameController.text = name;
    }
  }

  // 把错误码翻译成当前语言的提示文本
  String _localizedError(AppLocalizations t, String code) {
    switch (code) {
      case 'nickname_empty':
        return t.profileErrorNicknameEmpty;
      case 'nickname_too_long':
        return t.profileErrorNicknameTooLong;
      case 'bio_too_long':
        return t.profileErrorBioTooLong;
      case 'nickname_taken':
        return t.profileErrorNicknameTaken;
      case 'profile_save_failed':
        return t.profileErrorSaveFailed;
      default:
        return t.errorUnknown;
    }
  }

  // 选择头像
  Future<void> _pickAvatar() async {
    final picker = ImagePicker();

    // 从相册选一张图片
    final XFile? file = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    // 用户取消选择时，file 会是 null
    if (file == null) return;

    setState(() {
      _selectedAvatarPath = file.path;
    });
  }

  // 选择生日
  Future<void> _pickBirthday() async {
    final now = DateTime.now();

    final picked = await showDatePicker(
      context: context,
      // 默认给一个比较常见的初始年龄
      initialDate: DateTime(now.year - 20, 1, 1),
      firstDate: DateTime(1900),
      lastDate: now,
      locale: Localizations.localeOf(context),
    );

    if (picked == null) return;

    setState(() {
      _birthday = picked;
    });
  }

  // 选择国家
  Future<void> _pickCountry() async {
    showCountryPicker(
      context: context,
      showPhoneCode: false,
      showSearch: true,

      // 这里的 onSelect 会在用户点选某个国家后触发
      onSelect: (Country country) {
        setState(() {
          _countryCode = country.countryCode;
          _countryName = country.name;
          _countryFlag = country.flagEmoji;
        });
      },
    );
  }

  // 提交资料
  Future<void> _submit() async {
    final AuthUser? currentUser = _currentUser;

    if (currentUser == null) {
      setState(() {
        _errorCode = 'profile_save_failed';
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _errorCode = null;
    });

    try {
      await _controller.submitProfile(
        currentUser: currentUser,
        nickname: _nicknameController.text,
        birthday: _birthday,
        gender: _gender,
        countryCode: _countryCode,
        countryName: _countryName,
        bio: _bioController.text,
        avatarLocalPath: _selectedAvatarPath,
      );

      if (!mounted) return;

      // 保存成功后进入主页
      Navigator.pushReplacementNamed(context, AppRouter.home);
    } on AppException catch (e) {
      setState(() {
        _errorCode = e.code;
      });
    } catch (_) {
      setState(() {
        _errorCode = 'profile_save_failed';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  // 性别显示文本
  String _genderLabel(AppLocalizations t, String value) {
    switch (value) {
      case 'male':
        return t.profileGenderMale;
      case 'female':
        return t.profileGenderFemale;
      default:
        return t.profileGenderOther;
    }
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    if (t == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // 用统一格式显示生日
    final birthdayText = _birthday == null
        ? t.profileBirthday
        : DateFormat('yyyy-MM-dd').format(_birthday!);

    return Scaffold(
      backgroundColor: const Color(0xFFF3F3F3),
      appBar: AppBar(
        title: Text(t.profileSetupTitle),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,

        // 按你的要求，这里返回 login page
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacementNamed(context, AppRouter.login);
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 头像选择器
              // 如果是 Google 登录，会优先显示 Google 的头像
              // 如果用户重新选了图，则显示新图
              Center(
                child: AvatarPicker(
                  imagePath: _selectedAvatarPath,
                  imageUrl: _currentUser?.photoUrl,
                  onTap: _pickAvatar,
                ),
              ),

              const SizedBox(height: 24),

              // 昵称
              AppTextField(
                label: t.profileNickname,
                controller: _nicknameController,
              ),
              const SizedBox(height: 8),
              Text(
                t.profileNicknameHint,
                style: const TextStyle(color: Colors.black54, fontSize: 12),
              ),

              const SizedBox(height: 20),

              // 生日
              GestureDetector(
                onTap: _pickBirthday,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black26),
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.white,
                  ),
                  child: Text(birthdayText),
                ),
              ),

              const SizedBox(height: 20),

              // 性别
              DropdownButtonFormField<String>(
                initialValue: _gender,
                decoration: InputDecoration(
                  labelText: t.profileGender,
                  border: const OutlineInputBorder(),
                ),
                items: [
                  DropdownMenuItem(
                    value: 'male',
                    child: Text(t.profileGenderMale),
                  ),
                  DropdownMenuItem(
                    value: 'female',
                    child: Text(t.profileGenderFemale),
                  ),
                  DropdownMenuItem(
                    value: 'other',
                    child: Text(t.profileGenderOther),
                  ),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    _gender = value;
                  });
                },
              ),

              const SizedBox(height: 20),

              // 国家（可选）
              GestureDetector(
                onTap: _pickCountry,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black26),
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.white,
                  ),
                  child: Row(
                    children: [
                      if (_countryFlag != null)
                        Text(
                          _countryFlag!,
                          style: const TextStyle(fontSize: 22),
                        ),
                      if (_countryFlag != null) const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _countryName == null
                              ? t.profileCountryOptional
                              : _countryName!,
                        ),
                      ),
                      const Icon(Icons.arrow_drop_down),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // 自我介绍
              TextField(
                controller: _bioController,
                maxLength: 100,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: t.profileBio,
                  hintText: t.profileBioHint,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),

              const SizedBox(height: 4),

              // 当前选择信息的小提示
              if (_gender.isNotEmpty)
                Text(
                  '${t.profileGender}: ${_genderLabel(t, _gender)}',
                  style: const TextStyle(color: Colors.black54, fontSize: 12),
                ),

              if (_errorCode != null) ...[
                const SizedBox(height: 12),
                Text(
                  _localizedError(t, _errorCode!),
                  style: const TextStyle(color: Colors.red),
                ),
              ],

              const SizedBox(height: 20),

              // 提交按钮
              AppButton(
                text: t.profileContinue,
                onPressed: _submit,
                isLoading: _isSaving,
                styleType: AppButtonStyleType.blackFilled,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
