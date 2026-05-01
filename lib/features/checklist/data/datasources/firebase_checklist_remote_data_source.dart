import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/error/app_exception.dart';
import '../../domain/entities/checklist_detail.dart';
import '../../domain/entities/checklist_destination_snapshot.dart';
import '../../domain/entities/checklist_item.dart';
import '../../domain/entities/checklist_plan_progress.dart';
import '../../domain/entities/journey_basic_info_input.dart';
import 'checklist_remote_data_source.dart';
import 'gemini_planning_remote_data_source.dart';
import 'google_places_remote_data_source.dart';

class FirebaseChecklistRemoteDataSource implements ChecklistRemoteDataSource {
  FirebaseChecklistRemoteDataSource({
    required this.firestore,
    required this.firebaseAuth,
    required this.geminiPlanningRemoteDataSource,
    required this.googlePlacesRemoteDataSource,
  });

  final FirebaseFirestore firestore;
  final FirebaseAuth firebaseAuth;
  final GeminiPlanningRemoteDataSource geminiPlanningRemoteDataSource;
  final GooglePlacesRemoteDataSource googlePlacesRemoteDataSource;

  void _log(String message) {
    debugPrint('[ChecklistPlan] $message');
  }

  void _logProgress({
    required ChecklistPlanProgressStep step,
    required double progressPercent,
    String? message,
    int? currentItemIndex,
    int? totalItemCount,
  }) {
    final buffer = StringBuffer(
      '[ChecklistPlanProgress] step=$step message=${message ?? ''} '
      'progress=${(progressPercent * 100).toStringAsFixed(0)}%',
    );
    if (currentItemIndex != null && totalItemCount != null) {
      buffer.write(' index=$currentItemIndex total=$totalItemCount');
    }
    debugPrint(buffer.toString());
  }

  @override
  Future<List<ChecklistItem>> getMyChecklists() async {
    final stopwatch = Stopwatch()..start();
    try {
      final userId = firebaseAuth.currentUser?.uid;
      debugPrint(
        '[MyTrips] auth user ready '
        'elapsed=${stopwatch.elapsedMilliseconds}ms '
        'hasUser=${userId != null && userId.trim().isNotEmpty}',
      );
      if (userId == null || userId.trim().isEmpty) {
        return const <ChecklistItem>[];
      }

      debugPrint(
        '[MyTrips] query started userId=${_maskUserId(userId)} '
        'scope=users/{uid}/checklists orderBy=none limit=none',
      );
      final queryStopwatch = Stopwatch()..start();
      final snapshot = await firestore
          .collection('users')
          .doc(userId)
          .collection('checklists')
          .get();
      final payloadStats = _summarizeChecklistPayload(snapshot.docs);
      debugPrint(
        '[MyTrips] query completed count=${snapshot.docs.length} '
        'elapsed=${queryStopwatch.elapsedMilliseconds}ms '
        'docsWithItems=${payloadStats.docsWithItems} '
        'totalItems=${payloadStats.totalItems} '
        'docsWithEssentials=${payloadStats.docsWithEssentials} '
        'totalEssentials=${payloadStats.totalEssentials} '
        'docsWithProTip=${payloadStats.docsWithProTip} '
        'docsWithBudgetSplit=${payloadStats.docsWithBudgetSplit}',
      );

      final mappingStopwatch = Stopwatch()..start();
      final items = snapshot.docs
          .map((doc) => _mapChecklistItem(doc.id, doc.data()))
          .toList(growable: false);

      if (items.isEmpty) {
        debugPrint(
          '[MyTrips] mapping completed '
          'elapsed=${mappingStopwatch.elapsedMilliseconds}ms',
        );
        return const <ChecklistItem>[];
      }

      final placeIds = items
          .map((item) => item.placeId?.trim() ?? '')
          .where((placeId) => placeId.isNotEmpty)
          .toSet();
      debugPrint(
        '[MyTrips] cover image doc lookup started count=${placeIds.length}',
      );
      final coverImageStopwatch = Stopwatch()..start();
      final coverImageMap = await _loadCoverImages(placeIds);
      debugPrint(
        '[MyTrips] cover image doc lookup completed '
        'count=${coverImageMap.length} '
        'elapsed=${coverImageStopwatch.elapsedMilliseconds}ms',
      );

      final enrichedItems = items
          .map(
            (item) => item.copyWith(
              coverImageUrl: item.resolvedCoverImageUrl.isNotEmpty
                  ? item.resolvedCoverImageUrl
                  : (coverImageMap[item.placeId?.trim() ?? ''] ??
                        item.coverImageUrl.trim()),
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
        return left.resolvedDestinationName.compareTo(
          right.resolvedDestinationName,
        );
      });
      debugPrint(
        '[MyTrips] mapping completed '
        'elapsed=${mappingStopwatch.elapsedMilliseconds}ms '
        'totalElapsed=${stopwatch.elapsedMilliseconds}ms',
      );
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

      // 优先兼容 journey 子集合，便于后续逐步迁移到正式链路。
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
    Map<String, String>? destinationNames,
    ChecklistDestinationSnapshot? destinationSnapshot,
  }) async {
    try {
      final trimmedPlaceId = placeId.trim();
      final snapshot =
          destinationSnapshot ??
          await _buildOfficialDestinationSnapshot(
            placeId: trimmedPlaceId,
            destination: destination,
            coverImageUrl: coverImageUrl,
          );
      final resolvedDestinationNames =
          destinationNames ??
          await _loadOfficialDestinationNames(
            placeId: trimmedPlaceId,
            fallbackName: destination,
          );
      return _createChecklistDocument(
        placeId: trimmedPlaceId,
        destination: destination,
        coverImageUrl: coverImageUrl,
        destinationNames: resolvedDestinationNames,
        destinationSourceType: ChecklistDestinationSourceType.official,
        destinationSnapshot: snapshot,
      );
    } catch (_) {
      throw AppException('checklist_create_failed');
    }
  }

