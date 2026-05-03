import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../../../core/config/checklist_debug_config.dart';
import '../../../../core/config/gemini_config.dart';
import '../../../../core/error/app_exception.dart';
import '../../domain/entities/checklist_detail.dart';

class GeminiPlanningRemoteDataSource {
  static const String _modelName = 'gemini-2.5-flash-lite';
  static const bool _enableGeminiSummaryLogs = kChecklistSummaryLogs;
  static const bool _enableGeminiDebugLogs = kChecklistVerboseLogs;
  static const int _maxRetryAttempts = 3;
  static const int _splitQueryTargetCount = 6;

  Future<GeminiGeneratedPlan> generatePlan({
    required GeminiPlanningInput input,
  }) async {
    final apiKey = geminiApiKey.trim();
    if (apiKey.isEmpty) {
      _summary('missing Gemini API key');
      throw AppException('gemini_api_key_missing');
    }
    final uri = Uri.https(
      'generativelanguage.googleapis.com',
      '/v1beta/models/$_modelName:generateContent',
      <String, String>{'key': apiKey},
    );
    final budgetHints = _buildBudgetHints(input);
    final promptA1 = _buildBudgetSplitPrompt(input);
    final promptA2 = _buildFlightSkeletonPrompt(input);
    final promptA3 = _buildHotelCandidatesPrompt(
      input: input,
      hints: budgetHints,
    );
    final promptB1 = _buildRestaurantQueriesPrompt(input);
    final promptB2 = _buildActivityQueriesPrompt(input);
    final promptB3 = _buildEssentialsTipPrompt(input);
    _debug('endpoint=generativelanguage.googleapis.com model=$_modelName');
    _debugLogRequestStart(
      input: input,
      promptA1: promptA1,
      promptA2: promptA2,
      promptA3: promptA3,
      promptB1: promptB1,
      promptB2: promptB2,
      promptB3: promptB3,
      hints: budgetHints,
    );
    _debug(
      'restaurantTargetCount=${input.restaurantTargetCount} '
      'activityTargetCount=${input.activityTargetCount} '
      'splitQueryTargetCount=$_splitQueryTargetCount '
      'groundingEnabled=false',
    );
    _summary(
      'started sections=A1,A2,A3,B1,B2,B3 '
      'promptLengths={A1:${promptA1.length},A2:${promptA2.length},A3:${promptA3.length},B1:${promptB1.length},B2:${promptB2.length},B3:${promptB3.length}}',
    );

    // 主计划拆为六段并发，尽量缩短首包耗时。
    final mainStopwatch = Stopwatch()..start();
    final results = await Future.wait<_SectionResult>(<Future<_SectionResult>>[
      _requestPlanSectionSafely(
        uri: uri,
        prompt: promptA1,
        label: 'A1_budget_split',
      ),
      _requestPlanSectionSafely(
        uri: uri,
        prompt: promptA2,
        label: 'A2_flight_skeleton',
      ),
      _requestPlanSectionSafely(
        uri: uri,
        prompt: promptA3,
        label: 'A3_hotel_candidates',
      ),
      _requestPlanSectionSafely(
        uri: uri,
        prompt: promptB1,
        label: 'B1_restaurant_queries',
      ),
      _requestPlanSectionSafely(
        uri: uri,
        prompt: promptB2,
        label: 'B2_activity_queries',
      ),
      _requestPlanSectionSafely(
        uri: uri,
        prompt: promptB3,
        label: 'B3_essentials_tip',
      ),
    ]);
    final byLabel = <String, _SectionResult>{
      for (final result in results) result.label: result,
    };
    final merged = _mergeSectionsWithFallback(
      input: input,
      hints: budgetHints,
      budgetSection: byLabel['A1_budget_split'],
      flightSection: byLabel['A2_flight_skeleton'],
      hotelSection: byLabel['A3_hotel_candidates'],
      restaurantSection: byLabel['B1_restaurant_queries'],
      activitySection: byLabel['B2_activity_queries'],
      essentialsSection: byLabel['B3_essentials_tip'],
    );
    final budgetElapsed = byLabel['A1_budget_split']?.elapsedMs ?? -1;
    final flightElapsed = byLabel['A2_flight_skeleton']?.elapsedMs ?? -1;
    final hotelElapsed = byLabel['A3_hotel_candidates']?.elapsedMs ?? -1;
    final restaurantElapsed = byLabel['B1_restaurant_queries']?.elapsedMs ?? -1;
    final activityElapsed = byLabel['B2_activity_queries']?.elapsedMs ?? -1;
    final essentialsElapsed = byLabel['B3_essentials_tip']?.elapsedMs ?? -1;
    _summary(
      'completed elapsed=${mainStopwatch.elapsedMilliseconds}ms '
      'counts flights=${(merged['flights'] as List?)?.length ?? 0} '
      'hotels=${(merged['hotelCandidates'] as List?)?.length ?? 0} '
      'restaurants=${(merged['restaurantQueries'] as List?)?.length ?? 0} '
      'activities=${(merged['activityQueries'] as List?)?.length ?? 0} '
      'essentials=${(merged['essentials'] as List?)?.length ?? 0}',
    );
    _debug(
      'main Gemini parallel elapsed=${mainStopwatch.elapsedMilliseconds}ms '
      'budgetElapsed=${budgetElapsed}ms '
      'flightElapsed=${flightElapsed}ms '
      'hotelElapsed=${hotelElapsed}ms '
      'restaurantElapsed=${restaurantElapsed}ms '
      'activityElapsed=${activityElapsed}ms '
      'essentialsElapsed=${essentialsElapsed}ms '
      'outputJsonLength=${jsonEncode(merged).length}',
    );
    _debug(
      'merge result flights=${(merged['flights'] as List?)?.length ?? 0} '
      'hotels=${(merged['hotelCandidates'] as List?)?.length ?? 0} '
      'restaurants=${(merged['restaurantQueries'] as List?)?.length ?? 0} '
      'activities=${(merged['activityQueries'] as List?)?.length ?? 0} '
      'essentials=${(merged['essentials'] as List?)?.length ?? 0}',
    );

    final generatedPlan = GeminiGeneratedPlan.fromJson(
      merged,
      defaultCurrency: input.currency,
      restaurantTargetCount: _splitQueryTargetCount,
      activityTargetCount: _splitQueryTargetCount,
    );
    _debugLogParsedPlan(
      input: input,
      parsed: merged,
      generatedPlan: generatedPlan,
    );
    return generatedPlan;
  }

  Future<_SectionResult> _requestPlanSectionSafely({
    required Uri uri,
    required String prompt,
    required String label,
  }) async {
    final stopwatch = Stopwatch()..start();
    try {
      final data = await _requestPlanSection(
        uri: uri,
        prompt: prompt,
        label: label,
      );
      _debug(
        'response label=$label elapsed=${stopwatch.elapsedMilliseconds}ms',
      );
      _summary(
        'section=$label elapsed=${stopwatch.elapsedMilliseconds}ms status=success',
      );
      return _SectionResult(
        label: label,
        data: data,
        elapsedMs: stopwatch.elapsedMilliseconds,
        isSuccess: true,
      );
    } catch (error) {
      _debug(
        'response label=$label elapsed=${stopwatch.elapsedMilliseconds}ms '
        'failed errorType=${error.runtimeType}',
      );
      _summary(
        'section=$label elapsed=${stopwatch.elapsedMilliseconds}ms status=failed',
      );
      return _SectionResult(
        label: label,
        data: null,
        elapsedMs: stopwatch.elapsedMilliseconds,
        isSuccess: false,
      );
    }
  }

