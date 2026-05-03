import 'checklist_destination_snapshot.dart';

class ChecklistDetail {
  const ChecklistDetail({
    required this.id,
    required this.destination,
    this.placeId,
    this.destinationSourceType,
    this.destinationSnapshot,
    this.latitude,
    this.longitude,
    this.departureCity,
    this.startDate,
    this.endDate,
    this.tripDays,
    this.nightCount,
    this.durationText,
    this.travelerCount,
    this.totalBudget,
    this.currency,
    this.currencySymbol,
    this.preferences = const <String>[],
    this.pace,
    this.accommodationPreference,
    this.basicInfoCompleted = false,
    this.planningStatus,
    this.budgetSplit,
    this.essentials = const <ChecklistEssential>[],
    this.proTip,
    this.items = const <ChecklistDetailItem>[],
  });

  final String id;
  final String destination;
  final String? placeId;
  final String? destinationSourceType;
  final ChecklistDestinationSnapshot? destinationSnapshot;
  final double? latitude;
  final double? longitude;
  final String? departureCity;
  final DateTime? startDate;
  final DateTime? endDate;
  final int? tripDays;
  final int? nightCount;
  final String? durationText;
  final int? travelerCount;
  final double? totalBudget;
  final String? currency;
  final String? currencySymbol;
  final List<String> preferences;
  final String? pace;
  final String? accommodationPreference;
  final bool basicInfoCompleted;
  final String? planningStatus;
  final ChecklistBudgetSplit? budgetSplit;
  final List<ChecklistEssential> essentials;
  final ChecklistProTip? proTip;
  final List<ChecklistDetailItem> items;

  // 是否满足“开始规划 / 生成计划”的基础信息完整性要求。
  bool get isBasicInfoComplete {
    return hasValidDestination &&
        startDate != null &&
        endDate != null &&
        (departureCity?.trim().isNotEmpty ?? false) &&
        (totalBudget ?? 0) > 0 &&
        (currency?.trim().isNotEmpty ?? false) &&
        (travelerCount ?? 0) > 0 &&
        (pace?.trim().isNotEmpty ?? false) &&
        (accommodationPreference?.trim().isNotEmpty ?? false) &&
        preferences.isNotEmpty;
  }

  bool get hasValidDestination => destinationSnapshot?.hasCoreData ?? false;

  String get resolvedDestinationName {
    final snapshotName = destinationSnapshot?.name.trim() ?? '';
    if (snapshotName.isNotEmpty) {
      return snapshotName;
    }
    return destination.trim();
  }

  double? get resolvedLatitude => destinationSnapshot?.latitude ?? latitude;

  double? get resolvedLongitude => destinationSnapshot?.longitude ?? longitude;

  String get resolvedCoverImageUrl {
    final snapshotImage = destinationSnapshot?.coverImageUrl?.trim() ?? '';
    return snapshotImage;
  }

  ChecklistDetail copyWith({
    String? id,
    String? destination,
    String? placeId,
    String? destinationSourceType,
    ChecklistDestinationSnapshot? destinationSnapshot,
    double? latitude,
    double? longitude,
    String? departureCity,
    DateTime? startDate,
    DateTime? endDate,
    int? tripDays,
    int? nightCount,
    String? durationText,
    int? travelerCount,
    double? totalBudget,
    String? currency,
    String? currencySymbol,
    List<String>? preferences,
    String? pace,
    String? accommodationPreference,
    bool? basicInfoCompleted,
    String? planningStatus,
    ChecklistBudgetSplit? budgetSplit,
    List<ChecklistEssential>? essentials,
    ChecklistProTip? proTip,
    List<ChecklistDetailItem>? items,
  }) {
    return ChecklistDetail(
      id: id ?? this.id,
      destination: destination ?? this.destination,
      placeId: placeId ?? this.placeId,
      destinationSourceType:
          destinationSourceType ?? this.destinationSourceType,
      destinationSnapshot: destinationSnapshot ?? this.destinationSnapshot,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      departureCity: departureCity ?? this.departureCity,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      tripDays: tripDays ?? this.tripDays,
      nightCount: nightCount ?? this.nightCount,
      durationText: durationText ?? this.durationText,
      travelerCount: travelerCount ?? this.travelerCount,
      totalBudget: totalBudget ?? this.totalBudget,
      currency: currency ?? this.currency,
      currencySymbol: currencySymbol ?? this.currencySymbol,
      preferences: preferences ?? this.preferences,
      pace: pace ?? this.pace,
      accommodationPreference:
          accommodationPreference ?? this.accommodationPreference,
      basicInfoCompleted: basicInfoCompleted ?? this.basicInfoCompleted,
      planningStatus: planningStatus ?? this.planningStatus,
      budgetSplit: budgetSplit ?? this.budgetSplit,
      essentials: essentials ?? this.essentials,
      proTip: proTip ?? this.proTip,
      items: items ?? this.items,
    );
  }
}

