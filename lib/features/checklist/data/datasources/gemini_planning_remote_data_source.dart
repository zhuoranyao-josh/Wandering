import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../../../core/config/gemini_config.dart';
import '../../../../core/error/app_exception.dart';
import '../../domain/entities/checklist_detail.dart';

class GeminiPlanningRemoteDataSource {
  static const Duration _requestTimeout = Duration(seconds: 24);
  static const String _modelName = 'gemini-2.5-flash-lite';

  Future<GeminiGeneratedPlan> generatePlan({
    required GeminiPlanningInput input,
  }) async {
    final apiKey = geminiApiKey.trim();
    if (apiKey.isEmpty) {
      debugPrint('[ChecklistPlan] Gemini key missing');
      throw AppException('gemini_api_key_missing');
    }
    debugPrint('[ChecklistPlan] Gemini key exists length=${apiKey.length}');

    HttpClient? client;
    String responsePreview = '';
    try {
      final uri = Uri.https(
        'generativelanguage.googleapis.com',
        '/v1beta/models/$_modelName:generateContent',
        <String, String>{'key': apiKey},
      );
      debugPrint('[ChecklistPlan] Gemini request started');
      debugPrint('[ChecklistPlan] Gemini endpoint=${uri.origin}${uri.path}');

      final requestBody = <String, dynamic>{
        'contents': <Map<String, dynamic>>[
          <String, dynamic>{
            'parts': <Map<String, dynamic>>[
              <String, dynamic>{'text': _buildPrompt(input)},
            ],
          },
        ],
        'generationConfig': <String, dynamic>{
          'responseMimeType': 'application/json',
          'temperature': 0.4,
          'thinkingConfig': <String, dynamic>{'thinkingBudget': 0},
        },
      };

      client = HttpClient();
      final request = await client.postUrl(uri);
      request.headers.contentType = ContentType.json;
      request.add(utf8.encode(jsonEncode(requestBody)));

      final response = await request.close().timeout(_requestTimeout);
      final payload = await response.transform(utf8.decoder).join();
      responsePreview = payload;
      debugPrint(
        '[ChecklistPlan] Gemini response statusCode=${response.statusCode}',
      );
      debugPrint(
        '[ChecklistPlan] Gemini response preview='
        '${_truncate(payload, 500)}',
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw AppException(
          'Gemini request failed with statusCode=${response.statusCode}',
        );
      }

      debugPrint('[ChecklistPlan] Gemini JSON parse started');
      final decoded = jsonDecode(payload);
      if (decoded is! Map<String, dynamic>) {
        throw AppException('Gemini response is not a JSON object.');
      }

      final jsonText = _extractJsonText(decoded);
      if (jsonText.isEmpty) {
        throw AppException('Gemini response does not contain JSON text.');
      }

      final parsed = jsonDecode(jsonText);
      if (parsed is! Map<String, dynamic>) {
        throw AppException('Gemini parsed JSON is not a JSON object.');
      }
      debugPrint('[ChecklistPlan] Gemini JSON parse success');

      return GeminiGeneratedPlan.fromJson(
        parsed,
        defaultCurrency: input.currency,
        restaurantTargetCount: input.restaurantTargetCount,
        activityTargetCount: input.activityTargetCount,
      );
    } on FormatException catch (error) {
      debugPrint('[ChecklistPlan] Gemini JSON parse failed error=$error');
      debugPrint(
        '[ChecklistPlan] Gemini raw response='
        '${_truncate(responsePreview, 1000)}',
      );
      throw AppException('Gemini JSON parse failed: $error');
    } catch (error) {
      debugPrint('[ChecklistPlan] Gemini request failed error=$error');
      rethrow;
    } finally {
      client?.close(force: true);
    }
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

  String _buildPrompt(GeminiPlanningInput input) {
    final schemaJson = const JsonEncoder.withIndent('  ').convert(
      <String, dynamic>{
        'budgetSplit': <String, dynamic>{
          'transportRatio': 'number',
          'stayRatio': 'number',
          'foodActivityRatio': 'number',
          'flightBudgetMax': 'number',
          'remainingBudget': 'number',
          'hotelBudget': 'number',
          'foodBudget': 'number',
          'activityBudget': 'number',
          'localTransportBudget': 'number',
          'bufferBudget': 'number',
          'currency': 'string',
          'budgetWarning': 'string|null',
        },
        'flight': <String, dynamic>{
          'title': 'string',
          'subtitle': 'string',
          'flightNumber': 'string|null',
          'airline': 'string|null',
          'departureAirport': 'string|null',
          'arrivalAirport': 'string|null',
          'departureTime': 'string|null',
          'arrivalTime': 'string|null',
          'departureDate': 'string|null',
          'arrivalDate': 'string|null',
          'estimatedCostMin': 'number',
          'estimatedCostMax': 'number',
          'currency': 'string',
          'routeText': 'string',
          'suggestedAirports': <String>[],
          'providerName': 'Google Flights',
          'externalUrl': 'string',
          'accuracyNote': 'string|null',
          'budgetWarning': 'string|null',
        },
        'hotelCandidates': <Map<String, dynamic>>[
          <String, dynamic>{
            'name': 'string',
            'expectedCostMin': 'number',
            'expectedCostMax': 'number',
            'costUnit': 'per_night|total',
            'reason': 'string|null',
            'matchPreference': 'string|null',
            'budgetWarning': 'string|null',
          },
        ],
        'restaurantQueries': <Map<String, dynamic>>[
          <String, dynamic>{
            'query': 'string',
            'dayIndex': 'number|null',
            'estimatedCostMin': 'number',
            'estimatedCostMax': 'number',
            'costUnit': 'per_person|per_meal|total',
          },
        ],
        'activityQueries': <Map<String, dynamic>>[
          <String, dynamic>{
            'query': 'string',
            'dayIndex': 'number|null',
            'estimatedCostMin': 'number',
            'estimatedCostMax': 'number',
            'costUnit': 'per_person|per_ticket|total',
          },
        ],
        'essentials': <Map<String, dynamic>>[
          <String, dynamic>{
            'iconType': 'string',
            'title': 'string',
            'mainText': 'string',
            'subText': 'string|null',
          },
        ],
        'proTip': <String, dynamic>{
          'tipTitle': 'string',
          'tipDescription': 'string',
        },
      },
    );

    final inputJson = jsonEncode(input.toJson());
    return '''
Return compact JSON only.
No markdown.
No explanations.
No extra text before or after JSON.

MVP priority:
1. checklist items planning data
2. travel essentials
3. pro tip
4. budget suggestions

Rules:
- Keep strings concise and practical.
- Do not generate WEATHER content in essentials.
- Do not generate estimatedPriceText.
- Use the provided currency code exactly.
- totalBudget is the total budget for the entire trip, not a daily budget.
- hotelBudget is the total lodging budget for the full stay, not a nightly budget.
- nightCount is the total number of hotel nights.
- maxHotelNightlyBudget = hotelBudget / nightCount.
- Every hotel candidate must satisfy expectedCostMax * nightCount <= hotelBudget.
- If travelerCount > 1 and hotel pricing is per room, still treat the hotel budget as per-night per-room budget. Do not reinterpret totalBudget as per-person per-day budget.
- If accommodationPreference is comfortable, prefer mid-range, comfortable, well-located hotels.
- Do not recommend clearly luxury hotels such as luxury, five-star, Park Hyatt, Aman, Four Seasons, Ritz-Carlton, Mandarin Oriental, Bulgari, or Peninsula unless hotelBudget can realistically cover the full stay.
- If the budget is insufficient, do not invent cheap luxury hotels. Choose realistic options such as business hotel, mid-range hotel, budget hotel, capsule hotel, or apartment hotel based on the actual budget.
- All prices must use the user's currency exactly. If currency is CNY, all estimatedCostMin and estimatedCostMax values must be RMB estimates, not JPY, USD, or any other currency, and not converted from a mistaken daily budget.
- Hotel candidates must respect accommodationPreference.
- restaurantQueries count must equal ${input.restaurantTargetCount}.
- activityQueries count must equal ${input.activityTargetCount}.
- hotelCandidates count must be between 1 and 3.
- remainingBudget must equal totalBudget - flightBudgetMax.
- Distribute dayIndex as evenly as possible across tripDays, using 1-based dayIndex.
- For relaxed pace, avoid putting too many activities on the same day.
- For packed pace, multiple activities per day are allowed.
- flight.providerName must be "Google Flights".
- All price fields must be numbers, using min/max only.
- Prefer short titles, short subtitles, short reasons, and short tips.
- If uncertain, still return valid compact JSON rather than prose.
- Flight output must be structured and UI-safe.
- Do not put travel advice, booking advice, or marketing copy in flight.title, flight.subtitle, flight.routeText, or flight.accuracyNote.
- Do not output strings like "Book in advance", "Best value", "Recommended", or any similar suggestion text in the flight object.
- flight.title should be airline + flightNumber when both are known. If not known, use a short neutral title like "Flight option".
- flight.subtitle should only describe the route, not advice.
- flight.departureAirport and flight.arrivalAirport should prefer IATA code plus airport name when known.
- flight.departureTime, flight.arrivalTime, flight.departureDate, flight.arrivalDate, flight.flightNumber, flight.airline, and any terminal-specific detail must be null when not confidently known from the provided trip input.
- Never invent terminal information, gate information, airline names, flight numbers, or exact departure/arrival times.
- When exact flight details are unavailable, keep the flight object valid by returning null for unknown structured fields and keep route text minimal.

Input JSON:
$inputJson

Output JSON schema:
$schemaJson
''';
  }
}

class GeminiPlanningInput {
  GeminiPlanningInput({
    required this.id,
    required this.destination,
    required this.placeId,
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
  }) : restaurantTargetCount = _buildRestaurantTargetCount(tripDays),
       activityTargetCount = _buildActivityTargetCount(
         tripDays: tripDays,
         pace: pace,
       );

