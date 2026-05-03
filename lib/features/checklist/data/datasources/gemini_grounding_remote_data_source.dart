import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../../../core/config/checklist_debug_config.dart';
import '../../../../core/config/gemini_config.dart';
import '../../../../core/error/app_exception.dart';
import 'gemini_planning_remote_data_source.dart';

class GeminiGroundingRemoteDataSource {
  static const String _modelName = 'gemini-2.5-flash';
  static const bool _enableGroundingSummaryLogs = kChecklistSummaryLogs;
  static const bool _enableGroundingDebugLogs = kChecklistVerboseLogs;

  void _log(String message) {
    if (!_enableGroundingDebugLogs) {
      return;
    }
    debugPrint('[Grounding] $message');
  }

  void _summary(String message) {
    if (!_enableGroundingSummaryLogs) {
      return;
    }
    debugPrint('[GroundingSummary] $message');
  }

  Future<List<GroundedFlightResult>> groundFlights({
    required GeminiPlanningInput input,
    required List<GeminiFlightPlan> skeletonFlights,
  }) async {
    final query =
        '${input.departureCity} ${input.destination} round trip flights '
        '${_formatDate(input.startDate)} ${_formatDate(input.endDate)}';
    final prompt =
        '''
Use Google Search grounding to find realistic public flight information.
Return compact JSON only.
Do not return markdown.
Do not invent data.

Target currency: ${input.currency}
Route: ${input.departureCity} -> ${input.destination}
Return route: ${input.destination} -> ${input.departureCity}
Outbound date: ${_formatDate(input.startDate)}
Return date: ${_formatDate(input.endDate)}

If exact live fares are unclear, keep the route, times, airline fields as realistic as possible, but set priceVerified=false and prices to null.
If price is available in another currency, convert it into ${input.currency} and also keep originalCurrency/originalPrice fields.

Return JSON schema:
{
  "flights": [
    {
      "tripDirection": "outbound|return",
      "airlineName": "string",
      "airlineCode": "string|null",
      "flightNumber": "string|null",
      "departureDate": "YYYY-MM-DD",
      "departureTime": "HH:mm|null",
      "arrivalTime": "HH:mm|null",
      "departureCity": "string",
      "arrivalCity": "string",
      "departureAirportName": "string|null",
      "departureAirportCode": "string|null",
      "departureTerminal": "string|null",
      "arrivalAirportName": "string|null",
      "arrivalAirportCode": "string|null",
      "arrivalTerminal": "string|null",
      "estimatedPrice": "number|null",
      "estimatedCostMin": "number|null",
      "estimatedCostMax": "number|null",
      "currency": "string",
      "googleFlightsUrl": "string|null",
      "originalCurrency": "string|null",
      "originalPriceMin": "number|null",
      "originalPriceMax": "number|null",
      "priceVerified": "boolean",
      "unverifiedReason": "string|null"
    }
  ]
}

Skeleton flights:
${jsonEncode(skeletonFlights.map((flight) => flight.toDebugJson()).toList(growable: false))}
''';

    final parsed = await _performGroundedRequest(
      type: 'flight',
      query: query,
      prompt: prompt,
    );
    final flights = <GroundedFlightResult>[];
    final rawFlights = parsed['flights'];
    if (rawFlights is List) {
      for (final item in rawFlights.whereType<Map>()) {
        flights.add(
          GroundedFlightResult.fromJson(item.cast<String, dynamic>()),
        );
      }
    }
    return flights;
  }