  @override
  Future<String> createChecklistFromDestinationSnapshot({
    required ChecklistDestinationSnapshot destinationSnapshot,
    Map<String, String>? destinationNames,
  }) async {
    try {
      final resolvedDestinationNames =
          destinationNames ??
          _buildFallbackDestinationNames(destinationSnapshot.name);
      return _createChecklistDocument(
        placeId: null,
        destination: destinationSnapshot.name,
        coverImageUrl: destinationSnapshot.coverImageUrl,
        destinationNames: resolvedDestinationNames,
        destinationSourceType: ChecklistDestinationSourceType.mapbox,
        destinationSnapshot: destinationSnapshot,
      );
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
  Future<ChecklistDetail> generateChecklistPlan(
    String checklistId, {
    ChecklistPlanProgressCallback? onProgress,
    ChecklistPlanCancelChecker? shouldCancel,
  }) async {
    final trimmedId = checklistId.trim();
    void throwIfCancelled() {
      if (shouldCancel?.call() ?? false) {
        throw AppException('checklist_generate_cancelled');
      }
    }

    void emitProgress(
      ChecklistPlanProgressStep step,
      double progressPercent, {
      int? currentItemIndex,
      int? totalItemCount,
      bool hasPartialFailures = false,
      String? errorCode,
      String? errorDetail,
      String? debugMessage,
    }) {
      _logProgress(
        step: step,
        progressPercent: progressPercent,
        message: debugMessage,
        currentItemIndex: currentItemIndex,
        totalItemCount: totalItemCount,
      );
      onProgress?.call(
        ChecklistPlanProgress(
          step: step,
          progressPercent: progressPercent,
          messageCode: debugMessage,
          currentItemIndex: currentItemIndex,
          totalItemCount: totalItemCount,
          hasPartialFailures: hasPartialFailures,
          errorCode: errorCode,
          errorDetail: errorDetail,
        ),
      );
    }

    emitProgress(
      ChecklistPlanProgressStep.preparingTripInformation,
      0.05,
      debugMessage: 'preparing_trip_information',
    );
    try {
      throwIfCancelled();
      _log('repository generateChecklistPlan started checklistId=$trimmedId');
      final checklistRef = _resolveChecklistCollection().doc(trimmedId);
      final checklistDoc = await checklistRef.get();
      throwIfCancelled();
      final checklistData = checklistDoc.data();
      if (!checklistDoc.exists || checklistData == null) {
        _log('checklist document not found checklistId=$trimmedId');
        throw AppException('Checklist document not found.');
      }

      final detail = await _mapChecklistDetailAsync(
        checklistDoc.id,
        checklistData,
      );
      throwIfCancelled();
      emitProgress(
        ChecklistPlanProgressStep.analyzingBudget,
        0.15,
        debugMessage: 'analyzing_budget',
      );
      final input = _buildGeminiPlanningInput(detail);
      if (input == null) {
        emitProgress(
          ChecklistPlanProgressStep.failed,
          1,
          errorCode: 'missing_required_fields',
          debugMessage: 'failed_missing_required_fields',
        );
        await _updatePlanningStatus(checklistRef, 'failed');
        throw AppException('Missing required planning fields.');
      }

      await _updatePlanningStatus(checklistRef, 'generating');
      throwIfCancelled();

      emitProgress(
        ChecklistPlanProgressStep.generatingAiTravelPlan,
        0.3,
        debugMessage: 'gemini_request_started',
      );
      GeminiGeneratedPlan generatedPlan;
      try {
        throwIfCancelled();
        generatedPlan = await geminiPlanningRemoteDataSource.generatePlan(
          input: input,
        );
        throwIfCancelled();
        emitProgress(
          ChecklistPlanProgressStep.generatingAiTravelPlan,
          0.42,
          debugMessage: 'gemini_response_parsed',
        );
      } catch (error) {
        _log('Gemini generation failed error=$error');
        emitProgress(
          ChecklistPlanProgressStep.failed,
          1,
          errorCode: 'gemini_generation_failed',
          errorDetail: error.toString(),
          debugMessage: 'failed_gemini_generation',
        );
        await _updatePlanningStatus(checklistRef, 'failed');
        rethrow;
      }

      final buildItemsStopwatch = Stopwatch()..start();
      _log('build items started');
      final generatedItems = await _buildGeneratedItems(
        detail: detail,
        input: input,
        generatedPlan: generatedPlan,
        onProgress: emitProgress,
        shouldCancel: shouldCancel,
      );
      final validatedItems = _normalizeAndValidateGeneratedItems(
        input: input,
        budgetSplit: generatedPlan.budgetSplit,
        items: generatedItems,
      );
      throwIfCancelled();
      _log(
        'build items completed elapsed='
        '${buildItemsStopwatch.elapsedMilliseconds}ms',
      );

      emitProgress(
        ChecklistPlanProgressStep.savingChecklist,
        0.92,
        debugMessage: 'saving_checklist',
      );
      final saveStopwatch = Stopwatch()..start();
      _log('save to Firestore started checklistId=$trimmedId');
      await checklistRef.set(<String, dynamic>{
        'budgetSplit': _toBudgetSplitJson(generatedPlan.budgetSplit),
        'essentials': generatedPlan.essentials
            .map(_toEssentialJson)
            .toList(growable: false),
        'proTip': _toProTipJson(generatedPlan.proTip),
        'items': validatedItems.map(_toItemJson).toList(growable: false),
        'planningStatus': 'completed',
        'aiGenerated': true,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      throwIfCancelled();
      final nextDetail = detail.copyWith(
        planningStatus: 'completed',
        budgetSplit: generatedPlan.budgetSplit.hasAnyValue
            ? generatedPlan.budgetSplit
            : null,
        essentials: generatedPlan.essentials,
        proTip: generatedPlan.proTip?.isEmpty == true
            ? null
            : generatedPlan.proTip,
        items: _sortItems(validatedItems),
      );
      emitProgress(
        ChecklistPlanProgressStep.finalizingPlan,
        0.985,
        debugMessage: 'finalizing_plan',
      );
      _log(
        'save to Firestore completed elapsed='
        '${saveStopwatch.elapsedMilliseconds}ms',
      );
      _log('save success checklistId=$trimmedId');
      return nextDetail;
    } catch (error) {
      if (error is AppException &&
          error.code == 'checklist_generate_cancelled') {
        _log('generate cancelled checklistId=$trimmedId');
        rethrow;
      }
      _log('save failed checklistId=$trimmedId error=$error');
      debugPrint('[ChecklistPlanProgress] failed reason=$error');
      onProgress?.call(
        ChecklistPlanProgress(
          step: ChecklistPlanProgressStep.failed,
          progressPercent: 1,
          messageCode: 'failed',
          errorCode: 'checklist_generate_failed',
          errorDetail: error.toString(),
        ),
      );
      if (error is AppException) {
        rethrow;
      }
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
  Future<void> updatePlan(
    String checklistId, {
    ChecklistPlanProgressCallback? onProgress,
    ChecklistPlanCancelChecker? shouldCancel,
  }) async {
    // 兼容旧调用：统一复用真实链路，不再触发 mock 生成。
    await generateChecklistPlan(
      checklistId,
      onProgress: onProgress,
      shouldCancel: shouldCancel,
    );
  }

  GeminiPlanningInput? _buildGeminiPlanningInput(ChecklistDetail detail) {
    final placeId = detail.placeId?.trim() ?? '';
    final destination = detail.resolvedDestinationName;
    final departureCity = detail.departureCity?.trim() ?? '';
    final startDate = detail.startDate;
    final endDate = detail.endDate;
    final tripDays = detail.tripDays;
    final nightCount = detail.nightCount;
    final travelerCount = detail.travelerCount;
    final totalBudget = detail.totalBudget;
    final currency = detail.currency?.trim() ?? '';
    final pace = detail.pace?.trim() ?? '';
    final accommodationPreference =
        detail.accommodationPreference?.trim() ?? '';
    final latitude = detail.resolvedLatitude;
    final longitude = detail.resolvedLongitude;
    final missingFields = <String>[];

    if (destination.isEmpty) {
      missingFields.add('destination');
    }
    if (departureCity.isEmpty) {
      missingFields.add('departureCity');
    }
    if (startDate == null) {
      missingFields.add('startDate');
    }
    if (endDate == null) {
      missingFields.add('endDate');
    }
    if (tripDays == null || tripDays <= 0) {
      missingFields.add('tripDays');
    }
    if (nightCount == null) {
      missingFields.add('nightCount');
    }
    if (travelerCount == null || travelerCount <= 0) {
      missingFields.add('travelerCount');
    }
    if (totalBudget == null || totalBudget <= 0) {
      missingFields.add('totalBudget');
    }
    if (currency.isEmpty) {
      missingFields.add('currency');
    }
    if (latitude == null) {
      missingFields.add('latitude');
    }
    if (longitude == null) {
      missingFields.add('longitude');
    }

    // 关键字段不完整时直接失败，避免调用外部 API 浪费额度。
    if (destination.isEmpty ||
        departureCity.isEmpty ||
        startDate == null ||
        endDate == null ||
        tripDays == null ||
        tripDays <= 0 ||
        nightCount == null ||
        travelerCount == null ||
        travelerCount <= 0 ||
        totalBudget == null ||
        totalBudget <= 0 ||
        currency.isEmpty ||
        pace.isEmpty ||
        accommodationPreference.isEmpty ||
        latitude == null ||
        longitude == null ||
        detail.preferences.isEmpty) {
      for (final field in missingFields) {
        _log('missing required field=$field');
      }
      if (pace.isEmpty) {
        _log('missing required field=pace');
      }
      if (accommodationPreference.isEmpty) {
        _log('missing required field=accommodationPreference');
      }
      if (detail.preferences.isEmpty) {
        _log('missing required field=preferences');
      }
      return null;
    }

    return GeminiPlanningInput(
      id: detail.id,
      destination: destination,
      placeId: placeId.isEmpty ? null : placeId,
      latitude: latitude,
      longitude: longitude,
      departureCity: departureCity,
      startDate: startDate,
      endDate: endDate,
      tripDays: tripDays,
      nightCount: nightCount,
      travelerCount: travelerCount,
      totalBudget: totalBudget,
      currency: currency,
      currencySymbol: _resolveCurrencySymbol(
        currency: detail.currency,
        currencySymbol: detail.currencySymbol,
      ),
      preferences: detail.preferences,
      pace: pace,
      accommodationPreference: accommodationPreference,
    );
  }

  Future<List<ChecklistDetailItem>> _buildGeneratedItems({
    required ChecklistDetail detail,
    required GeminiPlanningInput input,
    required GeminiGeneratedPlan generatedPlan,
    required ChecklistPlanCancelChecker? shouldCancel,
    required void Function(
      ChecklistPlanProgressStep step,
      double progressPercent, {
      int? currentItemIndex,
      int? totalItemCount,
      bool hasPartialFailures,
      String? errorCode,
      String? errorDetail,
      String? debugMessage,
    })
    onProgress,
  }) async {
    void throwIfCancelled() {
      if (shouldCancel?.call() ?? false) {
        throw AppException('checklist_generate_cancelled');
      }
    }

    final items = <ChecklistDetailItem>[];
    var flightItemCount = 0;
    throwIfCancelled();
    onProgress(
      ChecklistPlanProgressStep.findingFlightSuggestions,
      0.46,
      debugMessage: 'finding_flight_suggestions',
    );
    final flightItems = _buildFlightItems(
      input: input,
      flights: generatedPlan.flights,
    );
    if (flightItems.$1 != null) {
      items.add(flightItems.$1!);
      flightItemCount += 1;
    }
    throwIfCancelled();

    final hotelItems = await _buildHotelItems(
      input: input,
      candidates: generatedPlan.hotelCandidates,
      startingOrder: items.length,
      shouldCancel: shouldCancel,
      onProgress: onProgress,
    );
    items.addAll(hotelItems);
    throwIfCancelled();

    final restaurantItems = await _buildPlaceItems(
      input: input,
      queries: generatedPlan.restaurantQueries,
      type: 'restaurant',
      groupType: 'food',
      startingOrder: items.length,
      shouldCancel: shouldCancel,
      onProgress: onProgress,
    );
    items.addAll(restaurantItems);
    throwIfCancelled();

    final activityItems = await _buildPlaceItems(
      input: input,
      queries: generatedPlan.activityQueries,
      type: 'activity',
      groupType: 'activity',
      startingOrder: items.length,
      shouldCancel: shouldCancel,
      onProgress: onProgress,
    );
    items.addAll(activityItems);
    if (flightItems.$2 != null) {
      items.add(
        flightItems.$2!.copyWith(
          displayOrder: items.length,
          dayIndex: input.tripDays,
        ),
      );
      flightItemCount += 1;
    }

    _log('flight item count=$flightItemCount');
    _log('hotel item count=${hotelItems.length}');
    _log('restaurant item count=${restaurantItems.length}');
    _log('activity item count=${activityItems.length}');
    _log('total items count=${items.length}');
    for (final item in items) {
      _log(
        'item type=${item.type ?? ''} groupType=${item.groupType} '
        'title=${item.title} dayIndex=${item.dayIndex} '
        'displayOrder=${item.displayOrder}',
      );
    }

    return items;
  }

  (ChecklistDetailItem?, ChecklistDetailItem?) _buildFlightItems({
    required GeminiPlanningInput input,
    required List<GeminiFlightPlan> flights,
  }) {
    // 固定双航段：第一张出发航班，最后一张返程航班。
    GeminiFlightPlan? outboundPlan;
    GeminiFlightPlan? returnPlan;
    for (final flight in flights) {
      final direction = flight.tripDirection.trim().toLowerCase();
      if (direction == 'outbound' && outboundPlan == null) {
        outboundPlan = flight;
      } else if (direction == 'return' && returnPlan == null) {
        returnPlan = flight;
      }
    }
    if (outboundPlan == null && flights.isNotEmpty) {
      outboundPlan = flights.first;
    }
    if (returnPlan == null && flights.length > 1) {
      returnPlan = flights.last;
    }

    final resolvedOutbound = _fillFlightPlanFallback(
      input: input,
      tripDirection: 'outbound',
      flight: outboundPlan,
    );
    final resolvedReturn = _fillFlightPlanFallback(
      input: input,
      tripDirection: 'return',
      flight: returnPlan,
    );

    final outboundItem = _buildFlightItemFromPlan(
      input: input,
      flight: resolvedOutbound,
      displayOrder: 0,
      dayIndex: 1,
    );
    final returnItem = _buildFlightItemFromPlan(
      input: input,
      flight: resolvedReturn,
      displayOrder: 9999,
      dayIndex: input.tripDays,
    );

    return (outboundItem, returnItem);
  }

  Future<List<ChecklistDetailItem>> _buildHotelItems({
    required GeminiPlanningInput input,
    required List<GeminiHotelCandidate> candidates,
    required int startingOrder,
    required ChecklistPlanCancelChecker? shouldCancel,
    required void Function(
      ChecklistPlanProgressStep step,
      double progressPercent, {
      int? currentItemIndex,
      int? totalItemCount,
      bool hasPartialFailures,
      String? errorCode,
      String? errorDetail,
      String? debugMessage,
    })
    onProgress,
  }) async {
    void throwIfCancelled() {
      if (shouldCancel?.call() ?? false) {
        throw AppException('checklist_generate_cancelled');
      }
    }

    final items = <ChecklistDetailItem>[];
    final scopedCandidates = candidates.take(3).toList(growable: false);
    final total = scopedCandidates.length;
    if (total > 0) {
      onProgress(
        ChecklistPlanProgressStep.findingHotels,
        0.55,
        currentItemIndex: 0,
        totalItemCount: total,
        debugMessage: 'finding_hotels_started',
      );
    }
    for (var index = 0; index < scopedCandidates.length; index++) {
      throwIfCancelled();
      final candidate = scopedCandidates[index];
      final current = index + 1;
      final stageProgress = 0.55 + (0.12 * current / total);
      debugPrint(
        '[ChecklistPlanProgress] enrich type=hotel index=$current total=$total',
      );
      onProgress(
        ChecklistPlanProgressStep.findingHotels,
        stageProgress,
        currentItemIndex: current,
        totalItemCount: total,
        debugMessage: 'finding_hotels_progress',
      );
      final order = startingOrder + items.length;
      final fallbackItem = _buildFallbackHotelItem(
        input: input,
        candidate: candidate,
        order: order,
      );
      try {
        throwIfCancelled();
        final place = await googlePlacesRemoteDataSource.searchHotelByName(
          hotelName: candidate.name,
          destination: input.destination,
          latitude: input.latitude,
          longitude: input.longitude,
        );
        throwIfCancelled();
        if (place == null || place.placeId.trim().isEmpty) {
          _log('hotel enrich skipped name=${candidate.name}');
          items.add(fallbackItem);
          onProgress(
            ChecklistPlanProgressStep.findingHotels,
            stageProgress,
            currentItemIndex: current,
            totalItemCount: total,
            hasPartialFailures: true,
            errorCode: 'partial_enrich',
            debugMessage: 'hotel_partial_enrich_continue',
          );
          continue;
        }

        items.add(
          fallbackItem.copyWith(
            title: place.name,
            subtitle: place.address,
            providerName: 'Google Places',
            externalUrl: place.googleMapsUrl,
            dataSource: 'gemini_google_places',
            googlePlaceId: place.placeId,
            address: place.address,
            photoUrl: place.photoUrl,
            latitude: place.latitude,
            longitude: place.longitude,
            rating: place.rating,
            googleMapsUrl: place.googleMapsUrl,
          ),
        );
      } catch (error) {
        _log('hotel enrich failed name=${candidate.name} error=$error');
        items.add(fallbackItem);
        onProgress(
          ChecklistPlanProgressStep.findingHotels,
          stageProgress,
          currentItemIndex: current,
          totalItemCount: total,
          hasPartialFailures: true,
          errorCode: 'partial_enrich',
          debugMessage: 'hotel_partial_enrich_continue',
        );
      }
    }
    _log('hotel deduped count=${items.length}');
    _log('hotel final kept count=${items.length}');
    return items;
  }

  Future<List<ChecklistDetailItem>> _buildPlaceItems({
    required GeminiPlanningInput input,
    required List<GeminiPlaceQuery> queries,
    required String type,
    required String groupType,
    required int startingOrder,
    required ChecklistPlanCancelChecker? shouldCancel,
    required void Function(
      ChecklistPlanProgressStep step,
      double progressPercent, {
      int? currentItemIndex,
      int? totalItemCount,
      bool hasPartialFailures,
      String? errorCode,
      String? errorDetail,
      String? debugMessage,
    })
    onProgress,
  }) async {
    void throwIfCancelled() {
      if (shouldCancel?.call() ?? false) {
        throw AppException('checklist_generate_cancelled');
      }
    }

    throwIfCancelled();
    if (queries.isEmpty) {
      _log('$type query list empty');
      return const <ChecklistDetailItem>[];
    }

    final dayIndexes = _buildEvenDayIndexes(
      totalCount: queries.length,
      tripDays: input.tripDays,
    );
    final seenPlaceIds = <String>{};
    final items = <ChecklistDetailItem>[];
    final progressStep = type == 'restaurant'
        ? ChecklistPlanProgressStep.findingRestaurants
        : ChecklistPlanProgressStep.findingActivities;
    final progressStart = type == 'restaurant' ? 0.68 : 0.82;
    final progressSpan = type == 'restaurant' ? 0.12 : 0.08;
    onProgress(
      progressStep,
      progressStart,
      currentItemIndex: 0,
      totalItemCount: queries.length,
      debugMessage: 'finding_${type}s_started',
    );

    for (var index = 0; index < queries.length; index++) {
      throwIfCancelled();
      final query = queries[index];
      final current = index + 1;
      final stageProgress =
          progressStart + (progressSpan * current / queries.length);
      debugPrint(
        '[ChecklistPlanProgress] enrich type=$type index=$current total=${queries.length}',
      );
      onProgress(
        progressStep,
        stageProgress,
        currentItemIndex: current,
        totalItemCount: queries.length,
        debugMessage: 'finding_${type}s_progress',
      );
      final order = startingOrder + items.length;
      final resolvedDayIndex = _resolveDayIndex(
        rawDayIndex: query.dayIndex,
        fallbackDayIndex: dayIndexes[index],
        tripDays: input.tripDays,
      );
      final fallbackItem = _buildFallbackSearchItem(
        input: input,
        query: query,
        type: type,
        groupType: groupType,
        order: order,
        dayIndex: resolvedDayIndex,
      );
      try {
        throwIfCancelled();
        final places = await googlePlacesRemoteDataSource.searchPlacesByText(
          query: query.query,
          type: type,
          latitude: input.latitude,
          longitude: input.longitude,
          limit: 1,
        );
        throwIfCancelled();
        if (places.isEmpty) {
          _log('$type query returned 0 results query=${query.query}');
          items.add(fallbackItem);
          onProgress(
            progressStep,
            stageProgress,
            currentItemIndex: current,
            totalItemCount: queries.length,
            hasPartialFailures: true,
            errorCode: 'partial_enrich',
            debugMessage: '${type}_partial_enrich_continue',
          );
          continue;
        }

        final place = places.first;
        final placeId = place.placeId.trim();
        if (placeId.isEmpty || seenPlaceIds.contains(placeId)) {
          _log(
            '$type query skipped duplicateOrEmpty placeId=$placeId query=${query.query}',
          );
          items.add(fallbackItem);
          onProgress(
            progressStep,
            stageProgress,
            currentItemIndex: current,
            totalItemCount: queries.length,
            hasPartialFailures: true,
            errorCode: 'partial_enrich',
            debugMessage: '${type}_partial_enrich_continue',
          );
          continue;
        }
        seenPlaceIds.add(placeId);

        items.add(
          fallbackItem.copyWith(
            title: place.name,
            subtitle: place.address,
            providerName: 'Google Places',
            externalUrl: place.googleMapsUrl,
            dataSource: 'google_places',
            googlePlaceId: placeId,
            address: place.address,
            photoUrl: place.photoUrl,
            latitude: place.latitude,
            longitude: place.longitude,
            rating: place.rating,
            googleMapsUrl: place.googleMapsUrl,
          ),
        );
      } catch (error) {
        _log('$type enrich failed query=${query.query} error=$error');
        items.add(fallbackItem);
        onProgress(
          progressStep,
          stageProgress,
          currentItemIndex: current,
          totalItemCount: queries.length,
          hasPartialFailures: true,
          errorCode: 'partial_enrich',
          debugMessage: '${type}_partial_enrich_continue',
        );
      }
    }

    _log('$type deduped count=${seenPlaceIds.length}');
    _log('$type final kept count=${items.length}');

    return items;
  }

  ChecklistDetailItem _buildFallbackHotelItem({
    required GeminiPlanningInput input,
    required GeminiHotelCandidate candidate,
    required int order,
  }) {
    final nightlyRange = _normalizeHotelCandidatePriceRange(
      candidate: candidate,
      nightCount: input.nightCount,
    );
    return ChecklistDetailItem(
      id: _buildItemId(prefix: 'hotel', order: order),
      groupType: 'stay',
      title: candidate.name,
      subtitle: candidate.matchPreference,
      isCompleted: false,
      type: 'hotel',
      estimatedCostMin: nightlyRange.$1,
      estimatedCostMax: nightlyRange.$2,
      originalPriceMin: candidate.expectedCostMin,
      originalPriceMax: candidate.expectedCostMax,
      originalCurrency: input.currency,
      costUnit: 'per_night',
      currency: input.currency,
      routeText: _joinNonEmptyText(<String?>[
        candidate.reason,
        candidate.matchPreference,
      ], separator: ' · '),
      providerName: 'Google Places',
      dataSource: 'gemini',
      status: 'suggested',
      displayOrder: order,
      dayIndex: 0,
      budgetWarning: candidate.budgetWarning,
    );
  }

  ChecklistDetailItem _buildFallbackSearchItem({
    required GeminiPlanningInput input,
    required GeminiPlaceQuery query,
    required String type,
    required String groupType,
    required int order,
    required int dayIndex,
  }) {
    final normalizedPrice = _normalizePlaceQueryPriceRange(
      query: query,
      type: type,
      travelerCount: input.travelerCount,
    );
    return ChecklistDetailItem(
      id: _buildItemId(prefix: type, order: order),
      groupType: groupType,
      title: query.query,
      subtitle: null,
      isCompleted: false,
      type: type,
      estimatedCostMin: normalizedPrice.$1,
      estimatedCostMax: normalizedPrice.$2,
      originalPriceMin: query.estimatedCostMin,
      originalPriceMax: query.estimatedCostMax,
      originalCurrency: input.currency,
      costUnit: normalizedPrice.$3,
      currency: input.currency,
      routeText: query.query,
      providerName: 'Google Places',
      dataSource: 'gemini',
      status: 'suggested',
      displayOrder: order,
      dayIndex: dayIndex,
    );
  }

  List<ChecklistDetailItem> _normalizeAndValidateGeneratedItems({
    required GeminiPlanningInput input,
    required ChecklistBudgetSplit budgetSplit,
    required List<ChecklistDetailItem> items,
  }) {
    final hotelBudget = budgetSplit.hotelBudget;
    final maxHotelNightlyBudget = hotelBudget != null && input.nightCount > 0
        ? hotelBudget / input.nightCount
        : null;

    return items
        .map(
          (item) => _normalizeAndValidateGeneratedItem(
            input: input,
            hotelBudget: hotelBudget,
            maxHotelNightlyBudget: maxHotelNightlyBudget,
            item: item,
          ),
        )
        .toList(growable: false);
  }

  ChecklistDetailItem _normalizeAndValidateGeneratedItem({
    required GeminiPlanningInput input,
    required double? hotelBudget,
    required double? maxHotelNightlyBudget,
    required ChecklistDetailItem item,
  }) {
    final normalizedType = (item.type ?? '').trim().toLowerCase();
    final normalizedGroup = item.groupType.trim().toLowerCase();
    final isHotel = normalizedType == 'hotel' || normalizedGroup == 'stay';
    final isRestaurant =
        normalizedType == 'restaurant' ||
        normalizedType == 'food' ||
        normalizedGroup == 'food';
    final isActivity =
        normalizedType == 'activity' || normalizedGroup == 'activity';
    final isFlight =
        normalizedType == 'flight' || normalizedGroup == 'transportation';

    var nextItem = item.copyWith(currency: input.currency);
    var min = nextItem.estimatedCostMin;
    var max = nextItem.estimatedCostMax;
    var costUnit = (nextItem.costUnit ?? '').trim().toLowerCase();
    String? budgetWarning = nextItem.budgetWarning;

    if (isFlight) {
      costUnit = 'per_ticket';
    } else if (isHotel) {
      if (costUnit == 'total' && input.nightCount > 0) {
        min = min == null ? null : min / input.nightCount;
        max = max == null ? null : max / input.nightCount;
      }
      costUnit = 'per_night';
    } else if (isRestaurant) {
      if (costUnit == 'total' && input.travelerCount > 0) {
        min = min == null ? null : min / input.travelerCount;
        max = max == null ? null : max / input.travelerCount;
      }
      costUnit = 'per_person';
    } else if (isActivity) {
      final average = _readAverageAmount(min: min, max: max);
      if ((average ?? 0) <= 0) {
        min = 0;
        max = 0;
        costUnit = 'total';
      } else {
        if (costUnit == 'total' && input.travelerCount > 0) {
          min = min == null ? null : min / input.travelerCount;
          max = max == null ? null : max / input.travelerCount;
        }
        costUnit = 'per_person';
      }
    }

    final isSuspiciousPriceUnit = _isSuspiciousPriceUnit(
      currency: input.currency,
      type: normalizedType,
      min: min,
      max: max,
      maxHotelNightlyBudget: maxHotelNightlyBudget,
    );

    if (isSuspiciousPriceUnit) {
      final fallbackRange = _buildFallbackPriceRange(
        input: input,
        item: nextItem,
        hotelBudget: hotelBudget,
        maxHotelNightlyBudget: maxHotelNightlyBudget,
      );
      min = fallbackRange.$1;
      max = fallbackRange.$2;
      budgetWarning = _mergeWarning(budgetWarning, 'suspicious_price_unit');
    }

    final isWithinBudget =
        !isHotel ||
        maxHotelNightlyBudget == null ||
        max == null ||
        max <= maxHotelNightlyBudget * 1.15;
    if (isHotel && !isWithinBudget) {
      budgetWarning = _mergeWarning(budgetWarning, 'over_budget');
      if (maxHotelNightlyBudget > 0) {
        final fallbackMin = maxHotelNightlyBudget * 0.82;
        final fallbackMax = maxHotelNightlyBudget * 0.98;
        min = fallbackMin;
        max = fallbackMax;
      }
    }

    _log(
      'price validation title=${nextItem.title} '
      'type=${nextItem.type ?? ''} '
      'currency=${input.currency} '
      'costUnit=$costUnit '
      'estimatedCostMin=$min '
      'estimatedCostMax=$max '
      'hotelBudget=$hotelBudget '
      'nightCount=${input.nightCount} '
      'maxHotelNightlyBudget=$maxHotelNightlyBudget '
      'isWithinBudget=$isWithinBudget',
    );

    return nextItem.copyWith(
      currency: input.currency,
      originalCurrency: nextItem.originalCurrency ?? nextItem.currency,
      originalPriceMin: nextItem.originalPriceMin ?? nextItem.estimatedCostMin,
      originalPriceMax: nextItem.originalPriceMax ?? nextItem.estimatedCostMax,
      estimatedCostMin: min,
      estimatedCostMax: max,
      estimatedPriceMin: isFlight ? min : nextItem.estimatedPriceMin,
      estimatedPriceMax: isFlight ? max : nextItem.estimatedPriceMax,
      costUnit: costUnit,
      budgetWarning: budgetWarning,
    );
  }

  bool _isSuspiciousPriceUnit({
    required String currency,
    required String type,
    required double? min,
    required double? max,
    required double? maxHotelNightlyBudget,
  }) {
    if (currency.trim().toUpperCase() != 'CNY') {
      return false;
    }
    final average = _readAverageAmount(min: min, max: max);
    if (average == null) {
      return false;
    }
    switch (type) {
      case 'hotel':
        if (average <= 0) {
          return false;
        }
        if (average < 60) {
          return true;
        }
        final limit = maxHotelNightlyBudget == null
            ? 8000
            : (maxHotelNightlyBudget * 2.8).clamp(8000, 30000).toDouble();
        return average > limit;
      case 'restaurant':
      case 'food':
        return average > 1500;
      case 'activity':
        return average > 5000;
      default:
        return false;
    }
  }

  (double?, double?) _buildFallbackPriceRange({
    required GeminiPlanningInput input,
    required ChecklistDetailItem item,
    required double? hotelBudget,
    required double? maxHotelNightlyBudget,
  }) {
    final normalizedType = (item.type ?? '').trim().toLowerCase();
    final normalizedGroup = item.groupType.trim().toLowerCase();
    if (normalizedType == 'hotel' || normalizedGroup == 'stay') {
      final nightlyBudget =
          maxHotelNightlyBudget ??
          ((hotelBudget ?? 0) > 0 && input.nightCount > 0
              ? hotelBudget! / input.nightCount
              : null);
      if (nightlyBudget != null && nightlyBudget > 0) {
        return (nightlyBudget * 0.72, nightlyBudget * 0.92);
      }
      return (480, 920);
    }
    if (normalizedType == 'restaurant' ||
        normalizedType == 'food' ||
        normalizedGroup == 'food') {
      switch (input.accommodationPreference.trim().toLowerCase()) {
        case 'luxury':
          return (220, 480);
        case 'budget':
          return (45, 120);
        default:
          return (80, 220);
      }
    }
    if (normalizedType == 'activity' || normalizedGroup == 'activity') {
      return (60, 260);
    }
    return (
      _readAverageAmount(
        min: item.estimatedCostMin,
        max: item.estimatedCostMax,
      ),
      item.estimatedCostMax,
    );
  }

  String _mergeWarning(String? current, String next) {
    final currentValue = (current ?? '').trim();
    if (currentValue.isEmpty) {
      return next;
    }
    if (currentValue.split('|').contains(next)) {
      return currentValue;
    }
    return '$currentValue|$next';
  }

  double? _readAverageAmount({required double? min, required double? max}) {
    if (min != null && max != null) {
      return (min + max) / 2;
    }
    return min ?? max;
  }

  (double?, double?) _normalizeHotelCandidatePriceRange({
    required GeminiHotelCandidate candidate,
    required int nightCount,
  }) {
    if (candidate.costUnit.trim().toLowerCase() != 'total' || nightCount <= 0) {
      return (candidate.expectedCostMin, candidate.expectedCostMax);
    }
    return (
      candidate.expectedCostMin == null
          ? null
          : candidate.expectedCostMin! / nightCount,
      candidate.expectedCostMax == null
          ? null
          : candidate.expectedCostMax! / nightCount,
    );
  }

  (double?, double?, String) _normalizePlaceQueryPriceRange({
    required GeminiPlaceQuery query,
    required String type,
    required int travelerCount,
  }) {
    final normalizedType = type.trim().toLowerCase();
    if (normalizedType == 'restaurant') {
      if (query.costUnit.trim().toLowerCase() == 'total' && travelerCount > 0) {
        return (
          query.estimatedCostMin == null
              ? null
              : query.estimatedCostMin! / travelerCount,
          query.estimatedCostMax == null
              ? null
              : query.estimatedCostMax! / travelerCount,
          'per_person',
        );
      }
      return (query.estimatedCostMin, query.estimatedCostMax, 'per_person');
    }

    final average = _readAverageAmount(
      min: query.estimatedCostMin,
      max: query.estimatedCostMax,
    );
    if ((average ?? 0) <= 0) {
      return (0, 0, 'total');
    }
    if (query.costUnit.trim().toLowerCase() == 'total' && travelerCount > 0) {
      return (
        query.estimatedCostMin == null
            ? null
            : query.estimatedCostMin! / travelerCount,
        query.estimatedCostMax == null
            ? null
            : query.estimatedCostMax! / travelerCount,
        'per_person',
      );
    }
    return (query.estimatedCostMin, query.estimatedCostMax, 'per_person');
  }

  List<int> _buildEvenDayIndexes({
    required int totalCount,
    required int tripDays,
  }) {
    if (totalCount <= 0 || tripDays <= 0) {
      return const <int>[];
    }
    return List<int>.generate(
      totalCount,
      (index) => ((index * tripDays) ~/ totalCount) + 1,
      growable: false,
    );
  }

  int _resolveDayIndex({
    required int? rawDayIndex,
    required int fallbackDayIndex,
    required int tripDays,
  }) {
    final candidate = rawDayIndex ?? fallbackDayIndex;
    if (candidate < 1) {
      return 1;
    }
    if (candidate > tripDays) {
      return tripDays;
    }
    return candidate;
  }

  Future<void> _updatePlanningStatus(
    DocumentReference<Map<String, dynamic>> checklistRef,
    String planningStatus,
  ) {
    _log('planningStatus changed -> $planningStatus');
    return checklistRef.set(<String, dynamic>{
      'planningStatus': planningStatus,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  String _buildItemId({required String prefix, required int order}) {
    return '${prefix}_${DateTime.now().microsecondsSinceEpoch}_$order';
  }

  ChecklistDetailItem _buildFlightItemFromPlan({
    required GeminiPlanningInput input,
    required GeminiFlightPlan flight,
    required int displayOrder,
    required int dayIndex,
  }) {
    final airlineName = flight.airlineName?.trim() ?? '';
    final flightNumber = flight.flightNumber?.trim() ?? '';
    final departureAirportDisplay = _composeAirportDisplay(
      airportName: flight.departureAirportName,
      airportCode: flight.departureAirportCode,
      terminal: flight.departureTerminal,
    );
    final arrivalAirportDisplay = _composeAirportDisplay(
      airportName: flight.arrivalAirportName,
      airportCode: flight.arrivalAirportCode,
      terminal: flight.arrivalTerminal,
    );
    final fallbackUrl = _buildGoogleFlightsSearchUrl(
      input: input,
      tripDirection: flight.tripDirection,
    );
    final routeText = _joinNonEmptyText(<String?>[
      _joinNonEmptyText(<String?>[
        flight.departureDate,
        flight.departureTime,
      ], separator: ' '),
      _joinNonEmptyText(<String?>[
        departureAirportDisplay,
        arrivalAirportDisplay,
      ], separator: ' -> '),
      flight.arrivalTime,
    ], separator: ' · ');
    final estimatedCostMin =
        flight.estimatedCostMin ??
        (flight.estimatedPrice == null ? null : flight.estimatedPrice! * 0.95);
    final estimatedCostMax =
        flight.estimatedCostMax ??
        (flight.estimatedPrice == null ? null : flight.estimatedPrice! * 1.05);

    return ChecklistDetailItem(
      id: _buildItemId(prefix: 'flight', order: displayOrder),
      groupType: 'transportation',
      title: airlineName,
      subtitle: flightNumber.isNotEmpty ? flightNumber : null,
      isCompleted: false,
      type: 'flight',
      estimatedPriceMin: estimatedCostMin,
      estimatedPriceMax: estimatedCostMax,
      estimatedCostMin: estimatedCostMin,
      estimatedCostMax: estimatedCostMax,
      costUnit: 'per_ticket',
      currency: flight.currency,
      routeText: routeText,
      suggestedAirports: <String>[
        if ((flight.departureAirportCode ?? '').trim().isNotEmpty)
          flight.departureAirportCode!.trim(),
        if ((flight.arrivalAirportCode ?? '').trim().isNotEmpty)
          flight.arrivalAirportCode!.trim(),
      ],
      providerName: 'Google Flights',
      externalUrl: (flight.googleFlightsUrl ?? '').trim().isNotEmpty
          ? flight.googleFlightsUrl!.trim()
          : fallbackUrl,
      dataSource: 'gemini',
      status: 'suggested',
      displayOrder: displayOrder,
      dayIndex: dayIndex,
      airline: airlineName,
      airlineCode: flight.airlineCode,
      flightNumber: flightNumber,
      departureAirport: departureAirportDisplay,
      arrivalAirport: arrivalAirportDisplay,
      departureTime: flight.departureTime,
      arrivalTime: flight.arrivalTime,
      departureDate: flight.departureDate,
      arrivalDate: flight.departureDate,
      tripDirection: flight.tripDirection,
      departureCity: flight.departureCity,
      arrivalCity: flight.arrivalCity,
      departureAirportName: flight.departureAirportName,
      departureAirportCode: flight.departureAirportCode,
      departureTerminal: flight.departureTerminal,
      arrivalAirportName: flight.arrivalAirportName,
      arrivalAirportCode: flight.arrivalAirportCode,
      arrivalTerminal: flight.arrivalTerminal,
      estimatedPrice: flight.estimatedPrice,
      googleFlightsUrl: (flight.googleFlightsUrl ?? '').trim().isNotEmpty
          ? flight.googleFlightsUrl!.trim()
          : fallbackUrl,
    );
  }

  GeminiFlightPlan _fillFlightPlanFallback({
    required GeminiPlanningInput input,
    required String tripDirection,
    required GeminiFlightPlan? flight,
  }) {
    // Gemini 字段缺失时做结构化补全，保证 flight 卡片稳定展示。
    final isOutbound = tripDirection == 'outbound';
    final departureCity = (flight?.departureCity ?? '').trim().isNotEmpty
        ? flight!.departureCity!.trim()
        : (isOutbound ? input.departureCity : input.destination);
    final arrivalCity = (flight?.arrivalCity ?? '').trim().isNotEmpty
        ? flight!.arrivalCity!.trim()
        : (isOutbound ? input.destination : input.departureCity);
    final departureAirportCode = (flight?.departureAirportCode ?? '').trim();
    final arrivalAirportCode = (flight?.arrivalAirportCode ?? '').trim();
    final estimatedPrice =
        flight?.estimatedPrice ??
        flight?.estimatedCostMin ??
        flight?.estimatedCostMax ??
        _fallbackEstimatedFlightPrice(input.totalBudget);

    return GeminiFlightPlan(
      tripDirection: tripDirection,
      airlineName: (flight?.airlineName ?? '').trim().isNotEmpty
          ? flight!.airlineName!.trim()
          : 'Sample Air',
      airlineCode: (flight?.airlineCode ?? '').trim().isNotEmpty
          ? flight!.airlineCode!.trim()
          : 'SA',
      flightNumber: (flight?.flightNumber ?? '').trim().isNotEmpty
          ? flight!.flightNumber!.trim()
          : (tripDirection == 'outbound' ? 'SA101' : 'SA202'),
      departureDate: (flight?.departureDate ?? '').trim().isNotEmpty
          ? flight!.departureDate!.trim()
          : _formatDate(isOutbound ? input.startDate : input.endDate),
      departureTime: _normalizeFlightTime(
        raw: flight?.departureTime,
        fallback: isOutbound ? '09:30' : '18:40',
      ),
      arrivalTime: _normalizeFlightTime(
        raw: flight?.arrivalTime,
        fallback: isOutbound ? '12:10' : '22:10',
      ),
      departureCity: departureCity,
      arrivalCity: arrivalCity,
      departureAirportName:
          (flight?.departureAirportName ?? '').trim().isNotEmpty
          ? flight!.departureAirportName!.trim()
          : '$departureCity International Airport',
      departureAirportCode: departureAirportCode.isNotEmpty
          ? departureAirportCode
          : _guessAirportCode(departureCity),
      departureTerminal: _normalizeTerminal(
        raw: flight?.departureTerminal,
        fallback: 'T1',
      ),
      arrivalAirportName: (flight?.arrivalAirportName ?? '').trim().isNotEmpty
          ? flight!.arrivalAirportName!.trim()
          : '$arrivalCity International Airport',
      arrivalAirportCode: arrivalAirportCode.isNotEmpty
          ? arrivalAirportCode
          : _guessAirportCode(arrivalCity),
      arrivalTerminal: _normalizeTerminal(
        raw: flight?.arrivalTerminal,
        fallback: 'T1',
      ),
      estimatedPrice: estimatedPrice,
      estimatedCostMin: flight?.estimatedCostMin,
      estimatedCostMax: flight?.estimatedCostMax,
      currency: (flight?.currency ?? '').trim().isNotEmpty
          ? flight!.currency.trim()
          : input.currency,
      googleFlightsUrl: (flight?.googleFlightsUrl ?? '').trim().isNotEmpty
          ? flight!.googleFlightsUrl!.trim()
          : _buildGoogleFlightsSearchUrl(
              input: input,
              tripDirection: tripDirection,
            ),
    );
  }

  String _composeAirportDisplay({
    required String? airportName,
    required String? airportCode,
    required String? terminal,
  }) {
    return _joinNonEmptyText(<String?>[
      airportName,
      _normalizeAirportCode(airportCode),
      _normalizeTerminal(raw: terminal),
    ]);
  }

  String _normalizeAirportCode(String? value) {
    final raw = (value ?? '').trim().toUpperCase();
    if (raw.isEmpty) {
      return '';
    }
    return raw.length >= 3 ? raw.substring(0, 3) : raw.padRight(3, 'X');
  }

  String _normalizeTerminal({String? raw, String fallback = 'T1'}) {
    final text = (raw ?? '').trim().toUpperCase();
    if (text.isEmpty) {
      return fallback;
    }
    if (text.startsWith('T')) {
      return text;
    }
    return 'T$text';
  }

  String _normalizeFlightTime({String? raw, required String fallback}) {
    final text = (raw ?? '').trim();
    if (RegExp(r'^\d{2}:\d{2}$').hasMatch(text)) {
      return text;
    }
    return fallback;
  }

  String _guessAirportCode(String city) {
    final normalized = city.replaceAll(RegExp(r'[^A-Za-z]'), '').toUpperCase();
    if (normalized.length >= 3) {
      return normalized.substring(0, 3);
    }
    return normalized.padRight(3, 'X');
  }

  double _fallbackEstimatedFlightPrice(double totalBudget) {
    final candidate = totalBudget * 0.18;
    if (candidate < 600) {
      return 600;
    }
    return candidate;
  }

  String _buildGoogleFlightsSearchUrl({
    required GeminiPlanningInput input,
    required String tripDirection,
  }) {
    final isOutbound = tripDirection.trim().toLowerCase() != 'return';
    final fromCity = isOutbound ? input.departureCity : input.destination;
    final toCity = isOutbound ? input.destination : input.departureCity;
    final departDate = _formatDate(
      isOutbound ? input.startDate : input.endDate,
    );
    final query = _joinNonEmptyText(<String>[
      'Flights',
      'from',
      fromCity,
      'to',
      toCity,
      'departing',
      departDate,
    ], separator: ' ');
    return Uri.https('www.google.com', '/travel/flights', <String, String>{
      'q': query,
    }).toString();
  }

  String _formatDate(DateTime value) {
    final year = value.year.toString().padLeft(4, '0');
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  String _joinNonEmptyText(Iterable<String?> parts, {String separator = ' '}) {
    return parts
        .map((item) => item?.trim() ?? '')
        .where((item) => item.isNotEmpty)
        .join(separator);
  }

  String _resolveCurrencySymbol({
    required String? currency,
    required String? currencySymbol,
  }) {
    final trimmedSymbol = currencySymbol?.trim() ?? '';
    if (trimmedSymbol.isNotEmpty) {
      return trimmedSymbol;
    }

    switch ((currency ?? '').trim().toUpperCase()) {
      case 'USD':
        return '\$';
      case 'EUR':
        return '\u20AC';
      case 'GBP':
        return '\u00A3';
      case 'JPY':
      case 'CNY':
      default:
        return '\u00A5';
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
    final snapshot = _readDestinationSnapshot(data);
    final snapshotName = snapshot?.name.trim() ?? '';
    final snapshotImage = snapshot?.coverImageUrl?.trim() ?? '';
    final destinationNames = _readDestinationNames(data);
    return ChecklistItem(
      id: id,
      destination: snapshotName.isNotEmpty
          ? snapshotName
          : (data['destination'] as String?)?.trim() ?? '',
      placeId: (data['placeId'] as String?)?.trim(),
      coverImageUrl: snapshotImage.isNotEmpty
          ? snapshotImage
          : (data['coverImageUrl'] as String?)?.trim() ?? '',
      destinationNames: destinationNames,
      destinationSourceType: (data['destinationSourceType'] as String?)?.trim(),
      destinationSnapshot: snapshot,
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
    final snapshot = _readDestinationSnapshot(data);
    final snapshotName = snapshot?.name.trim() ?? '';
    return ChecklistDetail(
      id: id,
      destination: snapshotName.isNotEmpty
          ? snapshotName
          : (data['destination'] as String?)?.trim() ?? '',
      placeId: (data['placeId'] as String?)?.trim(),
      destinationSourceType: (data['destinationSourceType'] as String?)?.trim(),
      destinationSnapshot: snapshot,
      latitude:
          snapshot?.latitude ??
          _readDouble(data['latitude']) ??
          _readDouble(data['markerLatitude']),
      longitude:
          snapshot?.longitude ??
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
    if (detail.destinationSnapshot?.hasCoreData == true &&
        detail.resolvedLatitude != null &&
        detail.resolvedLongitude != null) {
      return detail;
    }

    final placeId = detail.placeId?.trim() ?? '';
    if (placeId.isEmpty || detail.destinationSnapshot?.hasCoreData == true) {
      return detail;
    }

    final placeSnapshot = await _loadOfficialPlaceSnapshot(
      placeId: placeId,
      fallbackName: detail.destination,
      fallbackCoverImageUrl: detail.resolvedCoverImageUrl,
    );
    if (placeSnapshot == null) {
      return detail;
    }

    return detail.copyWith(
      destinationSnapshot: placeSnapshot,
      destinationSourceType: ChecklistDestinationSourceType.official,
      latitude: placeSnapshot.latitude,
      longitude: placeSnapshot.longitude,
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

  Future<String> _createChecklistDocument({
    required String? placeId,
    required String destination,
    required String? coverImageUrl,
    required Map<String, String> destinationNames,
    required String destinationSourceType,
    required ChecklistDestinationSnapshot destinationSnapshot,
  }) async {
    final userId = firebaseAuth.currentUser?.uid;
    if (userId == null || userId.trim().isEmpty) {
      throw AppException('checklist_create_failed');
    }

    final trimmedPlaceId = placeId?.trim();
    final trimmedDestination = destination.trim();
    final trimmedCoverImageUrl = coverImageUrl?.trim() ?? '';
    final sanitizedDestinationNames = _sanitizeDestinationNames(
      destinationNames,
    );
    final ref = firestore
        .collection('users')
        .doc(userId)
        .collection('checklists')
        .doc();

    await ref.set(<String, dynamic>{
      'placeId': (trimmedPlaceId?.isNotEmpty ?? false) ? trimmedPlaceId : null,
      'destination': trimmedDestination,
      'coverImageUrl': trimmedCoverImageUrl,
      'destinationNames': sanitizedDestinationNames,
      'destinationSourceType': destinationSourceType,
      'destinationSnapshot': _toDestinationSnapshotJson(destinationSnapshot),
      'createdAt': FieldValue.serverTimestamp(),
      'basicInfoCompleted': false,
      'planningStatus': 'collecting',
      'totalBudget': null,
      'aiGenerated': false,
    });

    return ref.id;
  }

  Future<ChecklistDestinationSnapshot> _buildOfficialDestinationSnapshot({
    required String placeId,
    required String destination,
    String? coverImageUrl,
  }) async {
    final doc = await firestore.collection('places').doc(placeId).get();
    final data = doc.data();
    final latitude = data == null
        ? null
        : _readDouble(data['latitude']) ?? _readDouble(data['markerLatitude']);
    final longitude = data == null
        ? null
        : _readDouble(data['longitude']) ??
              _readDouble(data['markerLongitude']);
    final fallbackImage = data == null
        ? null
        : (data['coverImage'] as String?)?.trim() ??
              (data['previewAssetPath'] as String?)?.trim();

    return ChecklistDestinationSnapshot(
      name: destination.trim(),
      latitude: latitude ?? 0,
      longitude: longitude ?? 0,
      coverImageUrl: coverImageUrl?.trim().isNotEmpty == true
          ? coverImageUrl?.trim()
          : fallbackImage,
      provider: ChecklistDestinationSourceType.official,
      providerPlaceId: placeId.trim().isEmpty ? null : placeId.trim(),
      placeLevel: 'city',
      country: null,
      region: null,
    );
  }

  Future<Map<String, String>> _loadOfficialDestinationNames({
    required String placeId,
    required String fallbackName,
  }) async {
    final doc = await firestore.collection('places').doc(placeId).get();
    final data = doc.data();
    if (data == null) {
      return _buildFallbackDestinationNames(fallbackName);
    }

    final names = _readLocalizedNamesMap(data['name']);
    if (names.isNotEmpty) {
      return names;
    }
    return _buildFallbackDestinationNames(fallbackName);
  }

  Map<String, String> _buildFallbackDestinationNames(String fallbackName) {
    final trimmed = fallbackName.trim();
    if (trimmed.isEmpty) {
      return const <String, String>{};
    }
    return <String, String>{'en': trimmed};
  }

  Map<String, String> _sanitizeDestinationNames(Map<String, String> input) {
    final result = <String, String>{};
    for (final entry in input.entries) {
      final key = entry.key.trim().toLowerCase();
      final value = entry.value.trim();
      if (value.isEmpty) {
        continue;
      }
      if (key.startsWith('zh')) {
        result['zh'] = value;
      } else if (key.startsWith('en')) {
        result['en'] = value;
      }
    }
    return result;
  }

  ChecklistDestinationSnapshot? _readDestinationSnapshot(
    Map<String, dynamic> data,
  ) {
    final raw = data['destinationSnapshot'];
    if (raw is Map) {
      final name = (raw['name'] as String?)?.trim() ?? '';
      final latitude = _readDouble(raw['latitude']);
      final longitude = _readDouble(raw['longitude']);
      if (name.isNotEmpty && latitude != null && longitude != null) {
        return ChecklistDestinationSnapshot(
          name: name,
          latitude: latitude,
          longitude: longitude,
          coverImageUrl: (raw['coverImageUrl'] as String?)?.trim(),
          provider: (raw['provider'] as String?)?.trim().isNotEmpty == true
              ? (raw['provider'] as String).trim()
              : ChecklistDestinationSourceType.official,
          providerPlaceId: (raw['providerPlaceId'] as String?)?.trim(),
          placeLevel: (raw['placeLevel'] as String?)?.trim(),
          country: (raw['country'] as String?)?.trim(),
          region: (raw['region'] as String?)?.trim(),
        );
      }
    }

    // 兼容旧 schema：用旧字段反推最小快照，避免旧 checklist 崩溃。
    final legacyName = (data['destination'] as String?)?.trim() ?? '';
    final legacyLatitude =
        _readDouble(data['latitude']) ?? _readDouble(data['markerLatitude']);
    final legacyLongitude =
        _readDouble(data['longitude']) ?? _readDouble(data['markerLongitude']);
    final legacyPlaceId = (data['placeId'] as String?)?.trim();
    if (legacyName.isEmpty ||
        legacyLatitude == null ||
        legacyLongitude == null) {
      return null;
    }
    return ChecklistDestinationSnapshot(
      name: legacyName,
      latitude: legacyLatitude,
      longitude: legacyLongitude,
      coverImageUrl: (data['coverImageUrl'] as String?)?.trim(),
      provider: (legacyPlaceId?.isNotEmpty ?? false)
          ? ChecklistDestinationSourceType.official
          : ChecklistDestinationSourceType.mapbox,
      providerPlaceId: legacyPlaceId,
      placeLevel: null,
      country: null,
      region: null,
    );
  }

  Map<String, String> _readDestinationNames(Map<String, dynamic> data) {
    final fromDoc = _readLocalizedNamesMap(data['destinationNames']);
    if (fromDoc.isNotEmpty) {
      return fromDoc;
    }

    // 兼容旧数据：没有 destinationNames 时，用 destination 兜底一个默认语言值。
    final fallbackName = (data['destination'] as String?)?.trim() ?? '';
    if (fallbackName.isNotEmpty) {
      return <String, String>{'en': fallbackName};
    }
    return const <String, String>{};
  }

  Map<String, String> _readLocalizedNamesMap(Object? value) {
    if (value is! Map) {
      return const <String, String>{};
    }

    final result = <String, String>{};
    for (final entry in value.entries) {
      final key = entry.key.toString().trim().toLowerCase();
      final raw = entry.value;
      if (raw is! String) {
        continue;
      }
      final text = raw.trim();
      if (text.isEmpty) {
        continue;
      }
      if (key.startsWith('zh')) {
        result['zh'] = text;
      } else if (key.startsWith('en')) {
        result['en'] = text;
      }
    }
    return result;
  }

  Map<String, dynamic> _toDestinationSnapshotJson(
    ChecklistDestinationSnapshot snapshot,
  ) {
    return <String, dynamic>{
      'name': snapshot.name.trim(),
      'latitude': snapshot.latitude,
      'longitude': snapshot.longitude,
      'coverImageUrl': snapshot.coverImageUrl?.trim(),
      'provider': snapshot.provider.trim(),
      'providerPlaceId': snapshot.providerPlaceId?.trim(),
      'placeLevel': snapshot.placeLevel?.trim(),
      'country': snapshot.country?.trim(),
      'region': snapshot.region?.trim(),
    };
  }

  Future<ChecklistDestinationSnapshot?> _loadOfficialPlaceSnapshot({
    required String placeId,
    required String fallbackName,
    required String fallbackCoverImageUrl,
  }) async {
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

    final name =
        _readLanguageMapValue(data['name']) ??
        (data['destination'] as String?)?.trim() ??
        fallbackName.trim();
    final coverImage =
        (data['coverImage'] as String?)?.trim() ??
        (data['previewAssetPath'] as String?)?.trim() ??
        fallbackCoverImageUrl.trim();

    return ChecklistDestinationSnapshot(
      name: name,
      latitude: latitude,
      longitude: longitude,
      coverImageUrl: coverImage.isEmpty ? null : coverImage,
      provider: ChecklistDestinationSourceType.official,
      providerPlaceId: placeId,
      placeLevel: 'city',
      country: null,
      region: null,
    );
  }

  CollectionReference<Map<String, dynamic>> _resolveChecklistCollection() {
    final userId = firebaseAuth.currentUser?.uid;
    if (userId == null || userId.trim().isEmpty) {
      throw AppException('checklist_save_failed');
    }
    return firestore.collection('users').doc(userId).collection('checklists');
  }

  // 统计列表查询中是否夹带了 detail 级字段，便于定位首屏慢来源。
  ({
    int docsWithItems,
    int totalItems,
    int docsWithEssentials,
    int totalEssentials,
    int docsWithProTip,
    int docsWithBudgetSplit,
  })
  _summarizeChecklistPayload(
    Iterable<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    var docsWithItems = 0;
    var totalItems = 0;
    var docsWithEssentials = 0;
    var totalEssentials = 0;
    var docsWithProTip = 0;
    var docsWithBudgetSplit = 0;

    for (final doc in docs) {
      final data = doc.data();
      final itemCount = _readListLength(data['items']);
      final essentialsCount = _readListLength(data['essentials']);
      if (itemCount > 0) {
        docsWithItems++;
        totalItems += itemCount;
      }
      if (essentialsCount > 0) {
        docsWithEssentials++;
        totalEssentials += essentialsCount;
      }
      if (_hasProTipPayload(data)) {
        docsWithProTip++;
      }
      if (_hasBudgetSplitPayload(data)) {
        docsWithBudgetSplit++;
      }
    }

    return (
      docsWithItems: docsWithItems,
      totalItems: totalItems,
      docsWithEssentials: docsWithEssentials,
      totalEssentials: totalEssentials,
      docsWithProTip: docsWithProTip,
      docsWithBudgetSplit: docsWithBudgetSplit,
    );
  }

  int _readListLength(Object? value) {
    if (value is List) {
      return value.length;
    }
    return 0;
  }

  bool _hasProTipPayload(Map<String, dynamic> data) {
    final raw = data['proTip'];
    if (raw is Map && raw.isNotEmpty) {
      return true;
    }
    return ((data['tipTitle'] as String?)?.trim().isNotEmpty ?? false) ||
        ((data['tipDescription'] as String?)?.trim().isNotEmpty ?? false);
  }

  bool _hasBudgetSplitPayload(Map<String, dynamic> data) {
    final raw = data['budgetSplit'];
    if (raw is Map && raw.isNotEmpty) {
      return true;
    }
    return data['transportRatio'] != null ||
        data['stayRatio'] != null ||
        data['foodActivityRatio'] != null ||
        data['flightBudgetMax'] != null ||
        data['remainingBudget'] != null ||
        data['hotelBudget'] != null ||
        data['foodBudget'] != null ||
        data['activityBudget'] != null ||
        data['localTransportBudget'] != null ||
        data['bufferBudget'] != null ||
        ((data['budgetWarning'] as String?)?.trim().isNotEmpty ?? false);
  }

  String _maskUserId(String userId) {
    final trimmed = userId.trim();
    if (trimmed.length <= 6) {
      return '***';
    }
    return '${trimmed.substring(0, 3)}***${trimmed.substring(trimmed.length - 2)}';
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
          originalCurrency: (map['originalCurrency'] as String?)?.trim(),
          originalPriceMin: _readDouble(map['originalPriceMin']),
          originalPriceMax: _readDouble(map['originalPriceMax']),
          routeText: (map['routeText'] as String?)?.trim(),
          suggestedAirports: _readStringList(map['suggestedAirports']),
          providerName: (map['providerName'] as String?)?.trim(),
          externalUrl: (map['externalUrl'] as String?)?.trim(),
          dataSource: (map['dataSource'] as String?)?.trim(),
          accuracyNote: (map['accuracyNote'] as String?)?.trim(),
          status: (map['status'] as String?)?.trim(),
          displayOrder: _readInt(map['displayOrder']),
          dayIndex: _readInt(map['dayIndex']),
          budgetWarning: (map['budgetWarning'] as String?)?.trim(),
          googlePlaceId:
              (map['googlePlaceId'] as String?)?.trim() ??
              (map['placeId'] as String?)?.trim(),
          address: (map['address'] as String?)?.trim(),
          photoUrl: (map['photoUrl'] as String?)?.trim(),
          latitude: _readDouble(map['latitude']),
          longitude: _readDouble(map['longitude']),
          rating: _readDouble(map['rating']),
          googleMapsUrl: (map['googleMapsUrl'] as String?)?.trim(),
          airline: (map['airline'] as String?)?.trim(),
          flightNumber: (map['flightNumber'] as String?)?.trim(),
          departureAirport: (map['departureAirport'] as String?)?.trim(),
          arrivalAirport: (map['arrivalAirport'] as String?)?.trim(),
          departureTime: (map['departureTime'] as String?)?.trim(),
          arrivalTime: (map['arrivalTime'] as String?)?.trim(),
          departureDate: (map['departureDate'] as String?)?.trim(),
          arrivalDate: (map['arrivalDate'] as String?)?.trim(),
          tripDirection: (map['tripDirection'] as String?)?.trim(),
          airlineCode: (map['airlineCode'] as String?)?.trim(),
          departureCity: (map['departureCity'] as String?)?.trim(),
          arrivalCity: (map['arrivalCity'] as String?)?.trim(),
          departureAirportName: (map['departureAirportName'] as String?)
              ?.trim(),
          departureAirportCode: (map['departureAirportCode'] as String?)
              ?.trim(),
          departureTerminal: (map['departureTerminal'] as String?)?.trim(),
          arrivalAirportName: (map['arrivalAirportName'] as String?)?.trim(),
          arrivalAirportCode: (map['arrivalAirportCode'] as String?)?.trim(),
          arrivalTerminal: (map['arrivalTerminal'] as String?)?.trim(),
          estimatedPrice: _readDouble(map['estimatedPrice']),
          googleFlightsUrl: (map['googleFlightsUrl'] as String?)?.trim(),
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
      'originalCurrency': item.originalCurrency,
      'originalPriceMin': item.originalPriceMin,
      'originalPriceMax': item.originalPriceMax,
      'routeText': item.routeText,
      'suggestedAirports': item.suggestedAirports,
      'providerName': item.providerName,
      'externalUrl': item.externalUrl,
      'dataSource': item.dataSource,
      'accuracyNote': item.accuracyNote,
      'status': item.status,
      'displayOrder': item.displayOrder,
      'dayIndex': item.dayIndex,
      'budgetWarning': item.budgetWarning,
      'googlePlaceId': item.googlePlaceId,
      'address': item.address,
      'photoUrl': item.photoUrl,
      'latitude': item.latitude,
      'longitude': item.longitude,
      'rating': item.rating,
      'googleMapsUrl': item.googleMapsUrl,
      'airline': item.airline,
      'flightNumber': item.flightNumber,
      'departureAirport': item.departureAirport,
      'arrivalAirport': item.arrivalAirport,
      'departureTime': item.departureTime,
      'arrivalTime': item.arrivalTime,
      'departureDate': item.departureDate,
      'arrivalDate': item.arrivalDate,
      'tripDirection': item.tripDirection,
      'airlineCode': item.airlineCode,
      'departureCity': item.departureCity,
      'arrivalCity': item.arrivalCity,
      'departureAirportName': item.departureAirportName,
      'departureAirportCode': item.departureAirportCode,
      'departureTerminal': item.departureTerminal,
      'arrivalAirportName': item.arrivalAirportName,
      'arrivalAirportCode': item.arrivalAirportCode,
      'arrivalTerminal': item.arrivalTerminal,
      'estimatedPrice': item.estimatedPrice,
      'googleFlightsUrl': item.googleFlightsUrl,
    };
  }

  Map<String, dynamic>? _toProTipJson(ChecklistProTip? proTip) {
    if (proTip == null || proTip.isEmpty) {
      return null;
    }
    return <String, dynamic>{
      'tipTitle': proTip.tipTitle,
      'tipDescription': proTip.tipDescription,
    };
  }

  Map<String, dynamic> _toEssentialJson(ChecklistEssential essential) {
    return <String, dynamic>{
      'iconType': essential.iconType,
      'title': essential.title,
      'mainText': essential.mainText,
      'subText': essential.subText,
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
      originalCurrency: (data['originalCurrency'] as String?)?.trim(),
      originalPriceMin: _readDouble(data['originalPriceMin']),
      originalPriceMax: _readDouble(data['originalPriceMax']),
      routeText: (data['routeText'] as String?)?.trim(),
      suggestedAirports: _readStringList(data['suggestedAirports']),
      providerName: (data['providerName'] as String?)?.trim(),
      externalUrl: (data['externalUrl'] as String?)?.trim(),
      dataSource: (data['dataSource'] as String?)?.trim(),
      accuracyNote: (data['accuracyNote'] as String?)?.trim(),
      status: (data['status'] as String?)?.trim(),
      displayOrder: _readInt(data['displayOrder']),
      dayIndex: _readInt(data['dayIndex']),
      budgetWarning: (data['budgetWarning'] as String?)?.trim(),
      googlePlaceId:
          (data['googlePlaceId'] as String?)?.trim() ??
          (data['placeId'] as String?)?.trim(),
      address: (data['address'] as String?)?.trim(),
      photoUrl: (data['photoUrl'] as String?)?.trim(),
      latitude: _readDouble(data['latitude']),
      longitude: _readDouble(data['longitude']),
      rating: _readDouble(data['rating']),
      googleMapsUrl: (data['googleMapsUrl'] as String?)?.trim(),
      airline: (data['airline'] as String?)?.trim(),
      flightNumber: (data['flightNumber'] as String?)?.trim(),
      departureAirport: (data['departureAirport'] as String?)?.trim(),
      arrivalAirport: (data['arrivalAirport'] as String?)?.trim(),
      departureTime: (data['departureTime'] as String?)?.trim(),
      arrivalTime: (data['arrivalTime'] as String?)?.trim(),
      departureDate: (data['departureDate'] as String?)?.trim(),
      arrivalDate: (data['arrivalDate'] as String?)?.trim(),
      tripDirection: (data['tripDirection'] as String?)?.trim(),
      airlineCode: (data['airlineCode'] as String?)?.trim(),
      departureCity: (data['departureCity'] as String?)?.trim(),
      arrivalCity: (data['arrivalCity'] as String?)?.trim(),
      departureAirportName: (data['departureAirportName'] as String?)?.trim(),
      departureAirportCode: (data['departureAirportCode'] as String?)?.trim(),
      departureTerminal: (data['departureTerminal'] as String?)?.trim(),
      arrivalAirportName: (data['arrivalAirportName'] as String?)?.trim(),
      arrivalAirportCode: (data['arrivalAirportCode'] as String?)?.trim(),
      arrivalTerminal: (data['arrivalTerminal'] as String?)?.trim(),
      estimatedPrice: _readDouble(data['estimatedPrice']),
      googleFlightsUrl: (data['googleFlightsUrl'] as String?)?.trim(),
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

  String? _readLanguageMapValue(Object? value) {
    if (value is! Map) {
      return null;
    }

    for (final key in <String>['en', 'zh']) {
      final raw = value[key];
      if (raw is String && raw.trim().isNotEmpty) {
        return raw.trim();
      }
    }

    for (final entry in value.entries) {
      final raw = entry.value;
      if (raw is String && raw.trim().isNotEmpty) {
        return raw.trim();
      }
    }
    return null;
  }
}
