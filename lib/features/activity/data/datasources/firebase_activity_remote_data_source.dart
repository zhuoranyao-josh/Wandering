import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/error/app_exception.dart';
import '../../domain/entities/activity_event.dart';
import 'activity_remote_data_source.dart';

class FirebaseActivityRemoteDataSource implements ActivityRemoteDataSource {
  final FirebaseFirestore firestore;

  FirebaseActivityRemoteDataSource({required this.firestore});

  @override
  Stream<List<ActivityEvent>> watchPublishedEvents() {
    // 这里只保留“已发布”这一层 Firestore 过滤。
    // startAt 允许为空时，不再在查询层直接 orderBy(startAt)，
    // 避免缺少该字段的长期活动被查询排除，排序改由本地处理。
    return firestore
        .collection('events')
        .where('isPublished', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => _mapDocToEvent(doc.id, doc.data()))
              .toList(growable: false);
        });
  }

  @override
  Future<ActivityEvent?> getEventById(String id) async {
    try {
      final doc = await firestore.collection('events').doc(id).get();
      if (!doc.exists) return null;

      final data = doc.data();
      if (data == null) return null;

      return _mapDocToEvent(doc.id, data);
    } catch (_) {
      throw AppException('activity_load_failed');
    }
  }

  ActivityEvent _mapDocToEvent(String id, Map<String, dynamic> data) {
    try {
      return ActivityEvent(
        id: id,
        title: (data['title'] as String?)?.trim() ?? '',
        category: (data['category'] as String?)?.trim() ?? '',
        cityName: (data['cityName'] as String?)?.trim() ?? '',
        countryName: (data['countryName'] as String?)?.trim() ?? '',
        cityCode: (data['cityCode'] as String?)?.trim() ?? '',
        coverImageUrl: (data['coverImageUrl'] as String?)?.trim() ?? '',
        // startAt / endAt 都允许为空，表示长期营业或时间待定的活动。
        startAt: _readDateTime(data['startAt']),
        endAt: _readDateTime(data['endAt']),
        isPublished: (data['isPublished'] as bool?) ?? false,
        isFeatured: (data['isFeatured'] as bool?) ?? false,
        detailText: (data['detailText'] as String?)?.trim() ?? '',
        createdAt: _readDateTime(data['createdAt']),
        updatedAt: _readDateTime(data['updatedAt']),
      );
    } catch (_) {
      throw AppException('activity_load_failed');
    }
  }

  DateTime? _readDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is DateTime) {
      return value;
    }
    if (value is String) {
      return DateTime.tryParse(value);
    }
    return null;
  }
}
