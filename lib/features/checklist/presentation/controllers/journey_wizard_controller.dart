import 'package:flutter/foundation.dart';

import '../../domain/entities/checklist_item.dart';
import '../../domain/entities/journey_basic_info_input.dart';
import '../../domain/repositories/checklist_repository.dart';

class JourneyWizardController extends ChangeNotifier {
  JourneyWizardController({
    required this.repository,
    required this.checklistId,
  });

  static const int minTravelerCount = 1;
  static const int maxTravelerCount = 20;
  static const int maxPreferencesCount = 5;

  static const List<String> preferenceOptions = <String>[
    'food',
    'shopping',
    'culture',
    'nature',
    'museum',
    'anime',
    'nightlife',
    'family',
    'photography',
    'relaxation',
  ];

  static const List<String> paceOptions = <String>[
    'relaxed',
    'balanced',
    'intensive',
  ];

  static const List<String> accommodationOptions = <String>[
    'budget',
    'comfortable',
    'luxury',
  ];

  final ChecklistRepository repository;
  final String checklistId;

  bool _isLoading = false;
  bool _isSaving = false;
  bool _notFound = false;
  String? _errorKey;
  ChecklistItem? _journey;
  int _currentStep = 0;
  final Map<String, String> _fieldErrorKeys = <String, String>{};

  String _departureCity = '';
  String? _departureCountry;
  double? _departureLatitude;
  double? _departureLongitude;
  String? _departureSource;
  DateTime? _startDate;
  DateTime? _endDate;
  int _travelerCount = minTravelerCount;
  double? _totalBudget;
  String _currency = 'CNY';
  Set<String> _preferences = <String>{};
  String _pace = 'balanced';
  String _accommodationPreference = 'comfortable';

  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  bool get notFound => _notFound;
  String? get errorKey => _errorKey;
  ChecklistItem? get journey => _journey;
  int get currentStep => _currentStep;

  String get departureCity => _departureCity;
  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;
  int get travelerCount => _travelerCount;
  double? get totalBudget => _totalBudget;
  String get currency => _currency;
  Set<String> get preferences => _preferences;
  String get pace => _pace;
  String get accommodationPreference => _accommodationPreference;

  int? get tripDays {
    final start = _startDate;
    final end = _endDate;
    if (start == null || end == null) {
      return null;
    }
    if (end.isBefore(start)) {
      return null;
    }
    return end.difference(start).inDays + 1;
  }

  int? get nightCount {
    final start = _startDate;
    final end = _endDate;
    if (start == null || end == null) {
      return null;
    }
    if (end.isBefore(start)) {
      return null;
    }
    return end.difference(start).inDays;
  }

  String? fieldErrorKey(String field) => _fieldErrorKeys[field];