  Future<GroundedPriceSearchResult?> groundHotelCandidate({
    required GeminiPlanningInput input,
    required GeminiHotelCandidate candidate,
  }) async {
    final query = '${candidate.name} ${input.destination} hotel nightly price';
    final prompt =
        '''
Use Google Search grounding to verify this hotel candidate.
Return compact JSON only.
Do not return markdown.
Do not invent prices.

Target currency: ${input.currency}
Destination: ${input.destination}
Stay dates: ${_formatDate(input.startDate)} to ${_formatDate(input.endDate)}
Night count: ${input.nightCount}
Accommodation preference: ${input.accommodationPreference}
Candidate hotel name: ${candidate.name}

If nightly price is unreliable, set estimatedCostMin and estimatedCostMax to null, priceVerified=false, and unverifiedReason="price_unverified".
If the source price is in another currency, convert it into ${input.currency} and keep originalCurrency/originalPrice fields too.

Return JSON schema:
{
  "title": "string|null",
  "subtitle": "string|null",
  "estimatedCostMin": "number|null",
  "estimatedCostMax": "number|null",
  "currency": "string",
  "costUnit": "per_night",
  "externalUrl": "string|null",
  "originalCurrency": "string|null",
  "originalPriceMin": "number|null",
  "originalPriceMax": "number|null",
  "priceVerified": "boolean",
  "unverifiedReason": "string|null"
}
''';

    final parsed = await _performGroundedRequest(
      type: 'hotel',
      query: query,
      prompt: prompt,
    );
    return GroundedPriceSearchResult.fromJson(
      parsed,
      fallbackCurrency: input.currency,
      fallbackCostUnit: 'per_night',
    );
  }

  Future<GroundedPriceSearchResult?> groundPlaceCandidate({
    required GeminiPlanningInput input,
    required GeminiPlaceQuery queryPlan,
    required String type,
  }) async {
    final normalizedType = type.trim().toLowerCase();
    final searchQuery = normalizedType == 'restaurant'
        ? '${queryPlan.query} ${input.destination} restaurant average price'
        : '${queryPlan.query} ${input.destination} activity ticket price';
    final prompt =
        '''
Use Google Search grounding to verify this $normalizedType candidate.
Return compact JSON only.
Do not return markdown.
Do not invent prices.

Target currency: ${input.currency}
Destination: ${input.destination}
Candidate query: ${queryPlan.query}
Trip dates: ${_formatDate(input.startDate)} to ${_formatDate(input.endDate)}

For restaurants, return an average per-person price when possible.
For activities, return a per-person or per-ticket price when possible.
If the activity is free, set estimatedCostMin=0, estimatedCostMax=0, costUnit="total", priceVerified=true.
If price is unreliable, set priceVerified=false and estimatedCostMin/estimatedCostMax to null.
If source price is in another currency, convert it into ${input.currency} and keep originalCurrency/originalPrice fields too.

Return JSON schema:
{
  "title": "string|null",
  "subtitle": "string|null",
  "estimatedCostMin": "number|null",
  "estimatedCostMax": "number|null",
  "currency": "string",
  "costUnit": "${normalizedType == 'restaurant' ? 'per_person' : 'per_person|per_ticket|total'}",
  "externalUrl": "string|null",
  "originalCurrency": "string|null",
  "originalPriceMin": "number|null",
  "originalPriceMax": "number|null",
  "priceVerified": "boolean",
  "unverifiedReason": "string|null"
}
''';

    final parsed = await _performGroundedRequest(
      type: normalizedType,
      query: searchQuery,
      prompt: prompt,
    );
    return GroundedPriceSearchResult.fromJson(
      parsed,
      fallbackCurrency: input.currency,
      fallbackCostUnit: normalizedType == 'restaurant'
          ? 'per_person'
          : 'per_person',
    );
  }

