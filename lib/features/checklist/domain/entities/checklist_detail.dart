class ChecklistDetail {
  const ChecklistDetail({
    required this.id,
    required this.destination,
    this.departureCity,
    this.startDate,
    this.endDate,
    this.tripDays,
    this.durationText,
    this.travelerCount,
    this.totalBudget,
    this.currency,
    this.currencySymbol,
    this.preferences = const <String>[],
    this.pace,
    this.accommodationPreference,
    this.basicInfoCompleted = false,
    this.planningStatus,
    this.budgetSplit,
    this.essentials = const <ChecklistEssential>[],
    this.proTip,
    this.items = const <ChecklistDetailItem>[],
  });

  final String id;
  final String destination;
  final String? departureCity;
  final DateTime? startDate;
  final DateTime? endDate;
  final int? tripDays;
  final String? durationText;
  final int? travelerCount;
  final double? totalBudget;
  final String? currency;
  final String? currencySymbol;
  final List<String> preferences;
  final String? pace;
  final String? accommodationPreference;
  final bool basicInfoCompleted;
  final String? planningStatus;
  final ChecklistBudgetSplit? budgetSplit;
  final List<ChecklistEssential> essentials;
  final ChecklistProTip? proTip;
  final List<ChecklistDetailItem> items;

  // 是否满足“开始规划/生成计划”的基础信息完整性要求。
  bool get isBasicInfoComplete {
    return startDate != null &&
        endDate != null &&
        (departureCity?.trim().isNotEmpty ?? false) &&
        (totalBudget ?? 0) > 0 &&
        (currency?.trim().isNotEmpty ?? false) &&
        (travelerCount ?? 0) > 0 &&
        (pace?.trim().isNotEmpty ?? false) &&
        (accommodationPreference?.trim().isNotEmpty ?? false) &&
        preferences.isNotEmpty;
  }

  ChecklistDetail copyWith({
    String? id,
    String? destination,
    String? departureCity,
    DateTime? startDate,
    DateTime? endDate,
    int? tripDays,
    String? durationText,
    int? travelerCount,
    double? totalBudget,
    String? currency,
    String? currencySymbol,
    List<String>? preferences,
    String? pace,
    String? accommodationPreference,
    bool? basicInfoCompleted,
    String? planningStatus,
    ChecklistBudgetSplit? budgetSplit,
    List<ChecklistEssential>? essentials,
    ChecklistProTip? proTip,
    List<ChecklistDetailItem>? items,
  }) {
    return ChecklistDetail(
      id: id ?? this.id,
      destination: destination ?? this.destination,
      departureCity: departureCity ?? this.departureCity,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      tripDays: tripDays ?? this.tripDays,
      durationText: durationText ?? this.durationText,
      travelerCount: travelerCount ?? this.travelerCount,
      totalBudget: totalBudget ?? this.totalBudget,
      currency: currency ?? this.currency,
      currencySymbol: currencySymbol ?? this.currencySymbol,
      preferences: preferences ?? this.preferences,
      pace: pace ?? this.pace,
      accommodationPreference:
          accommodationPreference ?? this.accommodationPreference,
      basicInfoCompleted: basicInfoCompleted ?? this.basicInfoCompleted,
      planningStatus: planningStatus ?? this.planningStatus,
      budgetSplit: budgetSplit ?? this.budgetSplit,
      essentials: essentials ?? this.essentials,
      proTip: proTip ?? this.proTip,
      items: items ?? this.items,
    );
  }
}

class ChecklistBudgetSplit {
  const ChecklistBudgetSplit({
    this.transportRatio,
    this.stayRatio,
    this.foodActivityRatio,
  });

  final double? transportRatio;
  final double? stayRatio;
  final double? foodActivityRatio;

  bool get hasAnyValue =>
      transportRatio != null || stayRatio != null || foodActivityRatio != null;
}

class ChecklistEssential {
  const ChecklistEssential({
    required this.iconType,
    required this.title,
    required this.mainText,
    this.subText,
  });

  final String iconType;
  final String title;
  final String mainText;
  final String? subText;
}

class ChecklistProTip {
  const ChecklistProTip({this.tipTitle, this.tipDescription});

  final String? tipTitle;
  final String? tipDescription;

  bool get isEmpty {
    final title = tipTitle?.trim() ?? '';
    final description = tipDescription?.trim() ?? '';
    return title.isEmpty && description.isEmpty;
  }
}

class ChecklistDetailItem {
  const ChecklistDetailItem({
    required this.id,
    required this.groupType,
    required this.title,
    this.subtitle,
    required this.isCompleted,
    this.detailRouteTarget,
  });

  final String id;
  final String groupType;
  final String title;
  final String? subtitle;
  final bool isCompleted;
  final String? detailRouteTarget;

  ChecklistDetailItem copyWith({
    String? id,
    String? groupType,
    String? title,
    String? subtitle,
    bool? isCompleted,
    String? detailRouteTarget,
  }) {
    return ChecklistDetailItem(
      id: id ?? this.id,
      groupType: groupType ?? this.groupType,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      isCompleted: isCompleted ?? this.isCompleted,
      detailRouteTarget: detailRouteTarget ?? this.detailRouteTarget,
    );
  }
}