  Future<Map<String, dynamic>> _requestPlanSection({
    required Uri uri,
    required String prompt,
    required String label,
  }) async {
    final requestBody = <String, dynamic>{
      'contents': <Map<String, dynamic>>[
        <String, dynamic>{
          'parts': <Map<String, dynamic>>[
            <String, dynamic>{'text': prompt},
          ],
        },
      ],
      'generationConfig': <String, dynamic>{
        'responseMimeType': 'application/json',
        'temperature': 0.4,
        'thinkingConfig': <String, dynamic>{'thinkingBudget': 0},
      },
    };
    AppException? lastAppException;
    Object? lastError;
    for (var attempt = 1; attempt <= _maxRetryAttempts; attempt++) {
      HttpClient? client;
      String responsePreview = '';
      final requestStartedAt = DateTime.now();
      final requestStopwatch = Stopwatch()..start();
      try {
        if (_enableGeminiDebugLogs) {
          debugPrint(
            '[ChecklistPlan] Gemini request started '
            'label=$label attempt=$attempt/$_maxRetryAttempts',
          );
        }
        _debug(
          'request started label=$label promptLength=${prompt.length} '
          'attempt=$attempt/$_maxRetryAttempts',
        );
        _debug(
          'request startTime=${requestStartedAt.toIso8601String()} '
          'label=$label attempt=$attempt/$_maxRetryAttempts '
          'model=$_modelName toolsEnabled=false groundingEnabled=false '
          'promptLength=${prompt.length}',
        );
        client = HttpClient();
        final request = await client.postUrl(uri);
        request.headers.contentType = ContentType.json;
        request.add(utf8.encode(jsonEncode(requestBody)));

        final response = await request.close().timeout(geminiTimeout);
        final payload = await response.transform(utf8.decoder).join();
        responsePreview = payload;
        if (_enableGeminiDebugLogs) {
          debugPrint(
            '[ChecklistPlan] Gemini response statusCode=${response.statusCode} '
            'label=$label attempt=$attempt/$_maxRetryAttempts',
          );
        }
        _debug(
          'response statusCode=${response.statusCode} '
          'label=$label attempt=$attempt/$_maxRetryAttempts '
          'elapsed=${requestStopwatch.elapsedMilliseconds}ms '
          'rawResponseLength=${payload.length}',
        );
        if (response.statusCode < 200 || response.statusCode >= 300) {
          if (_shouldRetryStatusCode(response.statusCode) &&
              attempt < _maxRetryAttempts) {
            _debug(
              'retryable statusCode=${response.statusCode} '
              'label=$label attempt=$attempt/$_maxRetryAttempts',
            );
            await Future<void>.delayed(_retryBackoff(attempt));
            continue;
          }
          throw AppException(
            'gemini_request_failed_status_${response.statusCode}',
          );
        }

        final decoded = jsonDecode(payload);
        if (decoded is! Map<String, dynamic>) {
          throw AppException('gemini_response_not_json_object');
        }
        final candidates = decoded['candidates'];
        final candidateCount = candidates is List ? candidates.length : 0;

        final jsonText = _extractJsonText(decoded);
        _debug(
          'response candidates=$candidateCount '
          'label=$label extractedTextLength=${jsonText.length} '
          'extractedTextPreview=${_truncate(jsonText, 1200)}',
        );
        if (jsonText.isEmpty) {
          throw AppException('gemini_response_missing_json_text');
        }

        final parsed = jsonDecode(jsonText);
        if (parsed is! Map<String, dynamic>) {
          throw AppException('gemini_parsed_json_not_object');
        }
        _debug(
          'section parse success label=$label jsonLength=${jsonText.length}',
        );
        return parsed;
      } on TimeoutException catch (error) {
        lastError = error;
        _debug(
          'request timeout label=$label '
          'attempt=$attempt/$_maxRetryAttempts '
          'elapsed=${requestStopwatch.elapsedMilliseconds}ms',
        );
        if (attempt < _maxRetryAttempts) {
          await Future<void>.delayed(_retryBackoff(attempt));
          continue;
        }
        throw AppException('gemini_request_timeout');
      } on SocketException catch (error) {
        lastError = error;
        _debug(
          'request socket exception label=$label '
          'attempt=$attempt/$_maxRetryAttempts '
          'elapsed=${requestStopwatch.elapsedMilliseconds}ms',
        );
        if (attempt < _maxRetryAttempts) {
          await Future<void>.delayed(_retryBackoff(attempt));
          continue;
        }
        throw AppException('gemini_request_network_error');
      } on HttpException catch (error) {
        lastError = error;
        _debug(
          'request http exception label=$label '
          'attempt=$attempt/$_maxRetryAttempts '
          'elapsed=${requestStopwatch.elapsedMilliseconds}ms',
        );
        if (attempt < _maxRetryAttempts) {
          await Future<void>.delayed(_retryBackoff(attempt));
          continue;
        }
        throw AppException('gemini_request_network_error');
      } on FormatException catch (error) {
        lastError = error;
        if (_enableGeminiDebugLogs) {
          debugPrint(
            '[ChecklistPlan] Gemini JSON parse failed label=$label error=$error',
          );
          debugPrint(
            '[ChecklistPlan] Gemini raw response='
            '${_truncate(responsePreview, 500)}',
          );
        }
        _debug(
          'JSON parse failed label=$label error=$error rawResponsePreview='
          '${_truncate(responsePreview, 3000)}',
        );
        throw AppException('Gemini JSON parse failed: $error');
      } on AppException catch (error) {
        lastAppException = error;
        rethrow;
      } catch (error) {
        lastError = error;
        _debug(
          'request failed label=$label errorType=${error.runtimeType} '
          'attempt=$attempt/$_maxRetryAttempts '
          'elapsed=${requestStopwatch.elapsedMilliseconds}ms',
        );
        if (attempt < _maxRetryAttempts) {
          await Future<void>.delayed(_retryBackoff(attempt));
          continue;
        }
        throw AppException('gemini_request_failed');
      } finally {
        client?.close(force: true);
      }
    }
    if (lastAppException != null) {
      throw lastAppException;
    }
    if (lastError is TimeoutException) {
      throw AppException('gemini_request_timeout');
    }
    throw AppException('gemini_request_failed');
  }

  bool _shouldRetryStatusCode(int statusCode) {
    return statusCode == 408 || statusCode == 429 || statusCode >= 500;
  }

  Duration _retryBackoff(int attempt) {
    final millis = (attempt * 200).clamp(200, 1200);
    return Duration(milliseconds: millis);
  }

  void _summary(String message) {
    if (!_enableGeminiSummaryLogs) {
      return;
    }
    debugPrint('[GeminiSummary] $message');
  }

  void _debug(String message) {
    if (!_enableGeminiDebugLogs) {
      return;
    }
    debugPrint('[GeminiDebug] $message');
  }

