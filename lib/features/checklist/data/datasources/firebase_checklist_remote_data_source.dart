import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/error/app_exception.dart';
import '../../domain/entities/checklist_detail.dart';
import '../../domain/entities/checklist_item.dart';
import '../../domain/entities/journey_basic_info_input.dart';
import 'checklist_remote_data_source.dart';

class FirebaseChecklistRemoteDataSource implements ChecklistRemoteDataSource {
  FirebaseChecklistRemoteDataSource({
    required this.firestore,
    required this.firebaseAuth,
  });

  final FirebaseFirestore firestore;
  final FirebaseAuth firebaseAuth;

  @override
  Future<List<ChecklistItem>> getMyChecklists() async {
    try {
      final userId = firebaseAuth.currentUser?.uid;
      if (userId == null || userId.trim().isEmpty) {
        return const <ChecklistItem>[];
      }

      final snapshot = await firestore
          .collection('users')
          .doc(userId)
          .collection('checklists')
          .get();

      final items = snapshot.docs
          .map((doc) => _mapChecklistItem(doc.id, doc.data()))
          .toList(growable: false);

      if (items.isEmpty) {
        return const <ChecklistItem>[];
      }

      final coverImageMap = await _loadCoverImages(
        items
            .map((item) => item.placeId.trim())
            .where((placeId) => placeId.isNotEmpty)
            .toSet(),
      );

      final enrichedItems = items
          .map(
            (item) => item.copyWith(
              coverImageUrl:
                  coverImageMap[item.placeId.trim()] ??
                  item.coverImageUrl.trim(),
            ),
          )
          .toList(growable: false);

      enrichedItems.sort((left, right) {
        final leftDate =
            left.startDate ?? DateTime.fromMillisecondsSinceEpoch(0);
        final rightDate =
            right.startDate ?? DateTime.fromMillisecondsSinceEpoch(0);
        final dateCompare = leftDate.compareTo(rightDate);
        if (dateCompare != 0) {
          return dateCompare;
        }
        return left.destination.compareTo(right.destination);
      });
      return enrichedItems;
    } catch (_) {
      throw AppException('checklist_load_failed');
    }
  }

  @override
  Future<ChecklistItem?> getChecklistById(String checklistId) async {
    try {
      final ref = _resolveChecklistCollection().doc(checklistId.trim());
      final doc = await ref.get();
      if (!doc.exists) {
        return null;
      }
      final data = doc.data();
      if (data == null) {
        return null;
      }
      return _mapChecklistItem(doc.id, data);
    } catch (_) {
      throw AppException('checklist_load_failed');
    }
  }

  @override
  Future<ChecklistDetail?> getChecklistDetail(String checklistId) async {
    try {
      final ref = _resolveChecklistCollection().doc(checklistId.trim());
      final doc = await ref.get();
      if (!doc.exists) {
        return null;
      }
      final data = doc.data();
      if (data == null) {
        return null;
      }
      return _mapChecklistDetail(doc.id, data);
    } catch (_) {
      throw AppException('checklist_load_failed');
    }
  }

  @override
  Future<String> createChecklistFromPlace({
    required String placeId,
    required String destination,
    String? coverImageUrl,
  }) async {
    try {
      final userId = firebaseAuth.currentUser?.uid;
      if (userId == null || userId.trim().isEmpty) {
        throw AppException('checklist_create_failed');
      }

      final trimmedPlaceId = placeId.trim();
      final trimmedDestination = destination.trim();
      final trimmedCoverImageUrl = coverImageUrl?.trim() ?? '';
      final ref = firestore
          .collection('users')
          .doc(userId)
          .collection('checklists')
          .doc();

      // 基于当前 place 创建行程清单，字段结构与后续正式数据保持一致。
      await ref.set(<String, dynamic>{
        'placeId': trimmedPlaceId,
        'destination': trimmedDestination,
        'coverImageUrl': trimmedCoverImageUrl,
        'createdAt': FieldValue.serverTimestamp(),
        'basicInfoCompleted': false,
        'planningStatus': 'collecting',
        'totalBudget': null,
        'aiGenerated': false,
      });

      return ref.id;
    } catch (_) {
      throw AppException('checklist_create_failed');
    }
  }

