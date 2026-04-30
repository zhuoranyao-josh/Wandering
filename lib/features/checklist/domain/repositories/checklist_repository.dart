import '../entities/checklist_detail.dart';
import '../entities/checklist_destination_snapshot.dart';
import '../entities/checklist_item.dart';
import '../entities/journey_basic_info_input.dart';

abstract class ChecklistRepository {
  Future<List<ChecklistItem>> getMyChecklists();

  Future<ChecklistItem?> getChecklistById(String checklistId);

  Future<ChecklistDetail?> getChecklistDetail(String checklistId);

  Future<String> createChecklistFromPlace({
    required String placeId,
    required String destination,
    String? coverImageUrl,
    Map<String, String>? destinationNames,
    ChecklistDestinationSnapshot? destinationSnapshot,
  });

  Future<String> createChecklistFromDestinationSnapshot({
    required ChecklistDestinationSnapshot destinationSnapshot,
    Map<String, String>? destinationNames,
  });

  Future<void> saveJourneyBasicInfo({
    required String checklistId,
    required JourneyBasicInfoInput input,
  });

  Future<void> generateChecklistPlan(String checklistId);

  Future<void> updateBudget({
    required String checklistId,
    double? totalBudget,
    String? currencySymbol,
  });

  Future<void> updateBudgetSplit({
    required String checklistId,
    double? transportRatio,
    double? stayRatio,
    double? foodActivityRatio,
  });

  Future<void> toggleItemCompleted({
    required String checklistId,
    required String itemId,
  });

  Future<void> updatePlan(String checklistId);

  Future<void> deleteChecklist(String checklistId);
}