  void _debugLogRequestStart({
    required GeminiPlanningInput input,
    required String promptA1,
    required String promptA2,
    required String promptA3,
    required String promptB1,
    required String promptB2,
    required String promptB3,
    required _BudgetHints hints,
  }) {
    if (!_enableGeminiDebugLogs) {
      return;
    }
    final hotelBudgetText =
        input.debugHotelBudget?.toString() ?? 'derived_by_model';
    final maxNightlyBudgetText =
        input.debugMaxHotelNightlyBudget?.toString() ?? 'derived_by_model';
    _debug('request started');
    _debug('model=$_modelName');
    _debug('destination=${input.destination}');
    _debug('departureCity=${input.departureCity}');
    _debug(
      'dateRange=${_formatDebugDate(input.startDate)} -> ${_formatDebugDate(input.endDate)}',
    );
    _debug('tripDays=${input.tripDays} nightCount=${input.nightCount}');
    _debug('travelerCount=${input.travelerCount}');
    _debug('totalBudget=${input.totalBudget}');
    _debug('currency=${input.currency}');
    _debug('hotelBudget=$hotelBudgetText');
    _debug('maxHotelNightlyBudget=$maxNightlyBudgetText');
    _debug(
      'accommodationPreference=${input.accommodationPreference} '
      'preferences=${input.preferences.join(', ')}',
    );
    _debug(
      'budget hints flight=${hints.flightBudgetHint} '
      'remaining=${hints.remainingBudgetHint} '
      'hotel=${hints.hotelBudgetHint} '
      'maxNightly=${hints.maxHotelNightlyBudgetHint}',
    );
    _debug(
      'promptA1 preview=${_truncate(promptA1, 1200)} '
      'totalLength=${promptA1.length}',
    );
    _debug(
      'promptA2 preview=${_truncate(promptA2, 1200)} '
      'totalLength=${promptA2.length}',
    );
    _debug(
      'promptA3 preview=${_truncate(promptA3, 1200)} '
      'totalLength=${promptA3.length}',
    );
    _debug(
      'promptB1 preview=${_truncate(promptB1, 1200)} '
      'totalLength=${promptB1.length}',
    );
    _debug(
      'promptB2 preview=${_truncate(promptB2, 1200)} '
      'totalLength=${promptB2.length}',
    );
    _debug(
      'promptB3 preview=${_truncate(promptB3, 1200)} '
      'totalLength=${promptB3.length}',
    );
  }

  void _debugLogParsedPlan({
    required GeminiPlanningInput input,
    required Map<String, dynamic> parsed,
    required GeminiGeneratedPlan generatedPlan,
  }) {
    if (!_enableGeminiDebugLogs) {
      return;
    }
    final hotelBudget = generatedPlan.budgetSplit.hotelBudget;
    final maxHotelNightlyBudget = hotelBudget != null && input.nightCount > 0
        ? hotelBudget / input.nightCount
        : null;
    _debug(
      'JSON parse success budgetSplit='
      '${_truncate(jsonEncode(parsed['budgetSplit']), 1200)}',
    );
    _debug(
      'counts flights=${generatedPlan.flights.length} '
      'hotels=${generatedPlan.hotelCandidates.length} '
      'restaurants=${generatedPlan.restaurantQueries.length} '
      'activities=${generatedPlan.activityQueries.length} '
      'essentials=${generatedPlan.essentials.length}',
    );

    for (final flight in generatedPlan.flights) {
      _debug(
        'flight tripDirection=${flight.tripDirection} '
        'airlineName=${flight.airlineName ?? ''} '
        'flightNumber=${flight.flightNumber ?? ''} '
        'departureAirportCode=${flight.departureAirportCode ?? ''} '
        'arrivalAirportCode=${flight.arrivalAirportCode ?? ''} '
        'departureTime=${flight.departureTime ?? ''} '
        'arrivalTime=${flight.arrivalTime ?? ''} '
        'estimatedPrice=${flight.estimatedPrice} '
        'hasGoogleFlightsUrl=${(flight.googleFlightsUrl ?? '').trim().isNotEmpty}',
      );
    }

    for (final hotel in generatedPlan.hotelCandidates) {
      final suspiciousReason = _detectHotelSuspiciousReason(
        currency: input.currency,
        hotel: hotel,
        nightCount: input.nightCount,
        hotelBudget: hotelBudget,
        maxHotelNightlyBudget: maxHotelNightlyBudget,
      );
      final totalMax = hotel.expectedCostMax == null
          ? null
          : hotel.expectedCostMax! * input.nightCount;
      final isWithinBudget =
          hotelBudget == null || totalMax == null || totalMax <= hotelBudget;
      _debug(
        'hotel title=${hotel.name} '
        'estimatedCostMin=${hotel.expectedCostMin} '
        'estimatedCostMax=${hotel.expectedCostMax} '
        'costUnit=${hotel.costUnit} '
        'currency=${input.currency} '
        'totalMax=$totalMax '
        'hotelBudget=$hotelBudget '
        'isWithinBudget=$isWithinBudget '
        'suspiciousPrice=${suspiciousReason != null} '
        'suspiciousReason=${suspiciousReason ?? ''}',
      );
    }

    for (final restaurant in generatedPlan.restaurantQueries) {
      final suspiciousReason = _detectQuerySuspiciousReason(
        currency: input.currency,
        query: restaurant,
        type: 'restaurant',
      );
      _debug(
        'restaurant title=${restaurant.query} '
        'estimatedCostMin=${restaurant.estimatedCostMin} '
        'estimatedCostMax=${restaurant.estimatedCostMax} '
        'costUnit=${restaurant.costUnit} '
        'currency=${input.currency} '
        'suspiciousPrice=${suspiciousReason != null} '
        'suspiciousReason=${suspiciousReason ?? ''}',
      );
    }

    for (final activity in generatedPlan.activityQueries) {
      final suspiciousReason = _detectQuerySuspiciousReason(
        currency: input.currency,
        query: activity,
        type: 'activity',
      );
      _debug(
        'activity title=${activity.query} '
        'estimatedCostMin=${activity.estimatedCostMin} '
        'estimatedCostMax=${activity.estimatedCostMax} '
        'costUnit=${activity.costUnit} '
        'currency=${input.currency} '
        'suspiciousPrice=${suspiciousReason != null} '
        'suspiciousReason=${suspiciousReason ?? ''}',
      );
    }
  }

  String? _detectHotelSuspiciousReason({
    required String currency,
    required GeminiHotelCandidate hotel,
    required int nightCount,
    required double? hotelBudget,
    required double? maxHotelNightlyBudget,
  }) {
    if (currency.trim().toUpperCase() != 'CNY') {
      return null;
    }
    final average = _readAverageAmount(
      min: hotel.expectedCostMin,
      max: hotel.expectedCostMax,
    );
    if (average == null) {
      return 'missing_price';
    }
    if (average <= 0) {
      return 'non_positive_price';
    }
    if (average < 60) {
      return 'too_low_for_cny_hotel';
    }
    final totalMax = hotel.expectedCostMax == null
        ? null
        : hotel.expectedCostMax! * nightCount;
    if (hotelBudget != null && totalMax != null && totalMax > hotelBudget) {
      return 'stay_total_exceeds_hotel_budget';
    }
    if (maxHotelNightlyBudget != null &&
        hotel.expectedCostMax != null &&
        hotel.expectedCostMax! > maxHotelNightlyBudget * 1.15) {
      return 'nightly_price_exceeds_budget';
    }
    final upperLimit = maxHotelNightlyBudget == null
        ? 8000
        : (maxHotelNightlyBudget * 2.8).clamp(8000, 30000).toDouble();
    if (average > upperLimit) {
      return 'too_high_for_cny_hotel';
    }
    return null;
  }

