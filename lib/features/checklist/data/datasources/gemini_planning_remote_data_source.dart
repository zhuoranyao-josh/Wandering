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
        'flights': <Map<String, dynamic>>[
          <String, dynamic>{
            'tripDirection': 'outbound|return',
            'airlineName': 'string',
            'airlineCode': 'string',
            'flightNumber': 'string',
            'departureDate': 'YYYY-MM-DD',
            'departureTime': 'HH:mm',
            'arrivalTime': 'HH:mm',
            'departureCity': 'string',
            'arrivalCity': 'string',
            'departureAirportName': 'string',
            'departureAirportCode': 'string',
            'departureTerminal': 'string',
            'arrivalAirportName': 'string',
            'arrivalAirportCode': 'string',
            'arrivalTerminal': 'string',
            'estimatedPrice': 'number',
            'currency': 'string',
            'googleFlightsUrl': 'string',
          },
        ],
        'hotelCandidates': <Map<String, dynamic>>[
          <String, dynamic>{
            'name': 'string',
            'expectedCostMin': 'number',
            'expectedCostMax': 'number',
            'costUnit': 'per_night',
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
            'costUnit': 'per_person',
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
            'type': 'trade_off|strategy|tips',
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
- essentials must only include: trade_off, strategy, tips.
- essentials count must be exactly 3, one entry per type.
- For essentials.type, only use: trade_off, strategy, tips.
- essentials.title must be short and aligned to essentials.type.
- essentials.mainText should be a compact phrase (around 3-6 English words).
- essentials.subText should be one short sentence.
- Do not generate estimatedPriceText.
- Use the provided currency code exactly.
- totalBudget is the total budget for the entire trip, not a daily budget.
- hotelBudget is the total lodging budget for the full stay, not a nightly budget.
- nightCount is the total number of hotel nights.
- maxHotelNightlyBudget = hotelBudget / nightCount.
- Every hotel candidate must satisfy expectedCostMax * nightCount <= hotelBudget.
- If travelerCount > 1 and hotel pricing is per room, still treat the hotel budget as per-night per-room budget. Do not reinterpret totalBudget as per-person per-day budget.
- accommodationPreference affects hotel tier preference, not a hard blacklist.
- budget: prefer budget-friendly, business, and strong value hotels.
- comfortable: prefer mid-range, comfortable, convenient, well-rated hotels; if a five-star hotel is truly within budget, it is allowed.
- luxury: prefer luxury, five-star, design-forward, and higher-service hotels, but still keep the full stay within hotelBudget.
- Recommend the best realistic hotel options within budget rather than filtering by brand alone.
- Do not invent unrealistically cheap luxury hotels.
- If a famous luxury hotel would exceed the stay budget, do not recommend it.
- All estimated prices must be in the user's selected currency.
- If currency is CNY, all estimatedCostMin and estimatedCostMax values must be Chinese Yuan.
- Do not output JPY, USD, AED, or local-currency amounts unless they are already converted into the selected currency.
- Hotel candidates must respect accommodationPreference while staying budget-realistic.
- restaurantQueries count must equal ${input.restaurantTargetCount}.
- activityQueries count must equal ${input.activityTargetCount}.
- hotelCandidates count must be between 1 and 3.
- remainingBudget must equal totalBudget - flightBudgetMax.
- Distribute dayIndex as evenly as possible across tripDays, using 1-based dayIndex.
- For relaxed pace, avoid putting too many activities on the same day.
- For packed pace, multiple activities per day are allowed.
 - flights must contain exactly 2 items: outbound first, return second.
 - flights[0].tripDirection must be "outbound"; flights[1].tripDirection must be "return".
 - For both flight items, all fields in the schema are mandatory and must be non-empty.
 - You may generate a realistic display-only flight plan (non-live), but fields must stay complete and coherent.
 - Do not output "Flight option" or generic city-to-city placeholders.
 - Each flight.googleFlightsUrl must be a route+date Google Flights search URL.
- outbound url: departureCity -> destination on startDate.
- return url: destination -> departureCity on endDate.
- All price fields must be numbers.
- For flights use estimatedPrice as a single numeric estimate.
- For hotel/restaurant/activity continue using estimatedCostMin and estimatedCostMax.
- Use costUnit = per_night for hotel candidates.
- Use costUnit = per_person for restaurant queries.
- Use costUnit = per_person or per_ticket for activity queries.
 - Prefer short titles, short subtitles, short reasons, and short tips.
 - If uncertain, still return valid compact JSON rather than prose.
 - Do not output booking advice, marketing copy, or recommendation slogans in any flight field.

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