class ChecklistBudgetSplit {
  const ChecklistBudgetSplit({
    this.transportRatio,
    this.stayRatio,
    this.foodActivityRatio,
    this.flightBudgetMax,
    this.remainingBudget,
    this.hotelBudget,
    this.foodBudget,
    this.activityBudget,
    this.localTransportBudget,
    this.bufferBudget,
    this.currency,
    this.budgetWarning,
  });

  final double? transportRatio;
  final double? stayRatio;
  final double? foodActivityRatio;
  final double? flightBudgetMax;
  final double? remainingBudget;
  final double? hotelBudget;
  final double? foodBudget;
  final double? activityBudget;
  final double? localTransportBudget;
  final double? bufferBudget;
  final String? currency;
  final String? budgetWarning;

  bool get hasAnyValue =>
      transportRatio != null ||
      stayRatio != null ||
      foodActivityRatio != null ||
      flightBudgetMax != null ||
      remainingBudget != null ||
      hotelBudget != null ||
      foodBudget != null ||
      activityBudget != null ||
      localTransportBudget != null ||
      bufferBudget != null ||
      (currency?.trim().isNotEmpty ?? false) ||
      (budgetWarning?.trim().isNotEmpty ?? false);

  ChecklistBudgetSplit copyWith({
    double? transportRatio,
    double? stayRatio,
    double? foodActivityRatio,
    double? flightBudgetMax,
    double? remainingBudget,
    double? hotelBudget,
    double? foodBudget,
    double? activityBudget,
    double? localTransportBudget,
    double? bufferBudget,
    String? currency,
    String? budgetWarning,
  }) {
    return ChecklistBudgetSplit(
      transportRatio: transportRatio ?? this.transportRatio,
      stayRatio: stayRatio ?? this.stayRatio,
      foodActivityRatio: foodActivityRatio ?? this.foodActivityRatio,
      flightBudgetMax: flightBudgetMax ?? this.flightBudgetMax,
      remainingBudget: remainingBudget ?? this.remainingBudget,
      hotelBudget: hotelBudget ?? this.hotelBudget,
      foodBudget: foodBudget ?? this.foodBudget,
      activityBudget: activityBudget ?? this.activityBudget,
      localTransportBudget: localTransportBudget ?? this.localTransportBudget,
      bufferBudget: bufferBudget ?? this.bufferBudget,
      currency: currency ?? this.currency,
      budgetWarning: budgetWarning ?? this.budgetWarning,
    );
  }
}

class ChecklistEssential {
  const ChecklistEssential({
    required this.iconType,
    required this.title,
    required this.mainText,
    this.subText,
  });

  final String iconType;
  final String title;
  final String mainText;
  final String? subText;
}

class ChecklistProTip {
  const ChecklistProTip({this.tipTitle, this.tipDescription});

  final String? tipTitle;
  final String? tipDescription;

