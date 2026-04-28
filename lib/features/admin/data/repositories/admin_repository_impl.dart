import '../../domain/entities/admin_activity.dart';
import '../../domain/entities/admin_place.dart';
import '../../domain/entities/admin_region.dart';
import '../../domain/entities/admin_subcontent_item.dart';
import '../../domain/entities/admin_subcontent_kind.dart';
import '../../domain/repositories/admin_repository.dart';
import '../datasources/admin_remote_data_source.dart';

class AdminRepositoryImpl implements AdminRepository {
  AdminRepositoryImpl(this.remoteDataSource);

  final AdminRemoteDataSource remoteDataSource;

  @override
  Future<String> uploadPlaceCoverImage({
    required String localPath,
    String? placeIdHint,
  }) {
    return remoteDataSource.uploadPlaceCoverImage(
      localPath: localPath,
      placeIdHint: placeIdHint,
    );
  }

  @override
  Future<String> uploadActivityCoverImage({
    required String localPath,
    String? activityIdHint,
  }) {
    return remoteDataSource.uploadActivityCoverImage(
      localPath: localPath,
      activityIdHint: activityIdHint,
    );
  }

  @override
  Future<String> uploadPlaceSubcontentImage({
    required String localPath,
    required String placeId,
    required AdminSubcontentKind kind,
  }) {
    return remoteDataSource.uploadPlaceSubcontentImage(
      localPath: localPath,
      placeId: placeId,
      kind: kind,
    );
  }

  @override
  Future<List<AdminPlace>> getPlaces() {
    return remoteDataSource.getPlaces();
  }

  @override
  Future<AdminPlace?> getPlaceById(String placeId) {
    return remoteDataSource.getPlaceById(placeId);
  }

  @override
  Future<String> upsertPlace(AdminPlace place) {
    return remoteDataSource.upsertPlace(place);
  }

  @override
  Future<void> deletePlace(String placeId) {
    return remoteDataSource.deletePlace(placeId);
  }

  @override
  Future<void> setPlaceEnabled({
    required String placeId,
    required bool enabled,
  }) {
    return remoteDataSource.setPlaceEnabled(placeId: placeId, enabled: enabled);
  }

  @override
  Future<List<AdminRegion>> getRegions() {
    return remoteDataSource.getRegions();
  }

  @override
  Future<AdminRegion?> getRegionById(String regionId) {
    return remoteDataSource.getRegionById(regionId);
  }

  @override
  Future<String> upsertRegion(AdminRegion region) {
    return remoteDataSource.upsertRegion(region);
  }

  @override
  Future<void> deleteRegion(String regionId) {
    return remoteDataSource.deleteRegion(regionId);
  }

  @override
  Future<void> setRegionEnabled({
    required String regionId,
    required bool enabled,
  }) {
    return remoteDataSource.setRegionEnabled(
      regionId: regionId,
      enabled: enabled,
    );
  }

  @override
  Future<bool> regionExists(String regionId) {
    return remoteDataSource.regionExists(regionId);
  }

  @override
  Future<List<AdminSubcontentItem>> getPlaceSubcontent({
    required String placeId,
    required AdminSubcontentKind kind,
  }) {
    return remoteDataSource.getPlaceSubcontent(placeId: placeId, kind: kind);
  }

  @override
  Future<String> upsertPlaceSubcontent({
    required String placeId,
    required AdminSubcontentKind kind,
    required AdminSubcontentItem item,
  }) {
    return remoteDataSource.upsertPlaceSubcontent(
      placeId: placeId,
      kind: kind,
      item: item,
    );
  }

  @override
  Future<void> deletePlaceSubcontent({
    required String placeId,
    required AdminSubcontentKind kind,
    required String itemId,
  }) {
    return remoteDataSource.deletePlaceSubcontent(
      placeId: placeId,
      kind: kind,
      itemId: itemId,
    );
  }

  @override
  Future<void> setPlaceSubcontentEnabled({
    required String placeId,
    required AdminSubcontentKind kind,
    required String itemId,
    required bool enabled,
  }) {
    return remoteDataSource.setPlaceSubcontentEnabled(
      placeId: placeId,
      kind: kind,
      itemId: itemId,
      enabled: enabled,
    );
  }

  @override
  Future<List<AdminActivity>> getActivities() {
    return remoteDataSource.getActivities();
  }

  @override
  Future<AdminActivity?> getActivityById(String activityId) {
    return remoteDataSource.getActivityById(activityId);
  }

  @override
  Future<String> upsertActivity(AdminActivity activity) {
    return remoteDataSource.upsertActivity(activity);
  }

  @override
  Future<void> deleteActivity(String activityId) {
    return remoteDataSource.deleteActivity(activityId);
  }

  @override
  Future<void> setActivityPublished({
    required String activityId,
    required bool isPublished,
  }) {
    return remoteDataSource.setActivityPublished(
      activityId: activityId,
      isPublished: isPublished,
    );
  }
}
