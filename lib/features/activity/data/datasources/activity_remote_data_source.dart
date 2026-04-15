import '../../domain/entities/activity_event.dart';

abstract class ActivityRemoteDataSource {
  Stream<List<ActivityEvent>> watchPublishedEvents();

  Future<ActivityEvent?> getEventById(String id);
}