  bool get isEmpty {
    final title = tipTitle?.trim() ?? '';
    final description = tipDescription?.trim() ?? '';
    return title.isEmpty && description.isEmpty;
  }
}

class ChecklistDetailItem {
  const ChecklistDetailItem({
    required this.id,
    required this.groupType,
    required this.title,
    this.subtitle,
    required this.isCompleted,
    this.detailRouteTarget,
    this.type,
    this.estimatedPriceMin,
    this.estimatedPriceMax,
    this.estimatedCostMin,
    this.estimatedCostMax,
    this.costUnit,
    this.currency,
    this.originalCurrency,
    this.originalPriceMin,
    this.originalPriceMax,
    this.routeText,
    this.suggestedAirports = const <String>[],
    this.providerName,
    this.externalUrl,
    this.dataSource,
    this.accuracyNote,
    this.status,
    this.priceStatus,
    this.displayOrder,
    this.dayIndex,
    this.budgetWarning,
    this.googlePlaceId,
    this.address,
    this.photoUrl,
    this.latitude,
    this.longitude,
    this.rating,
    this.googleMapsUrl,
    this.airline,
    this.flightNumber,
    this.departureAirport,
    this.arrivalAirport,
    this.departureTime,
    this.arrivalTime,
    this.departureDate,
    this.arrivalDate,
    this.tripDirection,
    this.airlineCode,
    this.departureCity,
    this.arrivalCity,
    this.departureAirportName,
    this.departureAirportCode,
    this.departureTerminal,
    this.arrivalAirportName,
    this.arrivalAirportCode,
    this.arrivalTerminal,
    this.estimatedPrice,
    this.googleFlightsUrl,
  });

  final String id;
  final String groupType;
  final String title;
  final String? subtitle;
  final bool isCompleted;
  final String? detailRouteTarget;
  final String? type;
  final double? estimatedPriceMin;
  final double? estimatedPriceMax;
  final double? estimatedCostMin;
  final double? estimatedCostMax;
  final String? costUnit;
  final String? currency;
  final String? originalCurrency;
  final double? originalPriceMin;
  final double? originalPriceMax;
  final String? routeText;
  final List<String> suggestedAirports;
  final String? providerName;
  final String? externalUrl;
  final String? dataSource;
  final String? accuracyNote;
  final String? status;
  final String? priceStatus;
  final int? displayOrder;
  final int? dayIndex;
  final String? budgetWarning;
  final String? googlePlaceId;
  final String? address;
  final String? photoUrl;
  final double? latitude;
  final double? longitude;
  final double? rating;
  final String? googleMapsUrl;
  final String? airline;
  final String? flightNumber;
  final String? departureAirport;
  final String? arrivalAirport;
  final String? departureTime;
  final String? arrivalTime;
  final String? departureDate;
  final String? arrivalDate;
  final String? tripDirection;
  final String? airlineCode;
  final String? departureCity;
  final String? arrivalCity;
  final String? departureAirportName;
  final String? departureAirportCode;
  final String? departureTerminal;
  final String? arrivalAirportName;
  final String? arrivalAirportCode;
  final String? arrivalTerminal;
  final double? estimatedPrice;
  final String? googleFlightsUrl;