  String? _detectQuerySuspiciousReason({
    required String currency,
    required GeminiPlaceQuery query,
    required String type,
  }) {
    if (currency.trim().toUpperCase() != 'CNY') {
      return null;
    }
    final average = _readAverageAmount(
      min: query.estimatedCostMin,
      max: query.estimatedCostMax,
    );
    if (average == null) {
      return 'missing_price';
    }
    if (average < 0) {
      return 'negative_price';
    }
    if (type == 'restaurant') {
      if (average > 1500) {
        return 'too_high_for_cny_restaurant';
      }
      return null;
    }
    if (average > 5000) {
      return 'too_high_for_cny_activity';
    }
    return null;
  }

  double? _readAverageAmount({required double? min, required double? max}) {
    if (min != null && max != null) {
      return (min + max) / 2;
    }
    return min ?? max;
  }

  String _formatDebugDate(DateTime value) {
    final year = value.year.toString().padLeft(4, '0');
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  String _truncate(String value, int maxLength) {
    final trimmed = value.trim();
    if (trimmed.length <= maxLength) {
      return trimmed;
    }
    return '${trimmed.substring(0, maxLength)}...';
  }

  String _extractJsonText(Map<String, dynamic> decoded) {
    final candidates = decoded['candidates'];
    if (candidates is! List) {
      return '';
    }

    for (final candidate in candidates) {
      if (candidate is! Map) {
        continue;
      }
      final content = candidate['content'];
      if (content is! Map) {
        continue;
      }
      final parts = content['parts'];
      if (parts is! List) {
        continue;
      }

      final buffer = StringBuffer();
      for (final part in parts) {
        if (part is! Map) {
          continue;
        }
        final text = (part['text'] as String?)?.trim() ?? '';
        if (text.isNotEmpty) {
          buffer.write(text);
        }
      }

      final mergedText = buffer.toString().trim();
      if (mergedText.isNotEmpty) {
        return mergedText;
      }
    }

    return '';
  }

  _BudgetHints _buildBudgetHints(GeminiPlanningInput input) {
    final normalizedPreference = input.accommodationPreference
        .trim()
        .toLowerCase();
    final stayRatio = switch (normalizedPreference) {
      'luxury' => 0.58,
      'budget' => 0.38,
      'budget_friendly' => 0.38,
      'comfortable' => 0.45,
      _ => 0.42,
    };
    final flightBudgetHint = input.totalBudget * 0.35;
    final remainingBudgetHint = (input.totalBudget - flightBudgetHint)
        .clamp(0, input.totalBudget)
        .toDouble();
    final hotelBudgetHint = (input.totalBudget * stayRatio)
        .clamp(0, input.totalBudget)
        .toDouble();
    final maxNightlyHint = input.nightCount > 0
        ? hotelBudgetHint / input.nightCount
        : hotelBudgetHint;
    return _BudgetHints(
      flightBudgetHint: _roundMoney(flightBudgetHint),
      remainingBudgetHint: _roundMoney(remainingBudgetHint),
      hotelBudgetHint: _roundMoney(hotelBudgetHint),
      maxHotelNightlyBudgetHint: _roundMoney(maxNightlyHint),
    );
  }

  Map<String, dynamic> _mergeSectionsWithFallback({
    required GeminiPlanningInput input,
    required _BudgetHints hints,
    required _SectionResult? budgetSection,
    required _SectionResult? flightSection,
    required _SectionResult? hotelSection,
    required _SectionResult? restaurantSection,
    required _SectionResult? activitySection,
    required _SectionResult? essentialsSection,
  }) {
    final budgetSplit =
        budgetSection?.data?['budgetSplit'] ??
        _buildBudgetSplitFallbackMap(input, hints);
    final flights =
        flightSection?.data?['flights'] ??
        _buildFlightSkeletonFallbackList(input);
    var hotels = (hotelSection?.data?['hotelCandidates'] as List?)?.toList();
    hotels ??= _buildHotelCandidatesFallbackList(input, hints);

    // 使用最终 budgetSplit 对酒店候选做二次校验，避免超预算候选进入主流程。
    final normalizedHotels = _enforceHotelBudgetOnCandidates(
      hotels: hotels,
      budgetSplit: budgetSplit,
      input: input,
      hints: hints,
    );
    final restaurantQueries =
        restaurantSection?.data?['restaurantQueries'] ??
        _buildRestaurantQueriesFallbackList(input);
    final activityQueries =
        activitySection?.data?['activityQueries'] ??
        _buildActivityQueriesFallbackList(input);
    final essentialsAndTipFallback = _buildEssentialsAndProTipFallbackMap();
    final essentials =
        essentialsSection?.data?['essentials'] ??
        essentialsAndTipFallback['essentials'];
    final proTip =
        essentialsSection?.data?['proTip'] ??
        essentialsAndTipFallback['proTip'];

    return <String, dynamic>{
      'budgetSplit': budgetSplit,
      'flights': flights,
      'hotelCandidates': normalizedHotels,
      'restaurantQueries': restaurantQueries,
      'activityQueries': activityQueries,
      'essentials': essentials,
      'proTip': proTip,
    };
  }

  List<Map<String, dynamic>> _enforceHotelBudgetOnCandidates({
    required List<dynamic> hotels,
    required Object? budgetSplit,
    required GeminiPlanningInput input,
    required _BudgetHints hints,
  }) {
    final budgetMap = budgetSplit is Map
        ? budgetSplit.cast<Object?, Object?>()
        : null;
    final hotelBudget =
        GeminiGeneratedPlan._readDouble(budgetMap?['hotelBudget']) ??
        hints.hotelBudgetHint;
    final nightlyLimit = input.nightCount > 0
        ? hotelBudget / input.nightCount
        : hints.maxHotelNightlyBudgetHint;
    final filtered = <Map<String, dynamic>>[];
    for (final raw in hotels) {
      if (raw is! Map) {
        continue;
      }
      final map = raw.cast<Object?, Object?>();
      final costMax = GeminiGeneratedPlan._readDouble(map['expectedCostMax']);
      if (costMax == null || input.nightCount <= 0) {
        filtered.add(Map<String, dynamic>.from(map.cast<String, dynamic>()));
        continue;
      }
      final total = costMax * input.nightCount;
      if (total <= hotelBudget) {
        filtered.add(Map<String, dynamic>.from(map.cast<String, dynamic>()));
      }
    }
    if (filtered.isNotEmpty) {
      return filtered.take(3).toList(growable: false);
    }
    _debug(
      'hotel candidates all over budget, fallback to budget-safe candidate',
    );
    final fallbackMax = (nightlyLimit <= 0 ? 1200.0 : nightlyLimit * 0.95)
        .toDouble();
    return <Map<String, dynamic>>[
      <String, dynamic>{
        'name': '${input.destination} hotel area',
        'expectedCostMin': _roundMoney(fallbackMax * 0.75),
        'expectedCostMax': _roundMoney(fallbackMax),
        'costUnit': 'per_night',
        'reason': 'budget-safe fallback',
        'matchPreference': input.accommodationPreference,
      },
    ];
  }

  Map<String, dynamic> _buildBudgetSplitFallbackMap(
    GeminiPlanningInput input,
    _BudgetHints hints,
  ) {
    return <String, dynamic>{
      'flightBudgetMax': hints.flightBudgetHint,
      'remainingBudget': hints.remainingBudgetHint,
      'hotelBudget': hints.hotelBudgetHint,
      'currency': input.currency,
      'foodBudget': _roundMoney(input.totalBudget * 0.2),
      'activityBudget': _roundMoney(input.totalBudget * 0.12),
      'localTransportBudget': _roundMoney(input.totalBudget * 0.08),
      'bufferBudget': _roundMoney(input.totalBudget * 0.1),
    };
  }

  List<Map<String, dynamic>> _buildFlightSkeletonFallbackList(
    GeminiPlanningInput input,
  ) {
    final outboundDate = _formatDebugDate(input.startDate);
    final returnDate = _formatDebugDate(input.endDate);
    final oneWayPrice = _roundMoney(
      ((input.totalBudget * 0.35) / 2).clamp(300, input.totalBudget).toDouble(),
    );
    return <Map<String, dynamic>>[
      <String, dynamic>{
        'tripDirection': 'outbound',
        'departureCity': input.departureCity,
        'arrivalCity': input.destination,
        'departureDate': outboundDate,
        'estimatedPrice': oneWayPrice,
        'currency': input.currency,
        'googleFlightsUrl': _buildGoogleFlightsSearchUrl(
          from: input.departureCity,
          to: input.destination,
          date: outboundDate,
        ),
      },
      <String, dynamic>{
        'tripDirection': 'return',
        'departureCity': input.destination,
        'arrivalCity': input.departureCity,
        'departureDate': returnDate,
        'estimatedPrice': oneWayPrice,
        'currency': input.currency,
        'googleFlightsUrl': _buildGoogleFlightsSearchUrl(
          from: input.destination,
          to: input.departureCity,
          date: returnDate,
        ),
      },
    ];
  }

  List<Map<String, dynamic>> _buildHotelCandidatesFallbackList(
    GeminiPlanningInput input,
    _BudgetHints hints,
  ) {
    final maxNightly = hints.maxHotelNightlyBudgetHint <= 0
        ? 1200.0
        : hints.maxHotelNightlyBudgetHint;
    return <Map<String, dynamic>>[
      <String, dynamic>{
        'name': '${input.destination} central hotel',
        'expectedCostMin': _roundMoney(maxNightly * 0.7),
        'expectedCostMax': _roundMoney(maxNightly),
        'costUnit': 'per_night',
        'reason': 'budget-aligned fallback',
        'matchPreference': input.accommodationPreference,
      },
    ];
  }

  List<Map<String, dynamic>> _buildRestaurantQueriesFallbackList(
    GeminiPlanningInput input,
  ) {
    final safeTripDays = input.tripDays <= 0 ? 1 : input.tripDays;
    final totalCount = _splitQueryTargetCount;
    final restaurants = <Map<String, dynamic>>[];
    for (var index = 0; index < totalCount; index++) {
      restaurants.add(<String, dynamic>{
        'query': '${input.destination} local restaurant',
        'dayIndex': (index % safeTripDays) + 1,
        'estimatedCostMin': _roundMoney(input.totalBudget * 0.01),
        'estimatedCostMax': _roundMoney(input.totalBudget * 0.018),
        'costUnit': 'per_person',
      });
    }
    return restaurants;
  }

  List<Map<String, dynamic>> _buildActivityQueriesFallbackList(
    GeminiPlanningInput input,
  ) {
    final safeTripDays = input.tripDays <= 0 ? 1 : input.tripDays;
    final totalCount = _splitQueryTargetCount;
    final activities = <Map<String, dynamic>>[];
    for (var index = 0; index < totalCount; index++) {
      activities.add(<String, dynamic>{
        'query': '${input.destination} popular activity',
        'dayIndex': (index % safeTripDays) + 1,
        'estimatedCostMin': _roundMoney(input.totalBudget * 0.008),
        'estimatedCostMax': _roundMoney(input.totalBudget * 0.02),
        'costUnit': 'per_person',
      });
    }
    return activities;
  }

  Map<String, dynamic> _buildEssentialsAndProTipFallbackMap() {
    return <String, dynamic>{
      'essentials': <Map<String, dynamic>>[
        <String, dynamic>{
          'type': 'trade_off',
          'iconType': 'trade_off',
          'title': 'Trade-off',
          'mainText': 'Prioritize key places',
          'subText': 'Keep a small time buffer daily.',
        },
        <String, dynamic>{
          'type': 'strategy',
          'iconType': 'strategy',
          'title': 'Strategy',
          'mainText': 'Cluster nearby spots',
          'subText': 'Reduce transfer time and cost.',
        },
        <String, dynamic>{
          'type': 'tips',
          'iconType': 'tips',
          'title': 'Tips',
          'mainText': 'Book top slots early',
          'subText': 'Reserve high-demand items first.',
        },
      ],
      'proTip': <String, dynamic>{
        'tipTitle': 'Plan smart',
        'tipDescription':
            'Lock priority bookings early and keep 1 backup option.',
      },
    };
  }

  String _buildGoogleFlightsSearchUrl({
    required String from,
    required String to,
    required String date,
  }) {
    return Uri.https('www.google.com', '/travel/flights', <String, String>{
      'q': 'Flights from $from to $to on $date',
    }).toString();
  }

  double _roundMoney(double value) {
    if (value.isNaN || value.isInfinite) {
      return 0;
    }
    return double.parse(value.toStringAsFixed(0));
  }

  String _buildBudgetSplitPrompt(GeminiPlanningInput input) {
    final inputJson = jsonEncode(input.toJson());
    return '''
Return compact JSON only.
No markdown.
No explanations.
No extra text before or after JSON.

Return only these top-level keys:
- budgetSplit

Rules:
- totalBudget is whole trip budget.
- remainingBudget = totalBudget - flightBudgetMax.
- currency must be the selected user currency.
- keep values practical and concise.

Input JSON:
$inputJson

Compact output shape example:
{
  "budgetSplit": {
    "flightBudgetMax": 0,
    "remainingBudget": 0,
    "hotelBudget": 0,
    "currency": "CNY",
    "foodBudget": 0,
    "activityBudget": 0,
    "localTransportBudget": 0,
    "bufferBudget": 0
  }
}
''';
  }

  String _buildFlightSkeletonPrompt(GeminiPlanningInput input) {
    final inputJson = jsonEncode(input.toJson());
    return '''
Return compact JSON only.
No markdown.
No explanations.
No extra text before or after JSON.

Return only top-level key: flights

Rules:
- flights must contain exactly 2 items: outbound then return.
- Required fields only:
  tripDirection, departureCity, arrivalCity, departureDate, estimatedPrice, currency, googleFlightsUrl
- Do not generate airlineName/flightNumber/airportCode/time/terminal.
- outbound: departureCity -> destination on startDate.
- return: destination -> departureCity on endDate.
- currency must be selected user currency.

Input JSON:
$inputJson

Compact output shape example:
{
  "flights":[
    {"tripDirection":"outbound","departureCity":"Shanghai","arrivalCity":"Tokyo","departureDate":"2026-08-01","estimatedPrice":2200,"currency":"CNY","googleFlightsUrl":"https://..."},
    {"tripDirection":"return","departureCity":"Tokyo","arrivalCity":"Shanghai","departureDate":"2026-08-05","estimatedPrice":2200,"currency":"CNY","googleFlightsUrl":"https://..."}
  ]
}
''';
  }

  String _buildHotelCandidatesPrompt({
    required GeminiPlanningInput input,
    required _BudgetHints hints,
  }) {
    final inputJson = jsonEncode(input.toJson());
    final hintJson = jsonEncode(<String, dynamic>{
      'flightBudgetHint': hints.flightBudgetHint,
      'remainingBudgetHint': hints.remainingBudgetHint,
      'hotelBudgetHint': hints.hotelBudgetHint,
      'maxHotelNightlyBudgetHint': hints.maxHotelNightlyBudgetHint,
    });
    return '''
Return compact JSON only.
No markdown.
No explanations.
No extra text before or after JSON.

Return only top-level key: hotelCandidates

Rules:
- hotelCandidates count must be 1 to 3.
- required fields:
  name, expectedCostMin, expectedCostMax, costUnit, reason, matchPreference
- costUnit must be per_night.
- Use hotelBudgetHint and maxHotelNightlyBudgetHint to keep prices realistic.
- expectedCostMax * nightCount should not exceed hotelBudgetHint.
- accommodationPreference affects tier preference, not strict blacklist.
- currency context must follow user currency.

Input JSON:
$inputJson

Budget Hints JSON:
$hintJson

Compact output shape example:
{
  "hotelCandidates":[
    {"name":"...","expectedCostMin":900,"expectedCostMax":1200,"costUnit":"per_night","reason":"near transit","matchPreference":"comfortable"}
  ]
}
''';
  }

  String _buildRestaurantQueriesPrompt(GeminiPlanningInput input) {
    final inputJson = jsonEncode(input.toJson());
    return '''
Return compact JSON only.
No markdown.
No explanations.
No extra text before or after JSON.

Return only this top-level key:
- restaurantQueries

Rules:
- Keep text short and practical for MVP only.
- restaurantQueries count must be exactly $_splitQueryTargetCount.
- dayIndex starts from 1 and should be evenly distributed across tripDays.
- restaurant costUnit must be per_person.
- estimatedCostMin/Max must be numeric and in selected currency.
- query text should be searchable, around 3-8 words.
- each query should represent different meal style or district.
- do not generate duplicate query strings.
- no long prose, no marketing tone, no markdown.
- do not output activityQueries, essentials, or proTip.
- Do not generate priceVerified/unverifiedReason/externalUrl fields.
- if uncertain, still return valid JSON with $_splitQueryTargetCount rows.
- output strictly follows JSON shape below.

Input JSON:
$inputJson

Compact output shape example:
{
  "restaurantQueries":[
    {"query":"local breakfast cafe","dayIndex":1,"estimatedCostMin":45,"estimatedCostMax":85,"costUnit":"per_person"},
    {"query":"ramen lunch spot","dayIndex":1,"estimatedCostMin":55,"estimatedCostMax":95,"costUnit":"per_person"},
    {"query":"casual izakaya dinner","dayIndex":2,"estimatedCostMin":80,"estimatedCostMax":160,"costUnit":"per_person"},
    {"query":"seafood market lunch","dayIndex":3,"estimatedCostMin":90,"estimatedCostMax":180,"costUnit":"per_person"},
    {"query":"family dinner place","dayIndex":4,"estimatedCostMin":70,"estimatedCostMax":140,"costUnit":"per_person"},
    {"query":"late night local eats","dayIndex":5,"estimatedCostMin":50,"estimatedCostMax":110,"costUnit":"per_person"}
  ]
}
''';
  }

  String _buildActivityQueriesPrompt(GeminiPlanningInput input) {
    final inputJson = jsonEncode(input.toJson());
    return '''
Return compact JSON only.
No markdown.
No explanations.
No extra text before or after JSON.

Return only this top-level key:
- activityQueries

Rules:
- Keep text short and practical for MVP.
- activityQueries count must be exactly $_splitQueryTargetCount.
- dayIndex starts from 1 and should be evenly distributed across tripDays.
- activity costUnit should be per_person or per_ticket.
- free activity can use costUnit=total with min=0 and max=0.
- estimatedCostMin/Max must be numeric and in selected currency.
- query text should be searchable, around 3-8 words.
- relaxed pace means fewer heavy activities in one day.
- packed pace allows multiple activities on one day.
- avoid long prose, avoid marketing copy, avoid markdown output.
- do not generate duplicate query strings.
- do not output restaurantQueries, essentials, or proTip.
- Do not generate priceVerified/unverifiedReason/externalUrl fields.
- if uncertain, still return valid JSON with $_splitQueryTargetCount rows.
- output strictly follows JSON shape below.

Input JSON:
$inputJson

Compact output shape example:
{
  "activityQueries":[
    {"query":"city observation deck","dayIndex":1,"estimatedCostMin":120,"estimatedCostMax":220,"costUnit":"per_ticket"},
    {"query":"historic temple walk","dayIndex":1,"estimatedCostMin":0,"estimatedCostMax":0,"costUnit":"total"},
    {"query":"modern art museum","dayIndex":2,"estimatedCostMin":90,"estimatedCostMax":180,"costUnit":"per_person"},
    {"query":"sunset river cruise","dayIndex":3,"estimatedCostMin":150,"estimatedCostMax":260,"costUnit":"per_person"},
    {"query":"street culture walk","dayIndex":4,"estimatedCostMin":0,"estimatedCostMax":0,"costUnit":"total"},
    {"query":"night skyline viewpoint","dayIndex":5,"estimatedCostMin":30,"estimatedCostMax":90,"costUnit":"per_person"}
  ]
}
''';
  }

  String _buildEssentialsTipPrompt(GeminiPlanningInput input) {
    final inputJson = jsonEncode(input.toJson());
    return '''
Return compact JSON only.
No markdown.
No explanations.
No extra text before or after JSON.

Return only these top-level keys:
- essentials
- proTip

Rules:
- essentials must contain exactly 3 entries.
- essentials types must be: trade_off, strategy, tips.
- do not generate WEATHER content.
- title and mainText must be short and practical.
- subText should be one concise sentence, no long paragraph.
- proTip requires tipTitle and tipDescription.
- proTip should be practical, not marketing language.
- keep all text compact, actionable, and neutral.
- do not output restaurantQueries or activityQueries.
- Do not generate priceVerified/unverifiedReason/externalUrl fields.
- if uncertain, still return valid compact JSON.
- output strictly follows JSON shape below.

Input JSON:
$inputJson

Compact output shape example:
{
  "essentials":[
    {"type":"trade_off","iconType":"trade_off","title":"Trade-off","mainText":"Prioritize top sights","subText":"Leave one flexible slot each day."},
    {"type":"strategy","iconType":"strategy","title":"Strategy","mainText":"Group nearby stops","subText":"Reduce transfers to save time and budget."},
    {"type":"tips","iconType":"tips","title":"Tips","mainText":"Book key tickets early","subText":"Reserve high-demand slots 3-7 days ahead."}
  ],
  "proTip":{"tipTitle":"Smart pacing","tipDescription":"Keep one light block daily so delays do not break the full plan."}
}
''';
  }
}

class GeminiPlanningInput {
  GeminiPlanningInput({
    required this.id,
    required this.destination,
    this.placeId,
    required this.latitude,
    required this.longitude,
    required this.departureCity,
    required this.startDate,
    required this.endDate,
    required this.tripDays,
    required this.nightCount,
    required this.travelerCount,
    required this.totalBudget,
    required this.currency,
    required this.currencySymbol,
    required this.preferences,
    required this.pace,
    required this.accommodationPreference,
    this.debugHotelBudget,
    this.debugMaxHotelNightlyBudget,
  }) : restaurantTargetCount = _buildRestaurantTargetCount(tripDays),
       activityTargetCount = _buildActivityTargetCount(
         tripDays: tripDays,
         pace: pace,
       );