  Future<Map<String, dynamic>> _performGroundedRequest({
    required String type,
    required String query,
    required String prompt,
  }) async {
    final apiKey = geminiApiKey.trim();
    if (apiKey.isEmpty) {
      throw AppException('gemini_api_key_missing');
    }

    HttpClient? client;
    final requestStartedAt = DateTime.now();
    final stopwatch = Stopwatch()..start();
    try {
      _summary('started type=$type');
      final uri = Uri.https(
        'generativelanguage.googleapis.com',
        '/v1beta/models/$_modelName:generateContent',
        <String, String>{'key': apiKey},
      );
      final requestBody = <String, dynamic>{
        'contents': <Map<String, dynamic>>[
          <String, dynamic>{
            'parts': <Map<String, dynamic>>[
              <String, dynamic>{'text': prompt},
            ],
          },
        ],
        'tools': const <Map<String, dynamic>>[
          <String, dynamic>{'google_search': <String, dynamic>{}},
        ],
        'generationConfig': <String, dynamic>{
          'temperature': 0.2,
          'thinkingConfig': <String, dynamic>{'thinkingBudget': 0},
        },
      };

      client = HttpClient();
      final request = await client.postUrl(uri);
      request.headers.contentType = ContentType.json;
      request.add(utf8.encode(jsonEncode(requestBody)));
      _log(
        'request startTime=${requestStartedAt.toIso8601String()} '
        'model=$_modelName toolsEnabled=true groundingEnabled=true '
        'promptLength=${prompt.length}',
      );

      final response = await request.close().timeout(geminiTimeout);
      final payload = await response.transform(utf8.decoder).join();
      if (_enableGroundingDebugLogs) {
        debugPrint(
          '[Grounding] response statusCode=${response.statusCode} '
          'type=$type rawResponseLength=${payload.length} '
          'bodyPreview=${_truncate(payload, 500)}',
        );
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw AppException('grounding_request_failed_$type');
      }

      final decoded = jsonDecode(payload);
      if (decoded is! Map<String, dynamic>) {
        throw AppException('grounding_invalid_response_$type');
      }
      final text = _extractJsonText(decoded);
      if (text.isEmpty) {
        throw AppException('grounding_empty_response_$type');
      }
      final parsed = jsonDecode(_sanitizeJsonText(text));
      if (parsed is! Map<String, dynamic>) {
        throw AppException('grounding_invalid_json_$type');
      }
      _summary(
        'section=$type elapsed=${stopwatch.elapsedMilliseconds}ms status=success',
      );
      return parsed;
    } on TimeoutException {
      _summary(
        'section=$type elapsed=${stopwatch.elapsedMilliseconds}ms status=failed',
      );
      throw AppException('grounding_request_timeout_$type');
    } catch (error) {
      _summary(
        'section=$type elapsed=${stopwatch.elapsedMilliseconds}ms status=failed',
      );
      rethrow;
    } finally {
      client?.close(force: true);
    }
  }

  String _extractJsonText(Map<String, dynamic> decoded) {
    final candidates = decoded['candidates'];
    if (candidates is! List) {
      return '';
    }
    for (final candidate in candidates.whereType<Map>()) {
      final content = candidate['content'];
      if (content is! Map) {
        continue;
      }
      final parts = content['parts'];
      if (parts is! List) {
        continue;
      }
      final buffer = StringBuffer();
      for (final part in parts.whereType<Map>()) {
        final text = (part['text'] as String?)?.trim() ?? '';
        if (text.isNotEmpty) {
          buffer.write(text);
        }
      }
      final merged = buffer.toString().trim();
      if (merged.isNotEmpty) {
        return merged;
      }
    }
    return '';
  }

  String _sanitizeJsonText(String value) {
    final trimmed = value.trim();
    if (trimmed.startsWith('```')) {
      return trimmed
          .replaceFirst(RegExp(r'^```(?:json)?\s*'), '')
          .replaceFirst(RegExp(r'\s*```$'), '')
          .trim();
    }
    return trimmed;
  }

  String _formatDate(DateTime value) {
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
}

class GroundedFlightResult {
  const GroundedFlightResult({
    required this.tripDirection,
    required this.airlineName,
    required this.airlineCode,
    required this.flightNumber,
    required this.departureDate,
    required this.departureTime,
    required this.arrivalTime,
    required this.departureCity,
    required this.arrivalCity,
    required this.departureAirportName,
    required this.departureAirportCode,
    required this.departureTerminal,
    required this.arrivalAirportName,
    required this.arrivalAirportCode,
    required this.arrivalTerminal,
    required this.estimatedPrice,
    required this.estimatedCostMin,
    required this.estimatedCostMax,
    required this.currency,
    required this.googleFlightsUrl,
    required this.originalCurrency,
    required this.originalPriceMin,
    required this.originalPriceMax,
    required this.priceVerified,
    required this.unverifiedReason,
  });

