import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/domain/entities/auth_user.dart';
import 'avatar_picker.dart';

class ProfileFormValue {
  final String nickname;
  final DateTime? birthday;
  final String gender;
  final String? countryCode;
  final String? countryName;
  final String bio;
  final String? selectedAvatarPath;

  const ProfileFormValue({
    required this.nickname,
    required this.birthday,
    required this.gender,
    required this.countryCode,
    required this.countryName,
    required this.bio,
    required this.selectedAvatarPath,
  });
}

class ProfileForm extends StatelessWidget {
  final AuthUser? currentUser;
  final TextEditingController nicknameController;
  final TextEditingController bioController;
  final DateTime? birthday;
  final String gender;
  final String? countryName;
  final String? countryFlag;
  final String? selectedAvatarPath;
  final String? errorText;
  final bool isSaving;
  final String submitText;
  final VoidCallback onPickAvatar;
  final VoidCallback onPickBirthday;
  final VoidCallback onPickCountry;
  final ValueChanged<String> onGenderChanged;
  final VoidCallback onSubmit;

  const ProfileForm({
    super.key,
    required this.currentUser,
    required this.nicknameController,
    required this.bioController,
    required this.birthday,
    required this.gender,
    required this.countryName,
    required this.countryFlag,
    required this.selectedAvatarPath,
    required this.errorText,
    required this.isSaving,
    required this.submitText,
    required this.onPickAvatar,
    required this.onPickBirthday,
    required this.onPickCountry,
    required this.onGenderChanged,
    required this.onSubmit,
  });

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
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    if (t == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final birthdayText = birthday == null
        ? t.profileBirthday
        : DateFormat('yyyy-MM-dd').format(birthday!);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: AvatarPicker(
              imagePath: selectedAvatarPath,
              imageUrl: currentUser?.photoUrl,
              onTap: onPickAvatar,
            ),
          ),
          const SizedBox(height: 24),
          AppTextField(
            label: t.profileNickname,
            controller: nicknameController,
          ),
          const SizedBox(height: 8),
          Text(
            t.profileNicknameHint,
            style: const TextStyle(color: Colors.black54, fontSize: 12),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: onPickBirthday,
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
          DropdownButtonFormField<String>(
            initialValue: gender,
            decoration: InputDecoration(
              labelText: t.profileGender,
              border: const OutlineInputBorder(),
            ),
            items: [
              DropdownMenuItem(value: 'male', child: Text(t.profileGenderMale)),
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
              onGenderChanged(value);
            },
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: onPickCountry,
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
                  if (countryFlag != null)
                    Text(
                      countryFlag!,
                      style: const TextStyle(fontSize: 22),
                    ),
                  if (countryFlag != null) const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      countryName == null ? t.profileCountryOptional : countryName!,
                    ),
                  ),
                  const Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: bioController,
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
          if (gender.isNotEmpty)
            Text(
              '${t.profileGender}: ${_genderLabel(t, gender)}',
              style: const TextStyle(color: Colors.black54, fontSize: 12),
            ),
          if (errorText != null) ...[
            const SizedBox(height: 12),
            Text(
              errorText!,
              style: const TextStyle(color: Colors.red),
            ),
          ],
          const SizedBox(height: 20),
          AppButton(
            text: submitText,
            onPressed: onSubmit,
            isLoading: isSaving,
            styleType: AppButtonStyleType.blackFilled,
          ),
        ],
      ),
    );
  }
}
