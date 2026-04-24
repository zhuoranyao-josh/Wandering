import '../../domain/entities/checklist_item.dart';
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
  Future<String> createChecklistFromPlace({
    required String placeId,
    required String destination,
    String? coverImageUrl,
  }) {
    return remoteDataSource.createChecklistFromPlace(
      placeId: placeId,
      destination: destination,
      coverImageUrl: coverImageUrl,
    );
  }

  @override
  Future<void> deleteChecklist(String checklistId) {
    return remoteDataSource.deleteChecklist(checklistId);
  }
}
