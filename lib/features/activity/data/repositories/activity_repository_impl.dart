import '../../domain/entities/activity_event.dart';
import '../../domain/repositories/activity_repository.dart';
import '../datasources/activity_remote_data_source.dart';

class ActivityRepositoryImpl implements ActivityRepository {
  final ActivityRemoteDataSource remoteDataSource;

  ActivityRepositoryImpl(this.remoteDataSource);

  @override
  Stream<List<ActivityEvent>> watchPublishedEvents() {
    return remoteDataSource.watchPublishedEvents();
  }

  @override
  Future<ActivityEvent?> getEventById(String id) {
    return remoteDataSource.getEventById(id);
  }
}
