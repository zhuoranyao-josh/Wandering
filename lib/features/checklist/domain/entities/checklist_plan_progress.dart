enum ChecklistPlanProgressStep {
  preparingTripInformation,
  analyzingBudget,
  generatingAiTravelPlan,
  findingFlightSuggestions,
  findingHotels,
  findingRestaurants,
  findingActivities,
  savingChecklist,
  preparingCards,
  finalizingPlan,
  completed,
  failed,
}

class ChecklistPlanProgress {
  const ChecklistPlanProgress({
    required this.step,
    required this.progressPercent,
    this.messageCode,
    this.currentItemIndex,
    this.totalItemCount,
    this.hasPartialFailures = false,
    this.errorCode,
    this.errorDetail,
  });

  final ChecklistPlanProgressStep step;
  final double progressPercent;
  final String? messageCode;
  final int? currentItemIndex;
  final int? totalItemCount;
  final bool hasPartialFailures;
  final String? errorCode;
  final String? errorDetail;
}

typedef ChecklistPlanProgressCallback =
    void Function(ChecklistPlanProgress progress);

typedef ChecklistPlanCancelChecker = bool Function();
