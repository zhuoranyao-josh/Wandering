import 'package:shared_preferences/shared_preferences.dart';

import 'onboarding_keys.dart';

class OnboardingPreferences {
  const OnboardingPreferences();

  // 只保存“是否看过”的本地状态，不接入账号或 Firebase，避免影响业务数据。
  Future<bool> hasSeenMainGuide() {
    return _readBool(OnboardingKeys.hasSeenMainGuide);
  }

  Future<void> setMainGuideSeen() {
    return _writeBool(OnboardingKeys.hasSeenMainGuide);
  }

  Future<bool> hasSeenWizardGuide() {
    return _readBool(OnboardingKeys.hasSeenWizardGuide);
  }

  Future<void> setWizardGuideSeen() {
    return _writeBool(OnboardingKeys.hasSeenWizardGuide);
  }

  Future<bool> hasSeenChecklistGuide() {
    return _readBool(OnboardingKeys.hasSeenChecklistGuide);
  }

  Future<void> setChecklistGuideSeen() {
    return _writeBool(OnboardingKeys.hasSeenChecklistGuide);
  }

  Future<bool> _readBool(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(key) ?? false;
  }

  Future<void> _writeBool(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, true);
  }
}
