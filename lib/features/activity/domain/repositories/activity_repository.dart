import '../entities/activity_event.dart';

abstract class ActivityRepository {
  Stream<List<ActivityEvent>> watchPublishedEvents();

  Future<ActivityEvent?> getEventById(String id);
}