  ChecklistDetailItem copyWith({
    String? id,
    String? groupType,
    String? title,
    String? subtitle,
    bool? isCompleted,
    String? detailRouteTarget,
    String? type,
    double? estimatedPriceMin,
    double? estimatedPriceMax,
    double? estimatedCostMin,
    double? estimatedCostMax,
    String? costUnit,
    String? currency,
    String? originalCurrency,
    double? originalPriceMin,
    double? originalPriceMax,
    String? routeText,
    List<String>? suggestedAirports,
    String? providerName,
    String? externalUrl,
    String? dataSource,
    String? accuracyNote,
    String? status,
    String? priceStatus,
    int? displayOrder,
    int? dayIndex,
    String? budgetWarning,
    String? googlePlaceId,
    String? address,
    String? photoUrl,
    double? latitude,
    double? longitude,
    double? rating,
    String? googleMapsUrl,
    String? airline,
    String? flightNumber,
    String? departureAirport,
    String? arrivalAirport,
    String? departureTime,
    String? arrivalTime,
    String? departureDate,
    String? arrivalDate,
    String? tripDirection,
    String? airlineCode,
    String? departureCity,
    String? arrivalCity,
    String? departureAirportName,
    String? departureAirportCode,
    String? departureTerminal,
    String? arrivalAirportName,
    String? arrivalAirportCode,
    String? arrivalTerminal,
    double? estimatedPrice,
    String? googleFlightsUrl,
  }) {
    return ChecklistDetailItem(
      id: id ?? this.id,
      groupType: groupType ?? this.groupType,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      isCompleted: isCompleted ?? this.isCompleted,
      detailRouteTarget: detailRouteTarget ?? this.detailRouteTarget,
      type: type ?? this.type,
      estimatedPriceMin: estimatedPriceMin ?? this.estimatedPriceMin,
      estimatedPriceMax: estimatedPriceMax ?? this.estimatedPriceMax,
      estimatedCostMin: estimatedCostMin ?? this.estimatedCostMin,
      estimatedCostMax: estimatedCostMax ?? this.estimatedCostMax,
      costUnit: costUnit ?? this.costUnit,
      currency: currency ?? this.currency,
      originalCurrency: originalCurrency ?? this.originalCurrency,
      originalPriceMin: originalPriceMin ?? this.originalPriceMin,
      originalPriceMax: originalPriceMax ?? this.originalPriceMax,
      routeText: routeText ?? this.routeText,
      suggestedAirports: suggestedAirports ?? this.suggestedAirports,
      providerName: providerName ?? this.providerName,
      externalUrl: externalUrl ?? this.externalUrl,
      dataSource: dataSource ?? this.dataSource,
      accuracyNote: accuracyNote ?? this.accuracyNote,
      status: status ?? this.status,
      priceStatus: priceStatus ?? this.priceStatus,
      displayOrder: displayOrder ?? this.displayOrder,
      dayIndex: dayIndex ?? this.dayIndex,
      budgetWarning: budgetWarning ?? this.budgetWarning,
      googlePlaceId: googlePlaceId ?? this.googlePlaceId,
      address: address ?? this.address,
      photoUrl: photoUrl ?? this.photoUrl,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      rating: rating ?? this.rating,
      googleMapsUrl: googleMapsUrl ?? this.googleMapsUrl,
      airline: airline ?? this.airline,
      flightNumber: flightNumber ?? this.flightNumber,
      departureAirport: departureAirport ?? this.departureAirport,
      arrivalAirport: arrivalAirport ?? this.arrivalAirport,
      departureTime: departureTime ?? this.departureTime,
      arrivalTime: arrivalTime ?? this.arrivalTime,
      departureDate: departureDate ?? this.departureDate,
      arrivalDate: arrivalDate ?? this.arrivalDate,
      tripDirection: tripDirection ?? this.tripDirection,
      airlineCode: airlineCode ?? this.airlineCode,
      departureCity: departureCity ?? this.departureCity,
      arrivalCity: arrivalCity ?? this.arrivalCity,
      departureAirportName: departureAirportName ?? this.departureAirportName,
      departureAirportCode: departureAirportCode ?? this.departureAirportCode,
      departureTerminal: departureTerminal ?? this.departureTerminal,
      arrivalAirportName: arrivalAirportName ?? this.arrivalAirportName,
      arrivalAirportCode: arrivalAirportCode ?? this.arrivalAirportCode,
      arrivalTerminal: arrivalTerminal ?? this.arrivalTerminal,
      estimatedPrice: estimatedPrice ?? this.estimatedPrice,
      googleFlightsUrl: googleFlightsUrl ?? this.googleFlightsUrl,
    );
  }
}