  final String id;
  final String destination;
  final String? placeId;
  final double latitude;
  final double longitude;
  final String departureCity;
  final DateTime startDate;
  final DateTime endDate;
  final int tripDays;
  final int nightCount;
  final int travelerCount;
  final double totalBudget;
  final String currency;
  final String currencySymbol;
  final List<String> preferences;
  final String pace;
  final String accommodationPreference;
  final double? debugHotelBudget;
  final double? debugMaxHotelNightlyBudget;
  final int restaurantTargetCount;
  final int activityTargetCount;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'destination': destination,
      'placeId': placeId,
      'latitude': latitude,
      'longitude': longitude,
      'departureCity': departureCity,
      'startDate': _formatDate(startDate),
      'endDate': _formatDate(endDate),
      'tripDays': tripDays,
      'nightCount': nightCount,
      'travelerCount': travelerCount,
      'totalBudget': totalBudget,
      'currency': currency,
      'currencySymbol': currencySymbol,
      'preferences': preferences,
      'pace': pace,
      'accommodationPreference': accommodationPreference,
      'restaurantTargetCount': restaurantTargetCount,
      'activityTargetCount': activityTargetCount,
    };
  }

  String _formatDate(DateTime value) {
    final year = value.year.toString().padLeft(4, '0');
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  static int _buildRestaurantTargetCount(int tripDays) {
    return (tripDays * 2).clamp(2, 12);
  }

  static int _buildActivityTargetCount({
    required int tripDays,
    required String pace,
  }) {
    switch (pace.trim().toLowerCase()) {
      case 'relaxed':
        return tripDays.clamp(2, 15);
      case 'packed':
        return (tripDays * 3).clamp(3, 15);
      case 'balanced':
      default:
        return (tripDays * 2).clamp(2, 15);
    }
  }
}

