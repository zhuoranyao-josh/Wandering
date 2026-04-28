import 'dart:io';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../../../core/error/app_exception.dart';
import '../../domain/entities/admin_activity.dart';
import '../../domain/entities/admin_place.dart';
import '../../domain/entities/admin_region.dart';
import '../../domain/entities/admin_subcontent_item.dart';
import '../../domain/entities/admin_subcontent_kind.dart';
import 'admin_remote_data_source.dart';

class FirebaseAdminRemoteDataSource implements AdminRemoteDataSource {
  FirebaseAdminRemoteDataSource({
    required this.firestore,
    required this.storage,
  });

  final FirebaseFirestore firestore;
  final FirebaseStorage storage;
  final Random _random = Random();
  static const String _base36Alphabet = 'abcdefghijklmnopqrstuvwxyz0123456789';

  @override
  Future<String> uploadPlaceCoverImage({
    required String localPath,
    String? placeIdHint,
  }) {
    // 管理端上传封面图后回填 URL，仍复用原有 coverImage 字段。
    final placeId = _sanitizeStorageSegment(
      placeIdHint,
      fallback: 'draft_place',
    );
    return _uploadImage(
      localPath: localPath,
      folderPath: 'admin/places/$placeId/cover',
    );
  }

  @override
  Future<String> uploadActivityCoverImage({
    required String localPath,
    String? activityIdHint,
  }) {
    final activityId = _sanitizeStorageSegment(
      activityIdHint,
      fallback: 'draft_activity',
    );
    return _uploadImage(
      localPath: localPath,
      folderPath: 'admin/activities/$activityId/cover',
    );
  }

  @override
  Future<String> uploadPlaceSubcontentImage({
    required String localPath,
    required String placeId,
    required AdminSubcontentKind kind,
  }) {
    final normalizedPlaceId = _sanitizeStorageSegment(
      placeId,
      fallback: 'draft_place',
    );
    return _uploadImage(
      localPath: localPath,
      folderPath: 'admin/places/$normalizedPlaceId/${kind.collectionName}',
    );
  }

  @override
  Future<List<AdminPlace>> getPlaces() async {
    final snapshot = await firestore.collection('places').get();
    final places = await Future.wait(
      snapshot.docs.map((doc) async {
        final markerDoc = await _findMarkerDocByPlaceId(doc.id);
        return _mapPlace(
          placeId: doc.id,
          data: doc.data(),
          markerDoc: markerDoc,
        );
      }),
    );
    places.sort((a, b) => a.id.compareTo(b.id));
    return places;
  }

  @override
  Future<AdminPlace?> getPlaceById(String placeId) async {
    final doc = await firestore.collection('places').doc(placeId).get();
    if (!doc.exists) {
      return null;
    }
    final markerDoc = await _findMarkerDocByPlaceId(placeId);
    return _mapPlace(
      placeId: doc.id,
      data: doc.data() ?? <String, dynamic>{},
      markerDoc: markerDoc,
    );
  }

