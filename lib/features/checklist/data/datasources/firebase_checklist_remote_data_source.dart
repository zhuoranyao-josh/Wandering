import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/error/app_exception.dart';
import '../../domain/entities/checklist_detail.dart';
import '../../domain/entities/checklist_item.dart';
import '../../domain/entities/journey_basic_info_input.dart';
import 'checklist_remote_data_source.dart';
import 'mock_checklist_plan_generator.dart';

class FirebaseChecklistRemoteDataSource implements ChecklistRemoteDataSource {
  FirebaseChecklistRemoteDataSource({
    required this.firestore,
    required this.firebaseAuth,
  });

  final FirebaseFirestore firestore;
  final FirebaseAuth firebaseAuth;
  final MockChecklistPlanGenerator _generator =
      const MockChecklistPlanGenerator();

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

      final detail = await _mapChecklistDetailAsync(doc.id, data);
      if (detail.items.isNotEmpty) {
        return detail.copyWith(items: _sortItems(detail.items));
      }

      // 优先兼容 journey 子集合，便于后续迁移到正式链路。
      final itemsFromJourney = await _loadJourneyChecklistItems(doc.id);
      if (itemsFromJourney.isEmpty) {
        return detail;
      }
      return detail.copyWith(items: itemsFromJourney);
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
        'nightCount': input.nightCount,
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
  Future<void> generateChecklistPlan(String checklistId) async {
    try {
      final userId = firebaseAuth.currentUser?.uid;
      if (userId == null || userId.trim().isEmpty) {
        throw AppException('checklist_generate_failed');
      }

      final trimmedId = checklistId.trim();
      final checklistRef = _resolveChecklistCollection().doc(trimmedId);
      final checklistDoc = await checklistRef.get();
      if (!checklistDoc.exists || checklistDoc.data() == null) {
        throw AppException('checklist_generate_failed');
      }

      final detail = _mapChecklistDetail(checklistDoc.id, checklistDoc.data()!);
      final result = _generator.generate(journeyId: trimmedId, detail: detail);
      final items = _sortItems(result.items);
      final now = FieldValue.serverTimestamp();

      final journeyItemsCollection = firestore
          .collection('users')
          .doc(userId)
          .collection('journeys')
          .doc(trimmedId)
          .collection('checklistItems');

      final batch = firestore.batch();
      for (final item in items) {
        batch.set(journeyItemsCollection.doc(item.id), <String, dynamic>{
          ..._toItemJson(item),
          'createdAt': now,
          'updatedAt': now,
        }, SetOptions(merge: true));
      }

      batch.set(checklistRef, <String, dynamic>{
        'items': items.map(_toItemJson).toList(growable: false),
        'budgetSplit': _toBudgetSplitJson(result.budgetSplit),
        'planningStatus': 'planned',
        'basicInfoCompleted': true,
        'updatedAt': now,
      }, SetOptions(merge: true));

      await batch.commit();
    } catch (_) {
      throw AppException('checklist_generate_failed');
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
      final currentDoc = await ref.get();
      final currentSplit = (currentDoc.exists && currentDoc.data() != null)
          ? _readBudgetSplit(currentDoc.data()!)
          : null;
      final nextSplit = (currentSplit ?? const ChecklistBudgetSplit()).copyWith(
        transportRatio: transportRatio,
        stayRatio: stayRatio,
        foodActivityRatio: foodActivityRatio,
      );

      await ref.set(<String, dynamic>{
        'budgetSplit': _toBudgetSplitJson(nextSplit),
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
      final trimmedId = checklistId.trim();
      final ref = _resolveChecklistCollection().doc(trimmedId);
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
      final toggled = target.copyWith(isCompleted: !target.isCompleted);
      nextItems[index] = toggled;

      final updates = <String, dynamic>{
        'items': nextItems.map(_toItemJson).toList(growable: false),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      await ref.set(updates, SetOptions(merge: true));

      final userId = firebaseAuth.currentUser?.uid;
      if (userId != null && userId.trim().isNotEmpty) {
        await firestore
            .collection('users')
            .doc(userId)
            .collection('journeys')
            .doc(trimmedId)
            .collection('checklistItems')
            .doc(itemId.trim())
            .set(<String, dynamic>{
              'isCompleted': toggled.isCompleted,
              'updatedAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
      }
    } catch (_) {
      throw AppException('checklist_save_failed');
    }
  }

  @override
  Future<void> updatePlan(String checklistId) async {
    // 兼容旧调用：直接复用新的 mock 生成链路。
    await generateChecklistPlan(checklistId);
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
      nightCount: _readInt(data['nightCount']),
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
      placeId: (data['placeId'] as String?)?.trim(),
      latitude:
          _readDouble(data['latitude']) ?? _readDouble(data['markerLatitude']),
      longitude:
          _readDouble(data['longitude']) ??
          _readDouble(data['markerLongitude']),
      departureCity: (data['departureCity'] as String?)?.trim(),
      startDate: _readDateTime(data['startDate']),
      endDate: _readDateTime(data['endDate']),
      tripDays: _readInt(data['tripDays']),
      nightCount: _readInt(data['nightCount']),
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
      items: _sortItems(_readChecklistItems(data['items'])),
    );
  }

  Future<ChecklistDetail> _mapChecklistDetailAsync(
    String id,
    Map<String, dynamic> data,
  ) async {
    final detail = _mapChecklistDetail(id, data);
    if (detail.latitude != null && detail.longitude != null) {
      return detail;
    }

    final placeId = detail.placeId?.trim() ?? '';
    if (placeId.isEmpty) {
      return detail;
    }

    final coords = await _loadPlaceCoordinates(placeId);
    if (coords == null) {
      return detail;
    }

    return detail.copyWith(latitude: coords.$1, longitude: coords.$2);
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

  Future<(double, double)?> _loadPlaceCoordinates(String placeId) async {
    final doc = await firestore.collection('places').doc(placeId).get();
    if (!doc.exists) {
      return null;
    }

    final data = doc.data();
    if (data == null) {
      return null;
    }

    final latitude =
        _readDouble(data['latitude']) ?? _readDouble(data['markerLatitude']);
    final longitude =
        _readDouble(data['longitude']) ?? _readDouble(data['markerLongitude']);
    if (latitude == null || longitude == null) {
      return null;
    }
    return (latitude, longitude);
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
        flightBudgetMax: _readDouble(map['flightBudgetMax']),
        remainingBudget: _readDouble(map['remainingBudget']),
        hotelBudget: _readDouble(map['hotelBudget']),
        foodBudget: _readDouble(map['foodBudget']),
        activityBudget: _readDouble(map['activityBudget']),
        localTransportBudget: _readDouble(map['localTransportBudget']),
        bufferBudget: _readDouble(map['bufferBudget']),
        currency: (map['currency'] as String?)?.trim(),
        budgetWarning: (map['budgetWarning'] as String?)?.trim(),
      );
    }

    return ChecklistBudgetSplit(
      transportRatio: _readDouble(data['transportRatio']),
      stayRatio: _readDouble(data['stayRatio']),
      foodActivityRatio: _readDouble(data['foodActivityRatio']),
      flightBudgetMax: _readDouble(data['flightBudgetMax']),
      remainingBudget: _readDouble(data['remainingBudget']),
      hotelBudget: _readDouble(data['hotelBudget']),
      foodBudget: _readDouble(data['foodBudget']),
      activityBudget: _readDouble(data['activityBudget']),
      localTransportBudget: _readDouble(data['localTransportBudget']),
      bufferBudget: _readDouble(data['bufferBudget']),
      currency: (data['currency'] as String?)?.trim(),
      budgetWarning: (data['budgetWarning'] as String?)?.trim(),
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
          type: (map['type'] as String?)?.trim(),
          estimatedPriceMin: _readDouble(map['estimatedPriceMin']),
          estimatedPriceMax: _readDouble(map['estimatedPriceMax']),
          estimatedCostMin: _readDouble(map['estimatedCostMin']),
          estimatedCostMax: _readDouble(map['estimatedCostMax']),
          costUnit: (map['costUnit'] as String?)?.trim(),
          currency: (map['currency'] as String?)?.trim(),
          routeText: (map['routeText'] as String?)?.trim(),
          suggestedAirports: _readStringList(map['suggestedAirports']),
          providerName: (map['providerName'] as String?)?.trim(),
          externalUrl: (map['externalUrl'] as String?)?.trim(),
          dataSource: (map['dataSource'] as String?)?.trim(),
          accuracyNote: (map['accuracyNote'] as String?)?.trim(),
          status: (map['status'] as String?)?.trim(),
          displayOrder: _readInt(map['displayOrder']),
          dayIndex: _readInt(map['dayIndex']),
          estimatedPriceText: (map['estimatedPriceText'] as String?)?.trim(),
          budgetWarning: (map['budgetWarning'] as String?)?.trim(),
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
      'type': item.type,
      'estimatedPriceMin': item.estimatedPriceMin,
      'estimatedPriceMax': item.estimatedPriceMax,
      'estimatedCostMin': item.estimatedCostMin,
      'estimatedCostMax': item.estimatedCostMax,
      'costUnit': item.costUnit,
      'currency': item.currency,
      'routeText': item.routeText,
      'suggestedAirports': item.suggestedAirports,
      'providerName': item.providerName,
      'externalUrl': item.externalUrl,
      'dataSource': item.dataSource,
      'accuracyNote': item.accuracyNote,
      'status': item.status,
      'displayOrder': item.displayOrder,
      'dayIndex': item.dayIndex,
      'estimatedPriceText': item.estimatedPriceText,
      'budgetWarning': item.budgetWarning,
    };
  }

  Map<String, dynamic> _toBudgetSplitJson(ChecklistBudgetSplit split) {
    return <String, dynamic>{
      'transportRatio': split.transportRatio,
      'stayRatio': split.stayRatio,
      'foodActivityRatio': split.foodActivityRatio,
      'flightBudgetMax': split.flightBudgetMax,
      'remainingBudget': split.remainingBudget,
      'hotelBudget': split.hotelBudget,
      'foodBudget': split.foodBudget,
      'activityBudget': split.activityBudget,
      'localTransportBudget': split.localTransportBudget,
      'bufferBudget': split.bufferBudget,
      'currency': split.currency,
      'budgetWarning': split.budgetWarning,
    };
  }

  Future<List<ChecklistDetailItem>> _loadJourneyChecklistItems(
    String journeyId,
  ) async {
    final userId = firebaseAuth.currentUser?.uid;
    if (userId == null || userId.trim().isEmpty) {
      return const <ChecklistDetailItem>[];
    }
    final snapshot = await firestore
        .collection('users')
        .doc(userId)
        .collection('journeys')
        .doc(journeyId.trim())
        .collection('checklistItems')
        .get();

    final items = snapshot.docs
        .map((doc) => _mapChecklistItemFromJourneyDoc(doc.id, doc.data()))
        .toList(growable: false);
    return _sortItems(items);
  }

  ChecklistDetailItem _mapChecklistItemFromJourneyDoc(
    String id,
    Map<String, dynamic> data,
  ) {
    return ChecklistDetailItem(
      id: id,
      groupType: (data['groupType'] as String?)?.trim() ?? '',
      title: (data['title'] as String?)?.trim() ?? '',
      subtitle: (data['subtitle'] as String?)?.trim(),
      isCompleted: (data['isCompleted'] as bool?) ?? false,
      detailRouteTarget: (data['detailRouteTarget'] as String?)?.trim(),
      type: (data['type'] as String?)?.trim(),
      estimatedPriceMin: _readDouble(data['estimatedPriceMin']),
      estimatedPriceMax: _readDouble(data['estimatedPriceMax']),
      estimatedCostMin: _readDouble(data['estimatedCostMin']),
      estimatedCostMax: _readDouble(data['estimatedCostMax']),
      costUnit: (data['costUnit'] as String?)?.trim(),
      currency: (data['currency'] as String?)?.trim(),
      routeText: (data['routeText'] as String?)?.trim(),
      suggestedAirports: _readStringList(data['suggestedAirports']),
      providerName: (data['providerName'] as String?)?.trim(),
      externalUrl: (data['externalUrl'] as String?)?.trim(),
      dataSource: (data['dataSource'] as String?)?.trim(),
      accuracyNote: (data['accuracyNote'] as String?)?.trim(),
      status: (data['status'] as String?)?.trim(),
      displayOrder: _readInt(data['displayOrder']),
      dayIndex: _readInt(data['dayIndex']),
      estimatedPriceText: (data['estimatedPriceText'] as String?)?.trim(),
      budgetWarning: (data['budgetWarning'] as String?)?.trim(),
    );
  }

  List<ChecklistDetailItem> _sortItems(List<ChecklistDetailItem> items) {
    final sorted = items.toList(growable: false);
    sorted.sort((a, b) {
      final orderA = a.displayOrder ?? 0;
      final orderB = b.displayOrder ?? 0;
      if (orderA != orderB) {
        return orderA.compareTo(orderB);
      }
      return a.id.compareTo(b.id);
    });
    return sorted;
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