class GeminiGeneratedPlan {
  GeminiGeneratedPlan({
    required this.budgetSplit,
    required this.flights,
    required this.hotelCandidates,
    required this.restaurantQueries,
    required this.activityQueries,
    required this.essentials,
    required this.proTip,
  });

  final ChecklistBudgetSplit budgetSplit;
  final List<GeminiFlightPlan> flights;
  final List<GeminiHotelCandidate> hotelCandidates;
  final List<GeminiPlaceQuery> restaurantQueries;
  final List<GeminiPlaceQuery> activityQueries;
  final List<ChecklistEssential> essentials;
  final ChecklistProTip? proTip;

  factory GeminiGeneratedPlan.fromJson(
    Map<String, dynamic> json, {
    required String defaultCurrency,
    required int restaurantTargetCount,
    required int activityTargetCount,
  }) {
    return GeminiGeneratedPlan(
      budgetSplit: _readBudgetSplit(
        json['budgetSplit'],
        defaultCurrency: defaultCurrency,
      ),
      flights: _readFlights(
        json['flights'],
        fallbackFlight: json['flight'],
        defaultCurrency: defaultCurrency,
      ),
      hotelCandidates: _readHotelCandidates(json['hotelCandidates']),
      restaurantQueries: _readQueries(
        json['restaurantQueries'],
        fallbackCostUnit: 'per_person',
      ).take(restaurantTargetCount).toList(growable: false),
      activityQueries: _readQueries(
        json['activityQueries'],
        fallbackCostUnit: 'per_ticket',
      ).take(activityTargetCount).toList(growable: false),
      essentials: _readEssentials(json['essentials']),
      proTip: _readProTip(json['proTip']),
    );
  }