  Future<void> loadJourney() async {
    _isLoading = true;
    _errorKey = null;
    _notFound = false;
    notifyListeners();

    try {
      final item = await repository.getChecklistById(checklistId);
      if (item == null) {
        _notFound = true;
        _journey = null;
      } else {
        _journey = item;
        _applyJourney(item);
      }
    } catch (_) {
      _errorKey = 'checklistLoadFailed';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> retry() => loadJourney();

  void clearError() {
    _errorKey = null;
  }

  void setDepartureCity(String value) {
    _departureCity = value;
    _departureSource = 'manual';
    _fieldErrorKeys.remove('departureCity');
  }

  void setStartDate(DateTime value) {
    _startDate = value;
    _fieldErrorKeys.remove('startDate');
    if (_endDate != null && _endDate!.isBefore(value)) {
      _fieldErrorKeys['endDate'] = 'journeyWizardErrorEndDateBeforeStartDate';
    } else {
      _fieldErrorKeys.remove('endDate');
    }
    notifyListeners();
  }

  void setEndDate(DateTime value) {
    _endDate = value;
    _fieldErrorKeys.remove('endDate');
    notifyListeners();
  }

  void increaseTravelerCount() {
    if (_travelerCount >= maxTravelerCount) {
      return;
    }
    _travelerCount += 1;
    _fieldErrorKeys.remove('travelerCount');
    notifyListeners();
  }

  void decreaseTravelerCount() {
    if (_travelerCount <= minTravelerCount) {
      return;
    }
    _travelerCount -= 1;
    _fieldErrorKeys.remove('travelerCount');
    notifyListeners();
  }

  void setTravelerCountFromText(String value) {
    final parsed = int.tryParse(value.trim());
    if (parsed == null) {
      return;
    }
    _travelerCount = parsed.clamp(minTravelerCount, maxTravelerCount);
    _fieldErrorKeys.remove('travelerCount');
    notifyListeners();
  }

  void setTotalBudgetFromText(String value) {
    _totalBudget = double.tryParse(value.trim());
    _fieldErrorKeys.remove('totalBudget');
  }

  void setCurrency(String value) {
    _currency = value.trim();
    _fieldErrorKeys.remove('currency');
    notifyListeners();
  }

  void togglePreference(String value) {
    if (_preferences.contains(value)) {
      _preferences = <String>{..._preferences}..remove(value);
      _fieldErrorKeys.remove('preferences');
      notifyListeners();
      return;
    }
    if (_preferences.length >= maxPreferencesCount) {
      _fieldErrorKeys['preferences'] = 'journeyWizardErrorPreferencesMax';
      notifyListeners();
      return;
    }
    _preferences = <String>{..._preferences, value};
    _fieldErrorKeys.remove('preferences');
    notifyListeners();
  }

  void setPace(String value) {
    _pace = value;
    _fieldErrorKeys.remove('pace');
    notifyListeners();
  }

  void setAccommodationPreference(String value) {
    _accommodationPreference = _normalizeAccommodationPreference(value);
    _fieldErrorKeys.remove('accommodationPreference');
    notifyListeners();
  }

  bool nextStep() {
    if (!validateCurrentStep()) {
      notifyListeners();
      return false;
    }
    if (_currentStep < 2) {
      _currentStep += 1;
      notifyListeners();
    }
    return true;
  }

  void previousStep() {
    if (_currentStep <= 0) {
      return;
    }
    _currentStep -= 1;
    notifyListeners();
  }

  bool validateCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _validateStepOne();
      case 1:
        return _validateStepTwo();
      case 2:
        return _validateAll();
      default:
        return false;
    }
  }

