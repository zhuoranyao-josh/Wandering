import '../../domain/entities/admin_activity.dart';
import '../../domain/entities/admin_place.dart';
import '../../domain/entities/admin_region.dart';
import '../../domain/entities/admin_subcontent_item.dart';
import '../../domain/entities/admin_subcontent_kind.dart';

abstract class AdminRemoteDataSource {
  Future<String> uploadPlaceCoverImage({
    required String localPath,
    String? placeIdHint,
  });

  Future<String> uploadActivityCoverImage({
    required String localPath,
    String? activityIdHint,
  });

  Future<String> uploadPlaceSubcontentImage({
    required String localPath,
    required String placeId,
    required AdminSubcontentKind kind,
  });

  Future<List<AdminPlace>> getPlaces();

  Future<AdminPlace?> getPlaceById(String placeId);

  Future<String> upsertPlace(AdminPlace place);

  Future<void> deletePlace(String placeId);

  Future<void> setPlaceEnabled({
    required String placeId,
    required bool enabled,
  });

  Future<List<AdminRegion>> getRegions();

  Future<AdminRegion?> getRegionById(String regionId);

  Future<String> upsertRegion(AdminRegion region);

  Future<void> deleteRegion(String regionId);

  Future<void> setRegionEnabled({
    required String regionId,
    required bool enabled,
  });

  Future<bool> regionExists(String regionId);

  Future<List<AdminSubcontentItem>> getPlaceSubcontent({
    required String placeId,
    required AdminSubcontentKind kind,
  });

  Future<String> upsertPlaceSubcontent({
    required String placeId,
    required AdminSubcontentKind kind,
    required AdminSubcontentItem item,
  });

  Future<void> deletePlaceSubcontent({
    required String placeId,
    required AdminSubcontentKind kind,
    required String itemId,
  });

  Future<void> setPlaceSubcontentEnabled({
    required String placeId,
    required AdminSubcontentKind kind,
    required String itemId,
    required bool enabled,
  });

  Future<List<AdminActivity>> getActivities();

  Future<AdminActivity?> getActivityById(String activityId);

  Future<String> upsertActivity(AdminActivity activity);

  Future<void> deleteActivity(String activityId);

  Future<void> setActivityPublished({
    required String activityId,
    required bool isPublished,
  });
}