  final String id;
  final String destination;
  final String placeId;
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
    required this.flight,
    required this.hotelCandidates,
    required this.restaurantQueries,
    required this.activityQueries,
    required this.essentials,
    required this.proTip,
  });

  final ChecklistBudgetSplit budgetSplit;
  final GeminiFlightPlan? flight;
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
      flight: _readFlight(json['flight'], defaultCurrency: defaultCurrency),
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

  static GeminiFlightPlan? _readFlight(
    Object? value, {
    required String defaultCurrency,
  }) {
    if (value is! Map) {
      return null;
    }
    final map = value.cast<Object?, Object?>();
    return GeminiFlightPlan(
      title: _nullableText(map['title']) ?? '',
      subtitle: _nullableText(map['subtitle']) ?? '',
      flightNumber: _nullableText(map['flightNumber']),
      airline: _nullableText(map['airline']),
      departureAirport: _nullableText(map['departureAirport']),
      arrivalAirport: _nullableText(map['arrivalAirport']),
      departureTime: _nullableText(map['departureTime']),
      arrivalTime: _nullableText(map['arrivalTime']),
      departureDate: _nullableText(map['departureDate']),
      arrivalDate: _nullableText(map['arrivalDate']),
      estimatedCostMin: _readDouble(map['estimatedCostMin']),
      estimatedCostMax: _readDouble(map['estimatedCostMax']),
      currency: _nullableText(map['currency']) ?? defaultCurrency,
      routeText: _nullableText(map['routeText']) ?? '',
      suggestedAirports: _readStringList(map['suggestedAirports']),
      providerName: _nullableText(map['providerName']) ?? 'Google Flights',
      externalUrl: _nullableText(map['externalUrl']),
      accuracyNote: _nullableText(map['accuracyNote']),
      budgetWarning: _nullableText(map['budgetWarning']),
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
        .map(
          (map) => ChecklistEssential(
            iconType: _nullableText(map['iconType']) ?? '',
            title: _nullableText(map['title']) ?? '',
            mainText: _nullableText(map['mainText']) ?? '',
            subText: _nullableText(map['subText']),
          ),
        )
        .where((item) {
          final title = item.title.trim().toLowerCase();
          final iconType = item.iconType.trim().toLowerCase();
          if (item.title.trim().isEmpty || item.mainText.trim().isEmpty) {
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

  static List<String> _readStringList(Object? value) {
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

class GeminiFlightPlan {
  const GeminiFlightPlan({
    required this.title,
    required this.subtitle,
    required this.flightNumber,
    required this.airline,
    required this.departureAirport,
    required this.arrivalAirport,
    required this.departureTime,
    required this.arrivalTime,
    required this.departureDate,
    required this.arrivalDate,
    required this.estimatedCostMin,
    required this.estimatedCostMax,
    required this.currency,
    required this.routeText,
    required this.suggestedAirports,
    required this.providerName,
    required this.externalUrl,
    required this.accuracyNote,
    required this.budgetWarning,
  });

  final String title;
  final String subtitle;
  final String? flightNumber;
  final String? airline;
  final String? departureAirport;
  final String? arrivalAirport;
  final String? departureTime;
  final String? arrivalTime;
  final String? departureDate;
  final String? arrivalDate;
  final double? estimatedCostMin;
  final double? estimatedCostMax;
  final String currency;
  final String routeText;
  final List<String> suggestedAirports;
  final String providerName;
  final String? externalUrl;
  final String? accuracyNote;
  final String? budgetWarning;
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
