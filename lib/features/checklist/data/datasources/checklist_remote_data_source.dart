import '../../domain/entities/checklist_item.dart';

abstract class ChecklistRemoteDataSource {
  Future<List<ChecklistItem>> getMyChecklists();

  Future<String> createChecklistFromPlace({
    required String placeId,
    required String destination,
    String? coverImageUrl,
  });

  Future<void> deleteChecklist(String checklistId);
}
