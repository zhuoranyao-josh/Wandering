import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/error/app_exception.dart';
import '../../domain/entities/activity_event.dart';
import 'activity_remote_data_source.dart';

class FirebaseActivityRemoteDataSource implements ActivityRemoteDataSource {
  FirebaseActivityRemoteDataSource({required this.firestore});

  final FirebaseFirestore firestore;

  @override
  Stream<List<ActivityEvent>> watchPublishedEvents() {
    // 只做 isPublished 过滤，排序与兼容策略交由本地处理。
    return firestore
        .collection('events')
        .where('isPublished', isEqualTo: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => _mapDocToEvent(doc.id, doc.data()))
              .toList(growable: false),
        );
  }

  @override
  Future<ActivityEvent?> getEventById(String id) async {
    try {
      final doc = await firestore.collection('events').doc(id).get();
      if (!doc.exists) {
        return null;
      }
      final data = doc.data();
      if (data == null) {
        return null;
      }
      return _mapDocToEvent(doc.id, data);
    } catch (_) {
      throw AppException('activity_load_failed');
    }
  }

  ActivityEvent _mapDocToEvent(String id, Map<String, dynamic> data) {
    try {
      return ActivityEvent(
        id: id,
        title: _readLocalizedTextMap(data['title']),
        categories: _readCategories(data),
        cityName: _readLocalizedTextMap(data['cityName']),
        countryName: _readLocalizedTextMap(data['countryName']),
        cityCode: (data['cityCode'] as String?)?.trim() ?? '',
        coverImageUrl: (data['coverImageUrl'] as String?)?.trim() ?? '',
        // startAt / endAt 均允许为空，支持长期开放或待定活动。
        startAt: _readDateTime(data['startAt']),
        endAt: _readDateTime(data['endAt']),
        isPublished: (data['isPublished'] as bool?) ?? false,
        isFeatured: (data['isFeatured'] as bool?) ?? false,
        detailText: _readLocalizedTextMap(data['detailText']),
        createdAt: _readDateTime(data['createdAt']),
        updatedAt: _readDateTime(data['updatedAt']),
      );
    } catch (_) {
      throw AppException('activity_load_failed');
    }
  }

  DateTime? _readDateTime(Object? value) {
    if (value == null) {
      return null;
    }
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

  // 兼容旧 string 数据，统一转为 bilingual map。
  Map<String, String> _readLocalizedTextMap(Object? value) {
    if (value is String) {
      final text = value.trim();
      if (text.isEmpty) {
        return const <String, String>{'zh': '', 'en': ''};
      }
      return <String, String>{'zh': text, 'en': text};
    }
    if (value is Map) {
      final zh = value['zh']?.toString().trim() ?? '';
      final en = value['en']?.toString().trim() ?? '';
      return <String, String>{'zh': zh, 'en': en};
    }
    return const <String, String>{'zh': '', 'en': ''};
  }

  List<String> _readCategories(Map<String, dynamic> data) {
    final rawCategories = <String>[];
    final categoriesValue = data['categories'];
    if (categoriesValue is List) {
      for (final item in categoriesValue) {
        if (item is String && item.trim().isNotEmpty) {
          rawCategories.add(item.trim());
        }
      }
    }
    final categoryValue = data['category'];
    if (categoryValue is String && categoryValue.trim().isNotEmpty) {
      rawCategories.add(categoryValue.trim());
    }
    return _normalizeRawCategories(rawCategories);
  }

  List<String> _normalizeRawCategories(Iterable<String> values) {
    final normalized = <String>{};
    for (final value in values) {
      final category = _normalizeCategory(value);
      if (category != null) {
        normalized.add(category);
      }
    }
    return normalized.toList(growable: false);
  }

  String? _normalizeCategory(String value) {
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
}