  static ChecklistBudgetSplit _readBudgetSplit(
    Object? value, {
    required String defaultCurrency,
  }) {
    final map = value is Map ? value.cast<Object?, Object?>() : null;
    return ChecklistBudgetSplit(
      transportRatio: _readDouble(map?['transportRatio']),
      stayRatio: _readDouble(map?['stayRatio']),
      foodActivityRatio: _readDouble(map?['foodActivityRatio']),
      flightBudgetMax: _readDouble(map?['flightBudgetMax']),
      remainingBudget: _readDouble(map?['remainingBudget']),
      hotelBudget: _readDouble(map?['hotelBudget']),
      foodBudget: _readDouble(map?['foodBudget']),
      activityBudget: _readDouble(map?['activityBudget']),
      localTransportBudget: _readDouble(map?['localTransportBudget']),
      bufferBudget: _readDouble(map?['bufferBudget']),
      currency: (map?['currency'] as String?)?.trim() ?? defaultCurrency,
      budgetWarning: _nullableText(map?['budgetWarning']),
    );
  }

  static List<GeminiFlightPlan> _readFlights(
    Object? value, {
    required Object? fallbackFlight,
    required String defaultCurrency,
  }) {
    final result = <GeminiFlightPlan>[];
    if (value is List) {
      for (final item in value.whereType<Map>()) {
        final flight = _readFlight(item, defaultCurrency: defaultCurrency);
        if (flight != null) {
          result.add(flight);
        }
      }
    }

    if (result.isNotEmpty) {
      return result;
    }

    final legacy = _readFlight(
      fallbackFlight,
      defaultCurrency: defaultCurrency,
    );
    if (legacy == null) {
      return const <GeminiFlightPlan>[];
    }
    return <GeminiFlightPlan>[legacy];
  }

  static GeminiFlightPlan? _readFlight(
    Object? value, {
    required String defaultCurrency,
  }) {
    if (value is! Map) {
      return null;
    }
    final map = value.cast<Object?, Object?>();
    final direction = (_nullableText(map['tripDirection']) ?? '').toLowerCase();
    final airlineName = _nullableText(map['airlineName']);
    final airline = airlineName ?? _nullableText(map['airline']);
    final googleFlightsUrl =
        _nullableText(map['googleFlightsUrl']) ??
        _nullableText(map['externalUrl']);
    final estimatedPrice = _readDouble(map['estimatedPrice']);
    final estimatedCostMin =
        _readDouble(map['estimatedCostMin']) ??
        (estimatedPrice == null ? null : estimatedPrice * 0.95);
    final estimatedCostMax =
        _readDouble(map['estimatedCostMax']) ??
        (estimatedPrice == null ? null : estimatedPrice * 1.05);
    return GeminiFlightPlan(
      tripDirection: direction == 'return' ? 'return' : 'outbound',
      airlineName: airline,
      airlineCode: _nullableText(map['airlineCode']),
      flightNumber: _nullableText(map['flightNumber']),
      departureCity: _nullableText(map['departureCity']),
      arrivalCity: _nullableText(map['arrivalCity']),
      departureAirportName:
          _nullableText(map['departureAirportName']) ??
          _nullableText(map['departureAirport']),
      departureAirportCode: _nullableText(map['departureAirportCode']),
      departureTerminal: _nullableText(map['departureTerminal']),
      arrivalAirportName:
          _nullableText(map['arrivalAirportName']) ??
          _nullableText(map['arrivalAirport']),
      arrivalAirportCode: _nullableText(map['arrivalAirportCode']),
      arrivalTerminal: _nullableText(map['arrivalTerminal']),
      departureTime: _nullableText(map['departureTime']),
      arrivalTime: _nullableText(map['arrivalTime']),
      departureDate: _nullableText(map['departureDate']),
      estimatedPrice: estimatedPrice,
      estimatedCostMin: estimatedCostMin,
      estimatedCostMax: estimatedCostMax,
      currency: _nullableText(map['currency']) ?? defaultCurrency,
      googleFlightsUrl: googleFlightsUrl,
      originalCurrency: _nullableText(map['originalCurrency']),
      originalPriceMin: _readDouble(map['originalPriceMin']),
      originalPriceMax: _readDouble(map['originalPriceMax']),
      priceVerified: (map['priceVerified'] as bool?) ?? false,
      unverifiedReason: _nullableText(map['unverifiedReason']) ?? 'ai_estimate',
    );
  }

