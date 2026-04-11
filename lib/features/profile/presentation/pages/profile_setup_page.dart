import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../app/app_router.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/error/app_exception.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/domain/entities/auth_user.dart';
import '../widgets/profile_form.dart';

class ProfileSetupPage extends StatefulWidget {
  const ProfileSetupPage({super.key});

  @override
  State<ProfileSetupPage> createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends State<ProfileSetupPage> {
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

  @override
  void initState() {
    super.initState();

    final name = _currentUser?.displayName?.trim();
    if (name != null && name.isNotEmpty && _nicknameController.text.isEmpty) {
      _nicknameController.text = name;
    }
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
      // 首次资料填写完成后，进入首页。
      context.go(AppRouter.home);
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

    if (t == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return PopScope(
      // 首次资料页禁用返回，避免误触返回导致重新走登录流程。
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFFF3F3F3),
        appBar: AppBar(
          title: Text(t.profileSetupTitle),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          automaticallyImplyLeading: false,
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
            submitText: t.profileContinue,
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
      ),
    );
  }
}
