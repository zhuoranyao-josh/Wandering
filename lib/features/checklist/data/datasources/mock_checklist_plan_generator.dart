import 'dart:math';

import 'package:intl/intl.dart';

import '../../domain/entities/checklist_detail.dart';

class MockChecklistPlanResult {
  const MockChecklistPlanResult({
    required this.budgetSplit,
    required this.items,
  });

  final ChecklistBudgetSplit budgetSplit;
  final List<ChecklistDetailItem> items;
}

class MockChecklistPlanGenerator {
  const MockChecklistPlanGenerator();

  MockChecklistPlanResult generate({
    required String journeyId,
    required ChecklistDetail detail,
  }) {
    final random = Random(_stableSeed(journeyId));
    final destination = detail.destination.trim().isEmpty
        ? 'Destination'
        : detail.destination.trim();
    final departureCity = (detail.departureCity ?? '').trim().isEmpty
        ? 'Departure'
        : detail.departureCity!.trim();
    final currency = (detail.currency ?? '').trim().isEmpty
        ? 'CNY'
        : detail.currency!.trim();
    final totalBudget = (detail.totalBudget ?? 0) > 0
        ? detail.totalBudget!
        : 8000.0;
    final tripDays = _resolveTripDays(detail);

    final split = _buildBudgetSplit(
      random: random,
      totalBudget: totalBudget,
      currency: currency,
      pace: detail.pace ?? 'balanced',
      accommodationPreference: detail.accommodationPreference ?? 'comfortable',
    );

    final items =
        <ChecklistDetailItem>[
          _flightItem(
            random: random,
            departureCity: departureCity,
            destination: destination,
            currency: currency,
            budgetMax: split.flightBudgetMax ?? (totalBudget * 0.3),
          ),
          _weatherItem(random: random, tripDays: tripDays),
          _hotelItem(
            random: random,
            destination: destination,
            currency: currency,
            preference: detail.accommodationPreference ?? 'comfortable',
            budget: split.hotelBudget,
          ),
          ..._foodItems(
            random: random,
            destination: destination,
            currency: currency,
          ),
          ..._activityItems(
            random: random,
            destination: destination,
            currency: currency,
          ),
          _essentialsItem(
            destination: destination,
            pace: detail.pace ?? 'balanced',
            weatherAdvice: 'Bring a light jacket and umbrella.',
          ),
        ]..sort((a, b) {
          final orderA = a.displayOrder ?? 0;
          final orderB = b.displayOrder ?? 0;
          if (orderA != orderB) return orderA.compareTo(orderB);
          return a.id.compareTo(b.id);
        });

    return MockChecklistPlanResult(budgetSplit: split, items: items);
  }

  ChecklistBudgetSplit _buildBudgetSplit({
    required Random random,
    required double totalBudget,
    required String currency,
    required String pace,
    required String accommodationPreference,
  }) {
    final paceTransportBoost = switch (pace.trim()) {
      'intensive' => 3.0,
      'relaxed' => -2.0,
      _ => 0.0,
    };
    final stayBoost = switch (accommodationPreference.trim()) {
      'premium' => 6.0,
      'budget' => -6.0,
      _ => 0.0,
    };

    final transportRatio = _clampPercent(28 + paceTransportBoost);
    final stayRatio = _clampPercent(42 + stayBoost);
    var foodActivityRatio = 100 - transportRatio - stayRatio;
    if (foodActivityRatio < 15) {
      foodActivityRatio = 15;
    }
    final totalRatio = transportRatio + stayRatio + foodActivityRatio;
    final normalizedTransport = transportRatio / totalRatio * 100;
    final normalizedStay = stayRatio / totalRatio * 100;
    final normalizedFoodActivity = foodActivityRatio / totalRatio * 100;

    final flightBudgetMax = _roundTo10(totalBudget * normalizedTransport / 100);
    final remainingBudget = _roundTo10(totalBudget - flightBudgetMax);
    final bufferPercent = random.nextInt(6) + 10; // 10%-15%
    final bufferBudget = _roundTo10(remainingBudget * bufferPercent / 100);

    final allocatable = max(0, remainingBudget - bufferBudget);
    final hotelBudget = _roundTo10(allocatable * 0.5);
    final foodBudget = _roundTo10(allocatable * 0.22);
    final activityBudget = _roundTo10(allocatable * 0.18);
    final localTransportBudget = _roundTo10(
      max(0, allocatable - hotelBudget - foodBudget - activityBudget),
    );

    return ChecklistBudgetSplit(
      transportRatio: normalizedTransport,
      stayRatio: normalizedStay,
      foodActivityRatio: normalizedFoodActivity,
      flightBudgetMax: flightBudgetMax,
      remainingBudget: remainingBudget,
      hotelBudget: hotelBudget,
      foodBudget: foodBudget,
      activityBudget: activityBudget,
      localTransportBudget: localTransportBudget,
      bufferBudget: bufferBudget,
      currency: currency,
      budgetWarning: remainingBudget < 0
          ? 'Remaining budget is below zero. Consider increasing total budget.'
          : null,
    );
  }