  @override
  Future<void> saveJourneyBasicInfo({
    required String checklistId,
    required JourneyBasicInfoInput input,
  }) async {
    try {
      final ref = _resolveChecklistCollection().doc(checklistId.trim());
      await ref.set(<String, dynamic>{
        'departureCity': input.departureCity.trim(),
        'departureCountry': input.departureCountry?.trim(),
        'departureLatitude': input.departureLatitude,
        'departureLongitude': input.departureLongitude,
        'departureSource': input.departureSource?.trim(),
        'startDate': Timestamp.fromDate(input.startDate),
        'endDate': Timestamp.fromDate(input.endDate),
        'tripDays': input.tripDays,
        'travelerCount': input.travelerCount,
        'totalBudget': input.totalBudget,
        'currency': input.currency.trim(),
        'preferences': input.preferences
            .map((value) => value.trim())
            .where((value) => value.isNotEmpty)
            .toList(growable: false),
        'pace': input.pace.trim(),
        'accommodationPreference': input.accommodationPreference.trim(),
        'basicInfoCompleted': input.basicInfoCompleted,
        'planningStatus': input.basicInfoCompleted
            ? 'readyToPlan'
            : 'collecting',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {
      throw AppException('checklist_save_failed');
    }
  }

  @override
  Future<void> updateBudget({
    required String checklistId,
    double? totalBudget,
    String? currencySymbol,
  }) async {
    try {
      final ref = _resolveChecklistCollection().doc(checklistId.trim());
      await ref.set(<String, dynamic>{
        'totalBudget': totalBudget,
        'currencySymbol': (currencySymbol ?? '').trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {
      throw AppException('checklist_save_failed');
    }
  }

  @override
  Future<void> updateBudgetSplit({
    required String checklistId,
    double? transportRatio,
    double? stayRatio,
    double? foodActivityRatio,
  }) async {
    try {
      final ref = _resolveChecklistCollection().doc(checklistId.trim());
      await ref.set(<String, dynamic>{
        'budgetSplit': <String, dynamic>{
          'transportRatio': transportRatio,
          'stayRatio': stayRatio,
          'foodActivityRatio': foodActivityRatio,
        },
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {
      throw AppException('checklist_save_failed');
    }
  }

  @override
  Future<void> toggleItemCompleted({
    required String checklistId,
    required String itemId,
  }) async {
    try {
      final ref = _resolveChecklistCollection().doc(checklistId.trim());
      final doc = await ref.get();
      final data = doc.data();
      if (!doc.exists || data == null) {
        return;
      }

      final currentItems = _readChecklistItems(data['items']);
      final index = currentItems.indexWhere((item) => item.id == itemId.trim());
      if (index < 0) {
        return;
      }

      final nextItems = currentItems.toList(growable: false);
      final target = nextItems[index];
      nextItems[index] = target.copyWith(isCompleted: !target.isCompleted);

      await ref.set(<String, dynamic>{
        'items': nextItems.map(_toItemJson).toList(growable: false),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {
      throw AppException('checklist_save_failed');
    }
  }

  @override
  Future<void> updatePlan(String checklistId) async {
    try {
      final ref = _resolveChecklistCollection().doc(checklistId.trim());
      // 先占位更新时间，后续可在云函数或后端任务里生成计划建议。
      await ref.set(<String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {
      throw AppException('checklist_save_failed');
    }
  }

  @override
  Future<void> deleteChecklist(String checklistId) async {
    try {
      final userId = firebaseAuth.currentUser?.uid;
      if (userId == null || userId.trim().isEmpty) {
        throw AppException('checklist_delete_failed');
      }

      await firestore
          .collection('users')
          .doc(userId)
          .collection('checklists')
          .doc(checklistId)
          .delete();
    } catch (_) {
      throw AppException('checklist_delete_failed');
    }
  }

  ChecklistItem _mapChecklistItem(String id, Map<String, dynamic> data) {
    return ChecklistItem(
      id: id,
      destination: (data['destination'] as String?)?.trim() ?? '',
      placeId: (data['placeId'] as String?)?.trim() ?? '',
      coverImageUrl: (data['coverImageUrl'] as String?)?.trim() ?? '',
      departureCity: (data['departureCity'] as String?)?.trim(),
      departureCountry: (data['departureCountry'] as String?)?.trim(),
      departureLatitude: _readDouble(data['departureLatitude']),
      departureLongitude: _readDouble(data['departureLongitude']),
      departureSource: (data['departureSource'] as String?)?.trim(),
      startDate: _readDateTime(data['startDate']),
      endDate: _readDateTime(data['endDate']),
      tripDays: _readInt(data['tripDays']),
      travelerCount: _readInt(data['travelerCount']),
      totalBudget: _readDouble(data['totalBudget']),
      currency:
          (data['currency'] as String?)?.trim() ??
          (data['currencySymbol'] as String?)?.trim(),
      preferences: _readStringList(data['preferences']),
      pace: (data['pace'] as String?)?.trim(),
      accommodationPreference: (data['accommodationPreference'] as String?)
          ?.trim(),
      basicInfoCompleted: (data['basicInfoCompleted'] as bool?) ?? false,
      statusText: (data['statusText'] as String?)?.trim(),
    );
  }

  ChecklistDetail _mapChecklistDetail(String id, Map<String, dynamic> data) {
    final budgetSplit = _readBudgetSplit(data);
    final proTip = _readProTip(data);
    return ChecklistDetail(
      id: id,
      destination: (data['destination'] as String?)?.trim() ?? '',
      departureCity: (data['departureCity'] as String?)?.trim(),
      startDate: _readDateTime(data['startDate']),
      endDate: _readDateTime(data['endDate']),
      tripDays: _readInt(data['tripDays']),
      durationText: (data['durationText'] as String?)?.trim(),
      travelerCount: _readInt(data['travelerCount']),
      totalBudget: _readDouble(data['totalBudget']),
      currency:
          (data['currency'] as String?)?.trim() ??
          (data['currencySymbol'] as String?)?.trim(),
      currencySymbol: (data['currencySymbol'] as String?)?.trim(),
      preferences: _readStringList(data['preferences']),
      pace: (data['pace'] as String?)?.trim(),
      accommodationPreference: (data['accommodationPreference'] as String?)
          ?.trim(),
      basicInfoCompleted: (data['basicInfoCompleted'] as bool?) ?? false,
      planningStatus: (data['planningStatus'] as String?)?.trim(),
      budgetSplit: budgetSplit?.hasAnyValue == true ? budgetSplit : null,
      essentials: _readEssentials(data['essentials']),
      proTip: proTip?.isEmpty == true ? null : proTip,
      items: _readChecklistItems(data['items']),
    );
  }

  Future<Map<String, String>> _loadCoverImages(Set<String> placeIds) async {
    if (placeIds.isEmpty) {
      return const <String, String>{};
    }

    final result = <String, String>{};
    final docs = await Future.wait(
      placeIds.map(
        (placeId) => firestore.collection('places').doc(placeId).get(),
      ),
    );

    for (final doc in docs) {
      if (!doc.exists) {
        continue;
      }
      final data = doc.data();
      if (data == null) {
        continue;
      }

      final coverImage =
          (data['coverImage'] as String?)?.trim() ??
          (data['previewAssetPath'] as String?)?.trim() ??
          '';
      if (coverImage.isNotEmpty) {
        result[doc.id] = coverImage;
      }
    }

    return result;
  }

  CollectionReference<Map<String, dynamic>> _resolveChecklistCollection() {
    final userId = firebaseAuth.currentUser?.uid;
    if (userId == null || userId.trim().isEmpty) {
      throw AppException('checklist_save_failed');
    }
    return firestore.collection('users').doc(userId).collection('checklists');
  }

  ChecklistBudgetSplit? _readBudgetSplit(Map<String, dynamic> data) {
    final rawBudgetSplit = data['budgetSplit'];
    if (rawBudgetSplit is Map) {
      final map = rawBudgetSplit.cast<Object?, Object?>();
      return ChecklistBudgetSplit(
        transportRatio: _readDouble(map['transportRatio']),
        stayRatio: _readDouble(map['stayRatio']),
        foodActivityRatio: _readDouble(map['foodActivityRatio']),
      );
    }

    return ChecklistBudgetSplit(
      transportRatio: _readDouble(data['transportRatio']),
      stayRatio: _readDouble(data['stayRatio']),
      foodActivityRatio: _readDouble(data['foodActivityRatio']),
    );
  }

  ChecklistProTip? _readProTip(Map<String, dynamic> data) {
    final raw = data['proTip'];
    if (raw is Map) {
      final map = raw.cast<Object?, Object?>();
      return ChecklistProTip(
        tipTitle: (map['tipTitle'] as String?)?.trim(),
        tipDescription: (map['tipDescription'] as String?)?.trim(),
      );
    }
    final tipTitle = (data['tipTitle'] as String?)?.trim();
    final tipDescription = (data['tipDescription'] as String?)?.trim();
    if ((tipTitle ?? '').isEmpty && (tipDescription ?? '').isEmpty) {
      return null;
    }
    return ChecklistProTip(tipTitle: tipTitle, tipDescription: tipDescription);
  }

  List<ChecklistEssential> _readEssentials(Object? value) {
    if (value is! List) {
      return const <ChecklistEssential>[];
    }
    final result = <ChecklistEssential>[];
    for (final item in value) {
      if (item is! Map) {
        continue;
      }
      final map = item.cast<Object?, Object?>();
      final title = (map['title'] as String?)?.trim() ?? '';
      final mainText = (map['mainText'] as String?)?.trim() ?? '';
      if (title.isEmpty && mainText.isEmpty) {
        continue;
      }
      result.add(
        ChecklistEssential(
          iconType: (map['iconType'] as String?)?.trim() ?? '',
          title: title,
          mainText: mainText,
          subText: (map['subText'] as String?)?.trim(),
        ),
      );
    }
    return result;
  }

  List<ChecklistDetailItem> _readChecklistItems(Object? value) {
    if (value is! List) {
      return const <ChecklistDetailItem>[];
    }
    final result = <ChecklistDetailItem>[];
    for (final item in value) {
      if (item is! Map) {
        continue;
      }
      final map = item.cast<Object?, Object?>();
      final id = (map['id'] as String?)?.trim() ?? '';
      final title = (map['title'] as String?)?.trim() ?? '';
      if (id.isEmpty || title.isEmpty) {
        continue;
      }
      result.add(
        ChecklistDetailItem(
          id: id,
          groupType: (map['groupType'] as String?)?.trim() ?? '',
          title: title,
          subtitle: (map['subtitle'] as String?)?.trim(),
          isCompleted: (map['isCompleted'] as bool?) ?? false,
          detailRouteTarget: (map['detailRouteTarget'] as String?)?.trim(),
        ),
      );
    }
    return result;
  }

  Map<String, dynamic> _toItemJson(ChecklistDetailItem item) {
    return <String, dynamic>{
      'id': item.id,
      'groupType': item.groupType,
      'title': item.title,
      'subtitle': item.subtitle,
      'isCompleted': item.isCompleted,
      'detailRouteTarget': item.detailRouteTarget,
    };
  }

  double? _readDouble(Object? value) {
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value.trim());
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

  int? _readInt(Object? value) {
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

  List<String> _readStringList(Object? value) {
    if (value is! List) {
      return const <String>[];
    }
    return value
        .whereType<String>()
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }
}