  static List<GeminiHotelCandidate> _readHotelCandidates(Object? value) {
    if (value is! List) {
      return const <GeminiHotelCandidate>[];
    }
    return value
        .whereType<Map>()
        .take(3)
        .map((item) => item.cast<Object?, Object?>())
        .map(
          (map) => GeminiHotelCandidate(
            name: _nullableText(map['name']) ?? '',
            expectedCostMin: _readDouble(map['expectedCostMin']),
            expectedCostMax: _readDouble(map['expectedCostMax']),
            costUnit: _nullableText(map['costUnit']) ?? 'per_night',
            reason: _nullableText(map['reason']),
            matchPreference: _nullableText(map['matchPreference']),
            budgetWarning: _nullableText(map['budgetWarning']),
          ),
        )
        .where((candidate) => candidate.name.isNotEmpty)
        .toList(growable: false);
  }

  static List<GeminiPlaceQuery> _readQueries(
    Object? value, {
    required String fallbackCostUnit,
  }) {
    if (value is! List) {
      return const <GeminiPlaceQuery>[];
    }
    return value
        .whereType<Map>()
        .map((item) => item.cast<Object?, Object?>())
        .map(
          (map) => GeminiPlaceQuery(
            query: _nullableText(map['query']) ?? '',
            dayIndex: _readInt(map['dayIndex']),
            estimatedCostMin: _readDouble(map['estimatedCostMin']),
            estimatedCostMax: _readDouble(map['estimatedCostMax']),
            costUnit: _nullableText(map['costUnit']) ?? fallbackCostUnit,
          ),
        )
        .where((query) => query.query.isNotEmpty)
        .toList(growable: false);
  }

  static List<ChecklistEssential> _readEssentials(Object? value) {
    if (value is! List) {
      return const <ChecklistEssential>[];
    }
    return value
        .whereType<Map>()
        .map((item) => item.cast<Object?, Object?>())
        .map((map) {
          // 优先读取 type，确保 UI 能稳定匹配 TRADE OFF / STRATEGY / TIPS。
          final type = _nullableText(map['type']) ?? '';
          final iconType = _nullableText(map['iconType']) ?? '';
          final title = _nullableText(map['title']) ?? '';
          return ChecklistEssential(
            iconType: type.isNotEmpty ? type : iconType,
            title: title,
            mainText: _nullableText(map['mainText']) ?? '',
            subText: _nullableText(map['subText']),
          );
        })
        .where((item) {
          final title = item.title.trim().toLowerCase();
          final iconType = item.iconType.trim().toLowerCase();
          if (item.mainText.trim().isEmpty) {
            return false;
          }
          return title != 'weather' && iconType != 'weather';
        })
        .toList(growable: false);
  }

  static ChecklistProTip? _readProTip(Object? value) {
    if (value is! Map) {
      return null;
    }
    final map = value.cast<Object?, Object?>();
    final tip = ChecklistProTip(
      tipTitle: _nullableText(map['tipTitle']),
      tipDescription: _nullableText(map['tipDescription']),
    );
    return tip.isEmpty ? null : tip;
  }

  static String? _nullableText(Object? value) {
    final text = (value as String?)?.trim() ?? '';
    return text.isEmpty ? null : text;
  }

  static double? _readDouble(Object? value) {
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value.trim());
    }
    return null;
  }

  static int? _readInt(Object? value) {
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
}

class GeminiFlightPlan {
  const GeminiFlightPlan({
    required this.tripDirection,
    required this.airlineName,
    required this.airlineCode,
    required this.flightNumber,
    required this.departureCity,
    required this.arrivalCity,
    required this.departureAirportName,
    required this.departureAirportCode,
    required this.departureTerminal,
    required this.arrivalAirportName,
    required this.arrivalAirportCode,
    required this.arrivalTerminal,
    required this.departureTime,
    required this.arrivalTime,
    required this.departureDate,
    required this.estimatedPrice,
    required this.estimatedCostMin,
    required this.estimatedCostMax,
    required this.currency,
    required this.googleFlightsUrl,
    this.originalCurrency,
    this.originalPriceMin,
    this.originalPriceMax,
    this.priceVerified = true,
    this.unverifiedReason,
  });

  final String tripDirection;
  final String? airlineName;
  final String? airlineCode;
  final String? flightNumber;
  final String? departureCity;
  final String? arrivalCity;
  final String? departureAirportName;
  final String? departureAirportCode;
  final String? departureTerminal;
  final String? arrivalAirportName;
  final String? arrivalAirportCode;
  final String? arrivalTerminal;
  final String? departureTime;
  final String? arrivalTime;
  final String? departureDate;
  final double? estimatedPrice;
  final double? estimatedCostMin;
  final double? estimatedCostMax;
  final String currency;
  final String? googleFlightsUrl;
  final String? originalCurrency;
  final double? originalPriceMin;
  final double? originalPriceMax;
  final bool priceVerified;
  final String? unverifiedReason;

  Map<String, dynamic> toDebugJson() {
    return <String, dynamic>{
      'tripDirection': tripDirection,
      'airlineName': airlineName,
      'airlineCode': airlineCode,
      'flightNumber': flightNumber,
      'departureCity': departureCity,
      'arrivalCity': arrivalCity,
      'departureAirportName': departureAirportName,
      'departureAirportCode': departureAirportCode,
      'departureTerminal': departureTerminal,
      'arrivalAirportName': arrivalAirportName,
      'arrivalAirportCode': arrivalAirportCode,
      'arrivalTerminal': arrivalTerminal,
      'departureTime': departureTime,
      'arrivalTime': arrivalTime,
      'departureDate': departureDate,
      'estimatedPrice': estimatedPrice,
      'estimatedCostMin': estimatedCostMin,
      'estimatedCostMax': estimatedCostMax,
      'currency': currency,
      'googleFlightsUrl': googleFlightsUrl,
    };
  }
}

class GeminiHotelCandidate {
  const GeminiHotelCandidate({
    required this.name,
    required this.expectedCostMin,
    required this.expectedCostMax,
    required this.costUnit,
    required this.reason,
    required this.matchPreference,
    required this.budgetWarning,
  });

  final String name;
  final double? expectedCostMin;
  final double? expectedCostMax;
  final String costUnit;
  final String? reason;
  final String? matchPreference;
  final String? budgetWarning;
}

class GeminiPlaceQuery {
  const GeminiPlaceQuery({
    required this.query,
    required this.dayIndex,
    required this.estimatedCostMin,
    required this.estimatedCostMax,
    required this.costUnit,
  });

  final String query;
  final int? dayIndex;
  final double? estimatedCostMin;
  final double? estimatedCostMax;
  final String costUnit;
}

class _SectionResult {
  const _SectionResult({
    required this.label,
    required this.data,
    required this.elapsedMs,
    required this.isSuccess,
  });

  final String label;
  final Map<String, dynamic>? data;
  final int elapsedMs;
  final bool isSuccess;
}

class _BudgetHints {
  const _BudgetHints({
    required this.flightBudgetHint,
    required this.remainingBudgetHint,
    required this.hotelBudgetHint,
    required this.maxHotelNightlyBudgetHint,
  });

  final double flightBudgetHint;
  final double remainingBudgetHint;
  final double hotelBudgetHint;
  final double maxHotelNightlyBudgetHint;
}