  @override
  Future<String> upsertPlace(AdminPlace place) async {
    final placeCollection = firestore.collection('places');
    final placeId = place.id.trim().isEmpty
        ? placeCollection.doc().id
        : place.id;
    final regionId = place.regionId.trim();
    if (regionId.isEmpty) {
      throw AppException('adminPlaceRegionRequired');
    }
    if (!await _regionExistsInternal(regionId)) {
      throw AppException('adminPlaceRegionInvalid');
    }
    final placeRef = placeCollection.doc(placeId);

    // 统一维护 place 文档，marker/preview/details 共享同一数据源。
    final placeData = <String, dynamic>{
      'id': placeId,
      'name': _sanitizeLanguageMap(place.name),
      'regionId': regionId,
      'latitude': place.latitude,
      'longitude': place.longitude,
      'coverImage': place.coverImage.trim(),
      'quote': _sanitizeLanguageMap(place.quote),
      'shortDescription': _sanitizeLanguageMap(place.shortDescription),
      'longDescription': _sanitizeLanguageMap(place.longDescription),
      'tags': place.tags
          .map((tag) => tag.trim())
          .where((tag) => tag.isNotEmpty)
          .toList(),
      'flyToZoom': place.flyToZoom,
      'flyToPitch': place.flyToPitch,
      'flyToBearing': place.flyToBearing,
      'enabled': place.enabled,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    final markerId = await _resolveMarkerDocId(
      placeId: placeId,
      preferredMarkerId: place.markerId,
    );
    final markerRef = firestore.collection('markers').doc(markerId);
    final markerData = <String, dynamic>{
      'id': markerId,
      'placeId': placeId,
      'type': place.markerType.trim().isEmpty
          ? 'official'
          : place.markerType.trim(),
      'latitude': place.markerLatitude,
      'longitude': place.markerLongitude,
      'enabled': place.enabled,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    final batch = firestore.batch();
    batch.set(placeRef, placeData, SetOptions(merge: true));
    batch.set(markerRef, markerData, SetOptions(merge: true));
    await batch.commit();
    return placeId;
  }

  @override
  Future<void> deletePlace(String placeId) async {
    final batch = firestore.batch();
    final placeRef = firestore.collection('places').doc(placeId);
    batch.delete(placeRef);

    final markerSnapshot = await firestore
        .collection('markers')
        .where('placeId', isEqualTo: placeId)
        .get();
    for (final markerDoc in markerSnapshot.docs) {
      batch.delete(markerDoc.reference);
    }

    for (final kind in AdminSubcontentKind.values) {
      final subSnapshot = await placeRef.collection(kind.collectionName).get();
      for (final doc in subSnapshot.docs) {
        batch.delete(doc.reference);
      }
    }

    await batch.commit();
  }

  @override
  Future<void> setPlaceEnabled({
    required String placeId,
    required bool enabled,
  }) async {
    final placeRef = firestore.collection('places').doc(placeId);
    await placeRef.set({
      'enabled': enabled,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    final markerSnapshot = await firestore
        .collection('markers')
        .where('placeId', isEqualTo: placeId)
        .get();
    for (final markerDoc in markerSnapshot.docs) {
      await markerDoc.reference.set({
        'enabled': enabled,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  @override
  Future<List<AdminRegion>> getRegions() async {
    final snapshot = await firestore.collection('regions').get();
    final regions = snapshot.docs
        .map((doc) => _mapRegion(doc.id, doc.data()))
        .toList(growable: false);
    regions.sort((a, b) => a.id.compareTo(b.id));
    return regions;
  }

  @override
  Future<AdminRegion?> getRegionById(String regionId) async {
    final doc = await firestore.collection('regions').doc(regionId.trim()).get();
    if (!doc.exists) {
      return null;
    }
    return _mapRegion(doc.id, doc.data() ?? <String, dynamic>{});
  }

  @override
  Future<String> upsertRegion(AdminRegion region) async {
    final collection = firestore.collection('regions');
    final id = region.id.trim().isEmpty ? collection.doc().id : region.id.trim();
    final isNew = region.id.trim().isEmpty;
    final payload = <String, dynamic>{
      'id': id,
      'focusZoom': region.focusZoom,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (isNew) {
      payload['createdAt'] = FieldValue.serverTimestamp();
    }
    if (region.hasName) {
      payload['name'] = _sanitizeLanguageMap(region.name);
    }
    if (region.enabled != null) {
      payload['enabled'] = region.enabled;
    }

    await collection.doc(id).set(payload, SetOptions(merge: true));
    return id;
  }

  @override
  Future<void> deleteRegion(String regionId) async {
    final trimmedId = regionId.trim();
    final inUseSnapshot = await firestore
        .collection('places')
        .where('regionId', isEqualTo: trimmedId)
        .limit(1)
        .get();
    if (inUseSnapshot.docs.isNotEmpty) {
      throw AppException('adminRegionInUse');
    }
    await firestore.collection('regions').doc(trimmedId).delete();
  }

  @override
  Future<void> setRegionEnabled({
    required String regionId,
    required bool enabled,
  }) async {
    await firestore.collection('regions').doc(regionId.trim()).set({
      'enabled': enabled,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  Future<bool> regionExists(String regionId) {
    return _regionExistsInternal(regionId);
  }

  @override
  Future<List<AdminSubcontentItem>> getPlaceSubcontent({
    required String placeId,
    required AdminSubcontentKind kind,
  }) async {
    final snapshot = await firestore
        .collection('places')
        .doc(placeId)
        .collection(kind.collectionName)
        .get();

    final items = snapshot.docs
        .map((doc) => _mapSubcontentItem(doc.id, doc.data()))
        .toList(growable: false);
    items.sort((a, b) {
      final orderResult = a.order.compareTo(b.order);
      if (orderResult != 0) {
        return orderResult;
      }
      return a.id.compareTo(b.id);
    });
    return items;
  }

  @override
  Future<String> upsertPlaceSubcontent({
    required String placeId,
    required AdminSubcontentKind kind,
    required AdminSubcontentItem item,
  }) async {
    final collection = firestore
        .collection('places')
        .doc(placeId)
        .collection(kind.collectionName);
    final itemId = item.id.trim().isEmpty
        ? collection.doc().id
        : item.id.trim();
    final isNew = item.id.trim().isEmpty;
    final ref = collection.doc(itemId);

    final payload = <String, dynamic>{
      'enabled': item.enabled,
      'order': item.order,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (isNew) {
      payload['createdAt'] = FieldValue.serverTimestamp();
    }

    switch (kind) {
      case AdminSubcontentKind.experiences:
        payload['title'] = _sanitizeLanguageMap(item.title);
        payload['badge'] = _sanitizeLanguageMap(item.badge);
        break;
      case AdminSubcontentKind.flavors:
        payload['name'] = _sanitizeLanguageMap(item.name);
        payload['subtitle'] = _sanitizeLanguageMap(item.subtitle);
        payload['imageUrl'] = item.imageUrl.trim();
        break;
      case AdminSubcontentKind.stays:
        payload['name'] = _sanitizeLanguageMap(item.name);
        payload['badge'] = _sanitizeLanguageMap(item.badge);
        payload['imageUrl'] = item.imageUrl.trim();
        payload['priceRange'] = item.priceRange.trim();
        break;
      case AdminSubcontentKind.gallery:
        payload['imageUrl'] = item.imageUrl.trim();
        payload['caption'] = _sanitizeLanguageMap(item.caption);
        break;
    }

    await ref.set(payload, SetOptions(merge: true));
    return itemId;
  }

  @override
  Future<void> deletePlaceSubcontent({
    required String placeId,
    required AdminSubcontentKind kind,
    required String itemId,
  }) async {
    await firestore
        .collection('places')
        .doc(placeId)
        .collection(kind.collectionName)
        .doc(itemId)
        .delete();
  }

  @override
  Future<void> setPlaceSubcontentEnabled({
    required String placeId,
    required AdminSubcontentKind kind,
    required String itemId,
    required bool enabled,
  }) async {
    await firestore
        .collection('places')
        .doc(placeId)
        .collection(kind.collectionName)
        .doc(itemId)
        .set({
          'enabled': enabled,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
  }

  @override
  Future<List<AdminActivity>> getActivities() async {
    final snapshot = await firestore.collection('events').get();
    final activities = snapshot.docs
        .map((doc) => _mapActivity(doc.id, doc.data()))
        .toList(growable: false);
    activities.sort((a, b) => a.id.compareTo(b.id));
    return activities;
  }

  @override
  Future<AdminActivity?> getActivityById(String activityId) async {
    final doc = await firestore.collection('events').doc(activityId).get();
    if (!doc.exists) {
      return null;
    }
    return _mapActivity(doc.id, doc.data() ?? <String, dynamic>{});
  }

  @override
  Future<String> upsertActivity(AdminActivity activity) async {
    final collection = firestore.collection('events');
    final id = await _resolveActivityDocId(collection: collection, activity: activity);
    final ref = collection.doc(id);
    final normalizedCategories = _normalizeActivityCategories(
      activity.categories,
    );

    final payload = <String, dynamic>{
      'id': id,
      'title': _sanitizeLanguageMap(activity.title),
      'categories': normalizedCategories,
      'category': normalizedCategories.isEmpty ? '' : normalizedCategories.first,
      'cityName': _sanitizeLanguageMap(activity.cityName),
      'countryName': _sanitizeLanguageMap(activity.countryName),
      'cityCode': activity.cityCode.trim(),
      'coverImageUrl': activity.coverImageUrl.trim(),
      'startAt': activity.startAt,
      'endAt': activity.endAt,
      'isPublished': activity.isPublished,
      'isFeatured': activity.isFeatured,
      'detailText': _sanitizeLanguageMap(activity.detailText),
      'placeId': activity.placeId?.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (activity.id.trim().isEmpty || activity.id.trim() != id) {
      payload['createdAt'] = FieldValue.serverTimestamp();
    }

    await ref.set(payload, SetOptions(merge: true));
    return id;
  }

  @override
  Future<void> deleteActivity(String activityId) async {
    await firestore.collection('events').doc(activityId).delete();
  }

  @override
  Future<void> setActivityPublished({
    required String activityId,
    required bool isPublished,
  }) async {
    await firestore.collection('events').doc(activityId).set({
      'isPublished': isPublished,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  AdminPlace _mapPlace({
    required String placeId,
    required Map<String, dynamic> data,
    required QueryDocumentSnapshot<Map<String, dynamic>>? markerDoc,
  }) {
    final markerData = markerDoc?.data() ?? <String, dynamic>{};
    return AdminPlace(
      id: (data['id'] as String?)?.trim().isNotEmpty == true
          ? (data['id'] as String).trim()
          : placeId,
      name: _readLanguageMap(data['name']),
      regionId: (data['regionId'] as String?)?.trim() ?? '',
      latitude: _toDouble(data['latitude']) ?? 0.0,
      longitude: _toDouble(data['longitude']) ?? 0.0,
      coverImage:
          (data['coverImage'] as String?)?.trim() ??
          (data['previewAssetPath'] as String?)?.trim() ??
          '',
      quote: _readLanguageMap(data['quote']),
      shortDescription: _readLanguageMap(data['shortDescription']),
      longDescription: _readLanguageMap(data['longDescription']),
      tags: _readStringList(data['tags']),
      flyToZoom: _toDouble(data['flyToZoom']) ?? 10.8,
      flyToPitch: _toDouble(data['flyToPitch']) ?? 48.0,
      flyToBearing: _toDouble(data['flyToBearing']) ?? 12.0,
      enabled: (data['enabled'] as bool?) ?? true,
      markerId: markerDoc?.id,
      markerType: (markerData['type'] as String?)?.trim() ?? 'official',
      markerLatitude: _toDouble(markerData['latitude']),
      markerLongitude: _toDouble(markerData['longitude']),
    );
  }

  AdminRegion _mapRegion(String docId, Map<String, dynamic> data) {
    final rawEnabled = data['enabled'];
    return AdminRegion(
      id: (data['id'] as String?)?.trim().isNotEmpty == true
          ? (data['id'] as String).trim()
          : docId,
      focusZoom: _toDouble(data['focusZoom']) ?? 4.8,
      name: _readLanguageMap(data['name']),
      enabled: rawEnabled is bool ? rawEnabled : null,
    );
  }

  AdminSubcontentItem _mapSubcontentItem(String id, Map<String, dynamic> data) {
    return AdminSubcontentItem(
      id: id,
      enabled: (data['enabled'] as bool?) ?? true,
      order: _toInt(data['order']) ?? 0,
      title: _readLanguageMap(data['title']),
      badge: _readLanguageMap(data['badge']),
      name: _readLanguageMap(data['name']),
      subtitle: _readLanguageMap(data['subtitle']),
      caption: _readLanguageMap(data['caption']),
      imageUrl: (data['imageUrl'] as String?)?.trim() ?? '',
      priceRange: (data['priceRange'] as String?)?.trim() ?? '',
    );
  }

  AdminActivity _mapActivity(String id, Map<String, dynamic> data) {
    return AdminActivity(
      id: id,
      title: _readLanguageMapWithStringFallback(data['title']),
      categories: _readActivityCategories(data),
      cityName: _readLanguageMapWithStringFallback(data['cityName']),
      countryName: _readLanguageMapWithStringFallback(data['countryName']),
      cityCode: (data['cityCode'] as String?)?.trim() ?? '',
      coverImageUrl: (data['coverImageUrl'] as String?)?.trim() ?? '',
      startAt: _readDateTime(data['startAt']),
      endAt: _readDateTime(data['endAt']),
      isPublished: (data['isPublished'] as bool?) ?? false,
      isFeatured: (data['isFeatured'] as bool?) ?? false,
      detailText: _readLanguageMapWithStringFallback(data['detailText']),
      placeId: (data['placeId'] as String?)?.trim(),
    );
  }

  Future<QueryDocumentSnapshot<Map<String, dynamic>>?> _findMarkerDocByPlaceId(
    String placeId,
  ) async {
    final markerSnapshot = await firestore
        .collection('markers')
        .where('placeId', isEqualTo: placeId)
        .limit(1)
        .get();
    if (markerSnapshot.docs.isEmpty) {
      return null;
    }
    return markerSnapshot.docs.first;
  }

  Future<String> _resolveMarkerDocId({
    required String placeId,
    required String? preferredMarkerId,
  }) async {
    final trimmed = preferredMarkerId?.trim() ?? '';
    if (trimmed.isNotEmpty) {
      return trimmed;
    }
    final markerDoc = await _findMarkerDocByPlaceId(placeId);
    if (markerDoc != null) {
      return markerDoc.id;
    }
    return placeId;
  }

  Future<String> _uploadImage({
    required String localPath,
    required String folderPath,
  }) async {
    final trimmedPath = localPath.trim();
    if (trimmedPath.isEmpty) {
      throw Exception('empty_image_path');
    }

    final file = File(trimmedPath);
    if (!await file.exists()) {
      throw Exception('image_file_not_found');
    }

    final fileName =
        'image_${DateTime.now().microsecondsSinceEpoch}${_resolveImageExtension(trimmedPath)}';
    final storageRef = storage.ref().child(folderPath).child(fileName);
    await storageRef.putFile(file);
    return storageRef.getDownloadURL();
  }

  String _resolveImageExtension(String localPath) {
    final dotIndex = localPath.lastIndexOf('.');
    if (dotIndex == -1 || dotIndex == localPath.length - 1) {
      return '.jpg';
    }
    final extension = localPath.substring(dotIndex).trim().toLowerCase();
    if (extension.length > 10) {
      return '.jpg';
    }
    return extension;
  }

  String _sanitizeStorageSegment(String? raw, {required String fallback}) {
    final value = raw?.trim() ?? '';
    if (value.isEmpty) {
      return fallback;
    }
    return value.replaceAll(RegExp(r'[\\/]+'), '_');
  }

  Future<String> _resolveActivityDocId({
    required CollectionReference<Map<String, dynamic>> collection,
    required AdminActivity activity,
  }) async {
    final rawId = activity.id.trim();
    if (rawId.isEmpty) {
      return _generateLowercaseActivityId();
    }

    // 若是编辑已有文档，保持原 docId 不变，避免破坏历史引用。
    final existing = await collection.doc(rawId).get();
    if (existing.exists) {
      return rawId;
    }

    final normalized = _normalizeActivityId(rawId);
    if (normalized.isNotEmpty) {
      return normalized;
    }
    return _generateLowercaseActivityId();
  }

  String _normalizeActivityId(String value) {
    final lower = value.trim().toLowerCase();
    var normalized = lower.replaceAll(RegExp(r'[^a-z0-9_-]+'), '_');
    normalized = normalized.replaceAll(RegExp(r'_+'), '_');
    normalized = normalized.replaceAll(RegExp(r'^[_-]+|[_-]+$'), '');
    return normalized;
  }

  String _generateLowercaseActivityId() {
    final randomPart = List<String>.generate(
      6,
      (_) => _base36Alphabet[_random.nextInt(_base36Alphabet.length)],
    ).join();
    return 'event_${DateTime.now().millisecondsSinceEpoch}_$randomPart';
  }

  List<String> _normalizeActivityCategories(Iterable<String> categories) {
    final normalized = <String>{};
    for (final category in categories) {
      final key = _normalizeActivityCategory(category);
      if (key != null) {
        normalized.add(key);
      }
    }
    return normalized.toList(growable: false);
  }

  List<String> _readActivityCategories(Map<String, dynamic> data) {
    final rawValues = <String>[];
    final rawList = data['categories'];
    if (rawList is List) {
      for (final value in rawList) {
        if (value is String && value.trim().isNotEmpty) {
          rawValues.add(value.trim());
        }
      }
    }
    final rawCategory = data['category'];
    if (rawCategory is String && rawCategory.trim().isNotEmpty) {
      rawValues.add(rawCategory.trim());
    }
    return _normalizeActivityCategories(rawValues);
  }

  String? _normalizeActivityCategory(String value) {
    final normalized = value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[\s_-]+'), ' ')
        .trim();
    switch (normalized) {
      case 'traditional festival':
      case 'traditionalfestival':
      case 'traditional':
      case 'festival':
      case '传统节日':
        return 'traditional_festival';
      case 'music':
      case '音乐':
        return 'music';
      case 'exhibition':
      case 'exhibit':
      case '展览':
        return 'exhibition';
      case 'entertainment':
      case 'fun':
      case '娱乐':
        return 'entertainment';
      case 'nature':
      case 'natural':
      case '自然':
        return 'nature';
      default:
        return null;
    }
  }

  Map<String, String> _readLanguageMapWithStringFallback(Object? value) {
    if (value is String) {
      final text = value.trim();
      if (text.isEmpty) {
        return const <String, String>{'zh': '', 'en': ''};
      }
      return <String, String>{'zh': text, 'en': text};
    }
    final map = _readLanguageMap(value);
    return <String, String>{
      'zh': map['zh']?.trim() ?? '',
      'en': map['en']?.trim() ?? '',
    };
  }

  Map<String, String> _readLanguageMap(Object? value) {
    if (value is! Map) {
      return const <String, String>{};
    }
    final result = <String, String>{};
    for (final entry in value.entries) {
      final normalizedKey = _normalizeLanguageKey(entry.key.toString());
      if (normalizedKey == null || entry.value is! String) {
        continue;
      }
      final text = (entry.value as String).trim();
      if (text.isNotEmpty) {
        result[normalizedKey] = text;
      }
    }
    return result;
  }

  Map<String, String> _sanitizeLanguageMap(Map<String, String> value) {
    final zh = value['zh']?.trim() ?? '';
    final en = value['en']?.trim() ?? '';
    return <String, String>{'zh': zh, 'en': en};
  }

  String? _normalizeLanguageKey(String rawKey) {
    final normalized = rawKey.trim().toLowerCase().replaceAll('_', '-');
    if (normalized.startsWith('zh')) {
      return 'zh';
    }
    if (normalized.startsWith('en')) {
      return 'en';
    }
    return null;
  }

  List<String> _readStringList(Object? value) {
    if (value is List) {
      return value
          .whereType<String>()
          .map((entry) => entry.trim())
          .where((entry) => entry.isNotEmpty)
          .toList(growable: false);
    }
    return const <String>[];
  }

  double? _toDouble(Object? value) {
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value.trim());
    }
    return null;
  }

  int? _toInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value.trim());
    }
    return null;
  }

  DateTime? _readDateTime(Object? value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is DateTime) {
      return value;
    }
    if (value is String) {
      return DateTime.tryParse(value.trim());
    }
    return null;
  }

  Future<bool> _regionExistsInternal(String regionId) async {
    final trimmed = regionId.trim();
    if (trimmed.isEmpty) {
      return false;
    }
    final doc = await firestore.collection('regions').doc(trimmed).get();
    return doc.exists;
  }
}