  ChecklistDetailItem _flightItem({
    required Random random,
    required String departureCity,
    required String destination,
    required String currency,
    required double budgetMax,
  }) {
    final maxPrice = _roundTo10(max(1200, budgetMax));
    final minPrice = _roundTo10(
      max(800, maxPrice * (0.72 + random.nextDouble() * 0.08)),
    );
    final provider = _pick(random, const <String>[
      'Google Flights',
      'Skyscanner',
      'Trip.com',
    ]);
    final airline = _pick(random, const <String>[
      'China Eastern Airlines',
      'Air China',
      'Japan Airlines',
    ]);
    final flightCodePrefix = switch (airline) {
      'China Eastern Airlines' => 'MU',
      'Japan Airlines' => 'JL',
      _ => 'CA',
    };
    final flightNumber = '$flightCodePrefix${5000 + random.nextInt(500)}';
    final departureAirport = _mockAirportLabel(
      city: departureCity,
      isDeparture: true,
      random: random,
    );
    final arrivalAirport = _mockAirportLabel(
      city: destination,
      isDeparture: false,
      random: random,
    );
    final departureMinutes =
        (7 + random.nextInt(6)) * 60 + random.nextInt(2) * 30;
    final flightDurationMinutes = 120 + random.nextInt(121); // 2h - 4h
    final arrivalMinutes = departureMinutes + flightDurationMinutes;
    final departureTime = _formatTime(departureMinutes);
    final arrivalTime = _formatTime(arrivalMinutes);
    final url = switch (provider) {
      'Skyscanner' => 'https://www.skyscanner.com/transport/flights',
      'Trip.com' => 'https://www.trip.com/flights',
      _ => 'https://www.google.com/travel/flights',
    };
    return ChecklistDetailItem(
      id: 'flight',
      type: 'flight',
      groupType: 'transportation',
      title: '$airline $flightNumber',
      subtitle:
          '$departureTime $departureAirport\n$arrivalTime $arrivalAirport',
      routeText: '$departureCity -> $destination',
      estimatedPriceMin: minPrice,
      estimatedPriceMax: maxPrice,
      currency: currency,
      suggestedAirports: <String>[departureAirport, arrivalAirport],
      providerName: provider,
      externalUrl: url,
      dataSource: 'demo_estimated',
      accuracyNote: 'Demo estimate. Check live prices before booking.',
      status: 'suggested',
      displayOrder: 10,
      isCompleted: false,
    );
  }

