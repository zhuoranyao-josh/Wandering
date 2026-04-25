import '../../domain/entities/checklist_detail.dart';
import '../../domain/entities/checklist_item.dart';
import '../../domain/entities/journey_basic_info_input.dart';

abstract class ChecklistRemoteDataSource {
  Future<List<ChecklistItem>> getMyChecklists();

  Future<ChecklistItem?> getChecklistById(String checklistId);

  Future<ChecklistDetail?> getChecklistDetail(String checklistId);

  Future<String> createChecklistFromPlace({
    required String placeId,
    required String destination,
    String? coverImageUrl,
  });

  Future<void> saveJourneyBasicInfo({
    required String checklistId,
    required JourneyBasicInfoInput input,
  });

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
