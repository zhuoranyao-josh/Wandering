import '../../domain/entities/checklist_detail.dart';
import '../../domain/entities/checklist_destination_snapshot.dart';
import '../../domain/entities/checklist_item.dart';
import '../../domain/entities/journey_basic_info_input.dart';
import '../../domain/repositories/checklist_repository.dart';
import '../datasources/checklist_remote_data_source.dart';

class ChecklistRepositoryImpl implements ChecklistRepository {
  ChecklistRepositoryImpl(this.remoteDataSource);

  final ChecklistRemoteDataSource remoteDataSource;

  @override
  Future<List<ChecklistItem>> getMyChecklists() {
    return remoteDataSource.getMyChecklists();
  }

  @override
  Future<ChecklistItem?> getChecklistById(String checklistId) {
    return remoteDataSource.getChecklistById(checklistId);
  }

  @override
  Future<ChecklistDetail?> getChecklistDetail(String checklistId) {
    return remoteDataSource.getChecklistDetail(checklistId);
  }

  @override
  Future<String> createChecklistFromPlace({
    required String placeId,
    required String destination,
    String? coverImageUrl,
    Map<String, String>? destinationNames,
    ChecklistDestinationSnapshot? destinationSnapshot,
  }) {
    return remoteDataSource.createChecklistFromPlace(
      placeId: placeId,
      destination: destination,
      coverImageUrl: coverImageUrl,
      destinationNames: destinationNames,
      destinationSnapshot: destinationSnapshot,
    );
  }

  @override
  Future<String> createChecklistFromDestinationSnapshot({
    required ChecklistDestinationSnapshot destinationSnapshot,
    Map<String, String>? destinationNames,
  }) {
    return remoteDataSource.createChecklistFromDestinationSnapshot(
      destinationSnapshot: destinationSnapshot,
      destinationNames: destinationNames,
    );
  }

  @override
  Future<void> saveJourneyBasicInfo({
    required String checklistId,
    required JourneyBasicInfoInput input,
  }) {
    return remoteDataSource.saveJourneyBasicInfo(
      checklistId: checklistId,
      input: input,
    );
  }

  @override
  Future<void> generateChecklistPlan(String checklistId) {
    return remoteDataSource.generateChecklistPlan(checklistId);
  }

  @override
  Future<void> updateBudget({
    required String checklistId,
    double? totalBudget,
    String? currencySymbol,
  }) {
    return remoteDataSource.updateBudget(
      checklistId: checklistId,
      totalBudget: totalBudget,
      currencySymbol: currencySymbol,
    );
  }

  @override
  Future<void> updateBudgetSplit({
    required String checklistId,
    double? transportRatio,
    double? stayRatio,
    double? foodActivityRatio,
  }) {
    return remoteDataSource.updateBudgetSplit(
      checklistId: checklistId,
      transportRatio: transportRatio,
      stayRatio: stayRatio,
      foodActivityRatio: foodActivityRatio,
    );
  }

  @override
  Future<void> toggleItemCompleted({
    required String checklistId,
    required String itemId,
  }) {
    return remoteDataSource.toggleItemCompleted(
      checklistId: checklistId,
      itemId: itemId,
    );
  }

  @override
  Future<void> updatePlan(String checklistId) {
    return remoteDataSource.updatePlan(checklistId);
  }

  @override
  Future<void> deleteChecklist(String checklistId) {
    return remoteDataSource.deleteChecklist(checklistId);
  }
}
