import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/error/app_exception.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/domain/entities/auth_user.dart';
import '../../domain/entities/user_profile.dart';
import '../widgets/profile_form.dart';

class ProfileEditPage extends StatefulWidget {
  const ProfileEditPage({super.key});

  @override
  State<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends State<ProfileEditPage> {
  final _controller = ServiceLocator.profileSetupController;
  final AuthUser? _currentUser = ServiceLocator.authController.getCurrentUser();

  final _nicknameController = TextEditingController();
  final _bioController = TextEditingController();

  DateTime? _birthday;
  String _gender = 'other';
  String? _countryCode;
  String? _countryName;
  String? _countryFlag;
  String? _selectedAvatarPath;
  bool _isSaving = false;
  String? _errorCode;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _prefillFromProfile();
  }

  Future<void> _prefillFromProfile() async {
    final user = _currentUser;

    if (user == null) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      return;
    }

    final profile = await _controller.getProfile(user.uid);
    if (!mounted) return;
    _applyProfile(profile, user);
  }

  void _applyProfile(UserProfile? profile, AuthUser user) {
    _nicknameController.text = profile?.nickname.isNotEmpty == true
        ? profile!.nickname
        : (user.displayName ?? '');
    _bioController.text = profile?.bio ?? '';
    _birthday = profile?.birthday;
    _gender = profile?.gender ?? 'other';
    _countryCode = profile?.countryCode;
    _countryName = profile?.countryName;
    _countryFlag = _countryCode != null
        ? _countryCodeToEmoji(_countryCode!)
        : null;
    _isLoading = false;
    setState(() {});
  }

  String _countryCodeToEmoji(String code) {
    final upper = code.toUpperCase();
    if (upper.length != 2) return '';
    final int first = upper.codeUnitAt(0) + 127397;
    final int second = upper.codeUnitAt(1) + 127397;
    return String.fromCharCode(first) + String.fromCharCode(second);
  }

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

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();

    final XFile? file = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (file == null) return;

    setState(() {
      _selectedAvatarPath = file.path;
    });
  }

  Future<void> _pickBirthday() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthday ?? DateTime(now.year - 20, 1, 1),
      firstDate: DateTime(1900),
      lastDate: now,
      locale: Localizations.localeOf(context),
    );

    if (picked == null) return;

    setState(() {
      _birthday = picked;
    });
  }

  Future<void> _pickCountry() async {
    showCountryPicker(
      context: context,
      showPhoneCode: false,
      showSearch: true,
      onSelect: (Country country) {
        setState(() {
          _countryCode = country.countryCode;
          _countryName = country.name;
          _countryFlag = country.flagEmoji;
        });
      },
    );
  }

  Future<void> _submit() async {
    final currentUser = _currentUser;
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
      // 保存资料成功后返回上一页（个人中心页）。
      context.pop();
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

  @override
  void dispose() {
    _nicknameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    if (t == null || _isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF3F3F3),
      appBar: AppBar(
        title: Text(t.profileEditTitle),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          // 顶部返回按钮：不保存直接退出编辑页。
          onPressed: () {
            context.pop();
          },
        ),
      ),
      body: SafeArea(
        child: ProfileForm(
          currentUser: _currentUser,
          nicknameController: _nicknameController,
          bioController: _bioController,
          birthday: _birthday,
          gender: _gender,
          countryName: _countryName,
          countryFlag: _countryFlag,
          selectedAvatarPath: _selectedAvatarPath,
          errorText: _errorCode == null
              ? null
              : _localizedError(t, _errorCode!),
          isSaving: _isSaving,
          submitText: t.save,
          onPickAvatar: _pickAvatar,
          onPickBirthday: _pickBirthday,
          onPickCountry: _pickCountry,
          onGenderChanged: (value) {
            setState(() {
              _gender = value;
            });
          },
          onSubmit: _submit,
        ),
      ),
    );
  }
}