  final String tripDirection;
  final String? airlineName;
  final String? airlineCode;
  final String? flightNumber;
  final String? departureDate;
  final String? departureTime;
  final String? arrivalTime;
  final String? departureCity;
  final String? arrivalCity;
  final String? departureAirportName;
  final String? departureAirportCode;
  final String? departureTerminal;
  final String? arrivalAirportName;
  final String? arrivalAirportCode;
  final String? arrivalTerminal;
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

  factory GroundedFlightResult.fromJson(Map<String, dynamic> json) {
    return GroundedFlightResult(
      tripDirection: (json['tripDirection'] as String?)?.trim() ?? 'outbound',
      airlineName: (json['airlineName'] as String?)?.trim(),
      airlineCode: (json['airlineCode'] as String?)?.trim(),
      flightNumber: (json['flightNumber'] as String?)?.trim(),
      departureDate: (json['departureDate'] as String?)?.trim(),
      departureTime: (json['departureTime'] as String?)?.trim(),
      arrivalTime: (json['arrivalTime'] as String?)?.trim(),
      departureCity: (json['departureCity'] as String?)?.trim(),
      arrivalCity: (json['arrivalCity'] as String?)?.trim(),
      departureAirportName: (json['departureAirportName'] as String?)?.trim(),
      departureAirportCode: (json['departureAirportCode'] as String?)?.trim(),
      departureTerminal: (json['departureTerminal'] as String?)?.trim(),
      arrivalAirportName: (json['arrivalAirportName'] as String?)?.trim(),
      arrivalAirportCode: (json['arrivalAirportCode'] as String?)?.trim(),
      arrivalTerminal: (json['arrivalTerminal'] as String?)?.trim(),
      estimatedPrice: _readDouble(json['estimatedPrice']),
      estimatedCostMin: _readDouble(json['estimatedCostMin']),
      estimatedCostMax: _readDouble(json['estimatedCostMax']),
      currency: (json['currency'] as String?)?.trim() ?? '',
      googleFlightsUrl: (json['googleFlightsUrl'] as String?)?.trim(),
      originalCurrency: (json['originalCurrency'] as String?)?.trim(),
      originalPriceMin: _readDouble(json['originalPriceMin']),
      originalPriceMax: _readDouble(json['originalPriceMax']),
      priceVerified: (json['priceVerified'] as bool?) ?? false,
      unverifiedReason: (json['unverifiedReason'] as String?)?.trim(),
    );
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
}

class GroundedPriceSearchResult {
  const GroundedPriceSearchResult({
    required this.title,
    required this.subtitle,
    required this.estimatedCostMin,
    required this.estimatedCostMax,
    required this.currency,
    required this.costUnit,
    required this.externalUrl,
    required this.originalCurrency,
    required this.originalPriceMin,
    required this.originalPriceMax,
    required this.priceVerified,
    required this.unverifiedReason,
  });

  final String? title;
  final String? subtitle;
  final double? estimatedCostMin;
  final double? estimatedCostMax;
  final String currency;
  final String costUnit;
  final String? externalUrl;
  final String? originalCurrency;
  final double? originalPriceMin;
  final double? originalPriceMax;
  final bool priceVerified;
  final String? unverifiedReason;

  factory GroundedPriceSearchResult.fromJson(
    Map<String, dynamic> json, {
    required String fallbackCurrency,
    required String fallbackCostUnit,
  }) {
    return GroundedPriceSearchResult(
      title: (json['title'] as String?)?.trim(),
      subtitle: (json['subtitle'] as String?)?.trim(),
      estimatedCostMin: _readDouble(json['estimatedCostMin']),
      estimatedCostMax: _readDouble(json['estimatedCostMax']),
      currency: (json['currency'] as String?)?.trim() ?? fallbackCurrency,
      costUnit: (json['costUnit'] as String?)?.trim() ?? fallbackCostUnit,
      externalUrl: (json['externalUrl'] as String?)?.trim(),
      originalCurrency: (json['originalCurrency'] as String?)?.trim(),
      originalPriceMin: _readDouble(json['originalPriceMin']),
      originalPriceMax: _readDouble(json['originalPriceMax']),
      priceVerified: (json['priceVerified'] as bool?) ?? false,
      unverifiedReason: (json['unverifiedReason'] as String?)?.trim(),
    );
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
}