  Future<bool> saveJourneyBasicInfo() async {
    if (!_validateAll()) {
      notifyListeners();
      return false;
    }

    final input = buildJourneyBasicInfoInput();
    if (input == null) {
      return false;
    }

    _isSaving = true;
    _errorKey = null;
    notifyListeners();
    try {
      await repository.saveJourneyBasicInfo(
        checklistId: checklistId,
        input: input,
      );
      _journey = _journey?.copyWith(
        departureCity: input.departureCity,
        departureCountry: input.departureCountry,
        departureLatitude: input.departureLatitude,
        departureLongitude: input.departureLongitude,
        departureSource: input.departureSource,
        startDate: input.startDate,
        endDate: input.endDate,
        tripDays: input.tripDays,
        nightCount: input.nightCount,
        travelerCount: input.travelerCount,
        totalBudget: input.totalBudget,
        currency: input.currency,
        preferences: input.preferences,
        pace: input.pace,
        accommodationPreference: input.accommodationPreference,
        basicInfoCompleted: true,
      );
      return true;
    } catch (_) {
      _errorKey = 'checklistSaveFailed';
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  JourneyBasicInfoInput? buildJourneyBasicInfoInput() {
    if (!_validateAll()) {
      return null;
    }
    final start = _startDate;
    final end = _endDate;
    final days = tripDays;
    final nights = nightCount;
    final budget = _totalBudget;
    if (start == null ||
        end == null ||
        days == null ||
        nights == null ||
        budget == null) {
      return null;
    }
    return JourneyBasicInfoInput(
      departureCity: _departureCity.trim(),
      departureCountry: _departureCountry?.trim(),
      departureLatitude: _departureLatitude,
      departureLongitude: _departureLongitude,
      departureSource: (_departureSource ?? 'manual').trim(),
      startDate: start,
      endDate: end,
      tripDays: days,
      nightCount: nights,
      travelerCount: _travelerCount,
      totalBudget: budget,
      currency: _currency.trim(),
      preferences: _preferences.toList(growable: false),
      pace: _pace.trim(),
      accommodationPreference: _normalizeAccommodationPreference(
        _accommodationPreference,
      ),
      basicInfoCompleted: true,
    );
  }

  bool _validateStepOne() {
    _fieldErrorKeys.removeWhere(
      (key, _) =>
          key == 'departureCity' ||
          key == 'startDate' ||
          key == 'endDate' ||
          key == 'travelerCount',
    );

    var valid = true;
    if (_departureCity.trim().isEmpty) {
      _fieldErrorKeys['departureCity'] =
          'journeyWizardErrorDepartureCityRequired';
      valid = false;
    }
    if (_startDate == null) {
      _fieldErrorKeys['startDate'] = 'journeyWizardErrorStartDateRequired';
      valid = false;
    }
    if (_endDate == null) {
      _fieldErrorKeys['endDate'] = 'journeyWizardErrorEndDateRequired';
      valid = false;
    }
    if (_startDate != null &&
        _endDate != null &&
        _endDate!.isBefore(_startDate!)) {
      _fieldErrorKeys['endDate'] = 'journeyWizardErrorEndDateBeforeStartDate';
      valid = false;
    }
    if (_travelerCount < minTravelerCount) {
      _fieldErrorKeys['travelerCount'] = 'journeyWizardErrorTravelerCountMin';
      valid = false;
    }
    if (_travelerCount > maxTravelerCount) {
      _fieldErrorKeys['travelerCount'] = 'journeyWizardErrorTravelerCountMax';
      valid = false;
    }
    return valid;
  }

  bool _validateStepTwo() {
    _fieldErrorKeys.removeWhere(
      (key, _) =>
          key == 'totalBudget' ||
          key == 'currency' ||
          key == 'preferences' ||
          key == 'pace' ||
          key == 'accommodationPreference',
    );

    var valid = true;
    if ((_totalBudget ?? 0) <= 0) {
      _fieldErrorKeys['totalBudget'] = 'journeyWizardErrorBudgetRequired';
      valid = false;
    }
    if (_currency.trim().isEmpty) {
      _fieldErrorKeys['currency'] = 'journeyWizardErrorCurrencyRequired';
      valid = false;
    }
    if (_preferences.isEmpty) {
      _fieldErrorKeys['preferences'] = 'journeyWizardErrorPreferencesRequired';
      valid = false;
    }
    if (_preferences.length > maxPreferencesCount) {
      _fieldErrorKeys['preferences'] = 'journeyWizardErrorPreferencesMax';
      valid = false;
    }
    if (_pace.trim().isEmpty) {
      _fieldErrorKeys['pace'] = 'journeyWizardErrorPaceRequired';
      valid = false;
    }
    if (_accommodationPreference.trim().isEmpty) {
      _fieldErrorKeys['accommodationPreference'] =
          'journeyWizardErrorAccommodationRequired';
      valid = false;
    }
    return valid;
  }

  bool _validateAll() {
    final stepOneValid = _validateStepOne();
    final stepTwoValid = _validateStepTwo();
    return stepOneValid && stepTwoValid;
  }

  void _applyJourney(ChecklistItem item) {
    _departureCity = item.departureCity?.trim() ?? '';
    _departureCountry = item.departureCountry?.trim();
    _departureLatitude = item.departureLatitude;
    _departureLongitude = item.departureLongitude;
    _departureSource = item.departureSource?.trim();
    _startDate = item.startDate;
    _endDate = item.endDate;
    _travelerCount = (item.travelerCount ?? minTravelerCount).clamp(
      minTravelerCount,
      maxTravelerCount,
    );
    _totalBudget = item.totalBudget;
    _currency = (item.currency?.trim().isNotEmpty ?? false)
        ? item.currency!.trim()
        : 'CNY';
    _preferences = item.preferences.toSet();
    _pace = (item.pace?.trim().isNotEmpty ?? false)
        ? item.pace!.trim()
        : 'balanced';
    _accommodationPreference =
        (item.accommodationPreference?.trim().isNotEmpty ?? false)
        ? _normalizeAccommodationPreference(item.accommodationPreference!)
        : 'comfortable';
    _fieldErrorKeys.clear();
  }

  String _normalizeAccommodationPreference(String value) {
    switch (value.trim().toLowerCase()) {
      case 'budget':
        return 'budget';
      case 'luxury':
      case 'premium':
        return 'luxury';
      case 'comfortable':
      case 'convenient':
      default:
        return 'comfortable';
    }
  }
}