  String _formatTime(int totalMinutes) {
    final normalized = totalMinutes % (24 * 60);
    final hour = (normalized ~/ 60).toString().padLeft(2, '0');
    final minute = (normalized % 60).toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _mockAirportLabel({
    required String city,
    required bool isDeparture,
    required Random random,
  }) {
    final normalized = city.trim().toLowerCase();
    if (normalized.contains('shanghai')) {
      return isDeparture
          ? 'Shanghai Hongqiao SHA T2'
          : _pick(random, const <String>[
              'Shanghai Pudong PVG T2',
              'Shanghai Hongqiao SHA T2',
            ]);
    }
    if (normalized.contains('tokyo')) {
      return isDeparture
          ? 'Tokyo Haneda HND T3'
          : _pick(random, const <String>[
              'Tokyo Haneda HND T3',
              'Tokyo Narita NRT T1',
            ]);
    }
    if (normalized.contains('beijing')) {
      return isDeparture
          ? 'Beijing Daxing PKX T1'
          : _pick(random, const <String>[
              'Beijing Capital PEK T3',
              'Beijing Daxing PKX T1',
            ]);
    }
    if (normalized.contains('osaka')) {
      return isDeparture
          ? 'Osaka Itami ITM T1'
          : _pick(random, const <String>[
              'Osaka Kansai KIX T1',
              'Osaka Itami ITM T1',
            ]);
    }

    final words = city.trim().isEmpty ? 'City' : city.trim();
    final code = words
        .split(RegExp(r'\s+'))
        .where((value) => value.isNotEmpty)
        .map((value) => value[0].toUpperCase())
        .take(3)
        .join()
        .padRight(3, 'X')
        .substring(0, 3);
    return '$words International $code T1';
  }

  ChecklistDetailItem _weatherItem({
    required Random random,
    required int tripDays,
  }) {
    final minTemp = 12 + random.nextInt(8);
    final maxTemp = minTemp + 8 + random.nextInt(6);
    final rainPossible = random.nextBool();
    final rainText = rainPossible
        ? 'Rain possible on one day.'
        : 'Mostly clear.';
    return ChecklistDetailItem(
      id: 'weather',
      type: 'weather',
      groupType: 'activity',
      title: 'Weather',
      subtitle:
          '$minTemp C - $maxTemp C. $rainText Bring a light jacket and umbrella.',
      dataSource: 'demo_estimated',
      accuracyNote: 'Demo estimate. Check live prices before booking.',
      status: 'suggested',
      displayOrder: tripDays > 3 ? 15 : 14,
      isCompleted: false,
    );
  }

  ChecklistDetailItem _hotelItem({
    required Random random,
    required String destination,
    required String currency,
    required String preference,
    required double? budget,
  }) {
    final area = _pick(random, _areas(destination));
    final provider = _pick(random, const <String>[
      'Booking',
      'Trip.com',
      'Expedia',
    ]);
    final url = switch (provider) {
      'Trip.com' => 'https://www.trip.com/hotels',
      'Expedia' => 'https://www.expedia.com/Hotels',
      _ => 'https://www.booking.com',
    };
    final base = budget != null && budget > 0 ? budget / 4 : 700;
    final minNight = _roundTo10(base * 0.78);
    final maxNight = _roundTo10(base * 1.08);
    return ChecklistDetailItem(
      id: 'hotel',
      type: 'hotel',
      groupType: 'stay',
      title: 'Hotel',
      subtitle:
          '$area area - Estimated $currency ${_money(minNight)} - ${_money(maxNight)} / night',
      estimatedPriceMin: minNight,
      estimatedPriceMax: maxNight,
      estimatedCostMin: budget,
      estimatedCostMax: budget,
      costUnit: 'per_night',
      currency: currency,
      providerName: provider,
      externalUrl: url,
      dataSource: 'demo_estimated',
      accuracyNote: 'Demo estimate. Check live prices before booking.',
      status: 'suggested',
      displayOrder: 20,
      isCompleted: false,
      detailRouteTarget: preference,
    );
  }

  List<ChecklistDetailItem> _foodItems({
    required Random random,
    required String destination,
    required String currency,
  }) {
    final templates = <(String id, String title, String subtitle, int order)>[
      ('food_1', 'Ramen near $destination', 'Comfort meal after city walk', 30),
      ('food_2', 'Sushi experience', 'Fresh local style option', 31),
      ('food_3', 'Local street food', 'Quick bites between attractions', 32),
      ('food_4', 'Cafe break', 'Light meal and coffee stop', 33),
    ];
    final count = 2 + random.nextInt(3); // 2-4
    return templates
        .take(count)
        .map((item) {
          final min = _roundTo10(70 + random.nextInt(50).toDouble());
          final max = _roundTo10(min + 50 + random.nextInt(80).toDouble());
          return ChecklistDetailItem(
            id: item.$1,
            type: 'food',
            groupType: 'food',
            title: item.$2,
            subtitle:
                '${item.$3} - Estimated $currency ${_money(min)} - ${_money(max)} / person',
            estimatedCostMin: min,
            estimatedCostMax: max,
            costUnit: 'per_person',
            currency: currency,
            dayIndex: random.nextInt(5) + 1,
            dataSource: 'demo_estimated',
            accuracyNote: 'Demo estimate. Check live prices before booking.',
            status: 'suggested',
            displayOrder: item.$4,
            isCompleted: false,
          );
        })
        .toList(growable: false);
  }

  List<ChecklistDetailItem> _activityItems({
    required Random random,
    required String destination,
    required String currency,
  }) {
    final templates = <(String id, String title, String subtitle, int order)>[
      ('activity_1', 'City Landmark', 'Classic must-see in $destination', 50),
      ('activity_2', 'Museum Visit', 'Indoor option with local culture', 51),
      ('activity_3', 'Skyline Viewpoint', 'Great evening photos', 52),
      ('activity_4', 'Popular Theme Spot', 'Half-day attraction option', 53),
      (
        'activity_5',
        'Local Neighborhood Walk',
        'Street vibe and hidden gems',
        54,
      ),
    ];
    final count = 2 + random.nextInt(4); // 2-5
    return templates
        .take(count)
        .map((item) {
          final min = _roundTo10(100 + random.nextInt(180).toDouble());
          final max = _roundTo10(min + 100 + random.nextInt(220).toDouble());
          return ChecklistDetailItem(
            id: item.$1,
            type: 'activity',
            groupType: 'activity',
            title: item.$2,
            subtitle:
                '${item.$3} - Estimated $currency ${_money(min)} - ${_money(max)} / person',
            estimatedCostMin: min,
            estimatedCostMax: max,
            currency: currency,
            dayIndex: random.nextInt(5) + 1,
            externalUrl: 'https://www.google.com/travel',
            dataSource: 'demo_estimated',
            accuracyNote: 'Demo estimate. Check live prices before booking.',
            status: 'suggested',
            displayOrder: item.$4,
            isCompleted: false,
          );
        })
        .toList(growable: false);
  }

  ChecklistDetailItem _essentialsItem({
    required String destination,
    required String pace,
    required String weatherAdvice,
  }) {
    final paceText = switch (pace.trim()) {
      'intensive' => 'Keep one flexible slot each day.',
      'relaxed' => 'Pack light and keep your day simple.',
      _ => 'Balance indoor and outdoor stops.',
    };
    return ChecklistDetailItem(
      id: 'essentials',
      type: 'essentials',
      groupType: 'activity',
      title: 'Essentials',
      subtitle:
          'For $destination: $weatherAdvice Bring power bank, passport, and comfortable shoes. $paceText',
      dataSource: 'demo_estimated',
      accuracyNote: 'Demo estimate. Check live prices before booking.',
      status: 'suggested',
      displayOrder: 80,
      isCompleted: false,
    );
  }

  List<String> _areas(String destination) {
    final normalized = destination.toLowerCase();
    if (normalized.contains('tokyo')) {
      return const <String>['Shinjuku', 'Ueno', 'Asakusa'];
    }
    if (normalized.contains('osaka')) {
      return const <String>['Namba', 'Umeda', 'Shinsaibashi'];
    }
    if (normalized.contains('shanghai')) {
      return const <String>['The Bund', 'Jingan', 'Xintiandi'];
    }
    return const <String>['City Center', 'Old Town', 'Riverside'];
  }

  int _resolveTripDays(ChecklistDetail detail) {
    if ((detail.tripDays ?? 0) > 0) {
      return detail.tripDays!;
    }
    if (detail.startDate == null || detail.endDate == null) {
      return 5;
    }
    final diff = detail.endDate!.difference(detail.startDate!).inDays + 1;
    return diff < 1 ? 5 : diff;
  }

  int _stableSeed(String value) {
    var hash = 0;
    for (final code in value.codeUnits) {
      hash = 0x1fffffff & (hash + code);
      hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
      hash ^= (hash >> 6);
    }
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    hash ^= (hash >> 11);
    hash = 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
    return hash;
  }

  double _roundTo10(double value) {
    return (value / 10).roundToDouble() * 10;
  }

  double _clampPercent(num value) {
    return value.clamp(15, 60).toDouble();
  }

  String _money(double value) {
    return NumberFormat.decimalPattern().format(value.round());
  }

  T _pick<T>(Random random, List<T> values) {
    return values[random.nextInt(values.length)];
  }
}
