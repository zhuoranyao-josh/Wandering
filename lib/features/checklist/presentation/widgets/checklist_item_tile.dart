import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/widgets/app_network_image.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/checklist_detail.dart';
import '../support/checklist_price_formatter.dart';

class ChecklistItemTile extends StatelessWidget {
  const ChecklistItemTile({
    super.key,
    required this.item,
    required this.onToggleCompleted,
    this.onTap,
  });

  final ChecklistDetailItem item;
  final ValueChanged<bool> onToggleCompleted;
  final VoidCallback? onTap;

  static const double _cardRadius = 10;
  static const double _transportCardRadius = 8;
  static const double _hotelCardRadius = 9;
  static const double _defaultTitleFontSize = 14;
  static const double _defaultSubtitleFontSize = 12;
  static const double _defaultMetaFontSize = 11;
  static const double _flightPrimaryFontSize = 12.5;
  static const double _flightSecondaryFontSize = 12.5;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    if (_isTransportFlightItem(item)) {
      return _buildTransportFlightTile(t);
    }
    if (_isHotelStayItem(item)) {
      return _buildHotelStayTile(t);
    }
    if (_isFoodOrActivityItem(item)) {
      return _buildFoodActivityTile(t);
    }
    return _buildDefaultTile(t);
  }

  Widget _buildDefaultTile(AppLocalizations? t) {
    final demoBadge = item.dataSource?.trim() == 'demo_estimated'
        ? t?.checklistDemoEstimateBadge
        : null;
    final priceDisplay = ChecklistPriceFormatter.build(item: item, t: t);
    final accuracyText = (item.accuracyNote ?? '').trim();
    final hasExternalUrl = (item.externalUrl ?? '').trim().isNotEmpty;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(_cardRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(_cardRadius),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_cardRadius),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Checkbox(
                value: item.isCompleted,
                onChanged: (value) => onToggleCompleted(value ?? false),
                visualDensity: VisualDensity.compact,
                activeColor: const Color(0xFF3B6EEA),
                checkColor: Colors.white,
                side: const BorderSide(color: Color(0xFFC5C8D0), width: 1.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            item.title.trim(),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: _defaultTitleFontSize,
                              fontWeight: FontWeight.w600,
                              color: item.isCompleted
                                  ? const Color(0xFF9CA3AF)
                                  : const Color(0xFF111827),
                              decoration: item.isCompleted
                                  ? TextDecoration.lineThrough
                                  : TextDecoration.none,
                            ),
                          ),
                        ),
                        if (demoBadge != null) ...<Widget>[
                          const SizedBox(width: 8),
                          _Badge(text: demoBadge),
                        ],
                      ],
                    ),
                    if ((item.subtitle ?? '').trim().isNotEmpty) ...<Widget>[
                      const SizedBox(height: 3),
                      Text(
                        item.subtitle!.trim(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: _defaultSubtitleFontSize,
                          color: Color(0xFF98A2B3),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                    if (priceDisplay.primaryText.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 4),
                      Text(
                        priceDisplay.primaryText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: _defaultMetaFontSize,
                          color: Color(0xFF3B6EEA),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                    if (accuracyText.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 4),
                      Text(
                        accuracyText,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF9CA3AF),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  if (hasExternalUrl) ...<Widget>[
                    const Icon(
                      Icons.open_in_new_rounded,
                      color: Color(0xFF98A2B3),
                      size: 18,
                    ),
                    const SizedBox(height: 8),
                  ],
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xFFCDD2DB),
                    size: 20,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTransportFlightTile(AppLocalizations? t) {
    final viewData = _TransportFlightViewData.fromItem(item: item, t: t);
    final titleColor = item.isCompleted
        ? const Color(0xFF6B7280)
        : const Color(0xFF111827);
    final airportColor = item.isCompleted
        ? const Color(0xFF9CA3AF)
        : const Color(0xFF667085);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(_transportCardRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(_transportCardRadius),
        child: Ink(
          decoration: BoxDecoration(
            color: item.isCompleted ? const Color(0xFFF3F4F6) : Colors.white,
            borderRadius: BorderRadius.circular(_transportCardRadius),
            border: Border.all(color: const Color(0xFFE5E7EB)),
            boxShadow: item.isCompleted
                ? const <BoxShadow>[]
                : const <BoxShadow>[
                    BoxShadow(
                      color: Color(0x05000000),
                      blurRadius: 6,
                      offset: Offset(0, 1),
                    ),
                  ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // 顶部信息：logo + 航空公司 + 航班号 + 价格 badge。
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _AirlineLogo(
                      url: viewData.logoUrl,
                      isCompleted: item.isCompleted,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            viewData.primaryTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: _flightPrimaryFontSize,
                              fontWeight: FontWeight.w600,
                              height: 1.15,
                              color: titleColor,
                            ),
                          ),
                          if (viewData.secondaryTitle != null) ...<Widget>[
                            const SizedBox(height: 4),
                            Text(
                              viewData.secondaryTitle!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: _flightSecondaryFontSize,
                                fontWeight: FontWeight.w500,
                                height: 1.1,
                                color: titleColor,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (viewData.estimateBadgeText != null) ...<Widget>[
                      const SizedBox(width: 8),
                      _EstimatePriceBadge(text: viewData.estimateBadgeText!),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 56,
                  child: viewData.hasRoute
                      ? _FlightFixedTemplateBlock(
                          departureTime: viewData.departureTimeDisplay,
                          arrivalTime: viewData.arrivalTimeDisplay,
                          departureAirport: viewData.departureAirportDisplay,
                          arrivalAirport: viewData.arrivalAirportDisplay,
                          airportColor: airportColor,
                          timeColor: titleColor,
                          routeSummary: viewData.routeSummary,
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHotelStayTile(AppLocalizations? t) {
    return _buildCompactItemTile(t: t, placeholderIcon: Icons.hotel_rounded);
  }

  Widget _buildFoodActivityTile(AppLocalizations? t) {
    final isFood =
        (item.type ?? '').trim().toLowerCase() == 'food' ||
        item.groupType.trim().toLowerCase() == 'food';
    final placeholderIcon = isFood
        ? Icons.restaurant_rounded
        : Icons.local_activity_rounded;

    return _buildCompactItemTile(t: t, placeholderIcon: placeholderIcon);
  }

  Widget _buildCompactItemTile({
    required AppLocalizations? t,
    required IconData placeholderIcon,
  }) {
    final viewData = _CompactItemViewData.fromItem(item: item, t: t);
    return _ChecklistCompactItemCard(
      item: item,
      onTap: onTap,
      onToggleCompleted: onToggleCompleted,
      title: viewData.title,
      imageUrl: viewData.imageUrl,
      shortAddress: viewData.shortAddress,
      displayPrice: viewData.displayPrice,
      placeholderIcon: placeholderIcon,
    );
  }

  bool _isTransportFlightItem(ChecklistDetailItem value) {
    final type = (value.type ?? '').trim().toLowerCase();
    final group = value.groupType.trim().toLowerCase();
    return type == 'flight' || group == 'transportation';
  }

  bool _isHotelStayItem(ChecklistDetailItem value) {
    final type = (value.type ?? '').trim().toLowerCase();
    final group = value.groupType.trim().toLowerCase();
    return type == 'hotel' || group == 'stay';
  }

  bool _isFoodOrActivityItem(ChecklistDetailItem value) {
    final type = (value.type ?? '').trim().toLowerCase();
    final group = value.groupType.trim().toLowerCase();
    if (type == 'food' || type == 'activity') {
      return true;
    }
    if (group == 'food') {
      return true;
    }
    if (group == 'activity' &&
        type != 'weather' &&
        type != 'essentials' &&
        type != 'budget') {
      return true;
    }
    return false;
  }
}

class _TransportFlightViewData {
  const _TransportFlightViewData({
    required this.primaryTitle,
    required this.secondaryTitle,
    required this.logoUrl,
    required this.departureTimeDisplay,
    required this.arrivalTimeDisplay,
    required this.departureAirportDisplay,
    required this.arrivalAirportDisplay,
    required this.routeSummary,
    required this.estimateBadgeText,
  });

  final String primaryTitle;
  final String? secondaryTitle;
  final String? logoUrl;
  final String? departureTimeDisplay;
  final String? arrivalTimeDisplay;
  final String? departureAirportDisplay;
  final String? arrivalAirportDisplay;
  final String routeSummary;
  final String? estimateBadgeText;

  bool get hasTimeline =>
      departureTimeDisplay != null &&
      arrivalTimeDisplay != null &&
      departureAirportDisplay != null &&
      arrivalAirportDisplay != null;

  bool get hasRoute =>
      hasTimeline ||
      routeSummary.trim().isNotEmpty ||
      departureAirportDisplay != null ||
      arrivalAirportDisplay != null;

  factory _TransportFlightViewData.fromItem({
    required ChecklistDetailItem item,
    required AppLocalizations? t,
  }) {
    final titles = _buildTitles(item);
    final estimateBadgeText = _buildEstimateBadgeText(item: item, t: t);
    final timeline = _readStructuredTimeline(item);
    final logoUrl = _extractLogoUrl(item);
    final routeSummary = _buildRouteSummary(item, timeline);

    return _TransportFlightViewData(
      primaryTitle: titles.$1,
      secondaryTitle: titles.$2,
      logoUrl: logoUrl,
      departureTimeDisplay: timeline.$1,
      arrivalTimeDisplay: timeline.$2,
      departureAirportDisplay: timeline.$3,
      arrivalAirportDisplay: timeline.$4,
      routeSummary: routeSummary,
      estimateBadgeText: estimateBadgeText,
    );
  }

  static (String, String?) _buildTitles(ChecklistDetailItem item) {
    final airline = (item.airline ?? '').trim();
    final flightNumber = (item.flightNumber ?? '').trim();
    final rawTitle = item.title.trim();
    if (airline.isNotEmpty && flightNumber.isNotEmpty) {
      return (airline, flightNumber);
    }
    if (airline.isNotEmpty) {
      return (airline, null);
    }
    if (flightNumber.isNotEmpty) {
      return (flightNumber, null);
    }
    if (rawTitle.isNotEmpty) {
      return (rawTitle, null);
    }
    final provider = (item.providerName ?? '').trim();
    return (provider.isNotEmpty ? provider : item.groupType, null);
  }

  static String? _buildEstimateBadgeText({
    required ChecklistDetailItem item,
    required AppLocalizations? t,
  }) {
    final estimateValue = _readEstimateValue(item);
    if (estimateValue == null) {
      return null;
    }

    final currencySymbol = _resolveCurrencySymbol(item.currency);
    final amountText = NumberFormat.decimalPattern().format(estimateValue);
    final prefix = t?.checklistEstimateShort ?? 'EST.';
    return '$prefix $currencySymbol$amountText';
  }

  // 航班卡右上角价格固定展示估算均值，不展示区间和单位。
  static double? _readEstimateValue(ChecklistDetailItem item) {
    final structuredMin = item.estimatedCostMin;
    final structuredMax = item.estimatedCostMax;
    if (structuredMin != null && structuredMax != null) {
      return (structuredMin + structuredMax) / 2;
    }
    if (structuredMin != null || structuredMax != null) {
      return structuredMin ?? structuredMax;
    }

    final legacyMin = item.estimatedPriceMin;
    final legacyMax = item.estimatedPriceMax;
    if (legacyMin != null && legacyMax != null) {
      return (legacyMin + legacyMax) / 2;
    }
    return legacyMin ?? legacyMax;
  }

  static String _resolveCurrencySymbol(String? currencyCode) {
    switch ((currencyCode ?? '').trim().toUpperCase()) {
      case 'CNY':
      case 'JPY':
        return '\u00A5';
      case 'USD':
        return '\$';
      case 'EUR':
        return '\u20AC';
      case 'GBP':
        return '\u00A3';
      default:
        final code = (currencyCode ?? '').trim();
        return code.isNotEmpty ? '$code ' : '\u00A5';
    }
  }

  static (String?, String?, String?, String?) _readStructuredTimeline(
    ChecklistDetailItem item,
  ) {
    final departureAirport = (item.departureAirport ?? '').trim();
    final arrivalAirport = (item.arrivalAirport ?? '').trim();
    final departureTime = (item.departureTime ?? '').trim();
    final arrivalTime = (item.arrivalTime ?? '').trim();
    return (
      departureTime.isNotEmpty ? departureTime : null,
      arrivalTime.isNotEmpty ? arrivalTime : null,
      departureAirport.isNotEmpty ? departureAirport : null,
      arrivalAirport.isNotEmpty ? arrivalAirport : null,
    );
  }

  static String _buildRouteSummary(
    ChecklistDetailItem item,
    (String?, String?, String?, String?) timeline,
  ) {
    final routeSummary = <String>[
      if ((item.departureDate ?? '').trim().isNotEmpty)
        item.departureDate!.trim(),
      if (timeline.$3 != null || timeline.$4 != null)
        [timeline.$3, timeline.$4]
            .whereType<String>()
            .where((value) => value.trim().isNotEmpty)
            .join(' -> '),
      if ((item.arrivalDate ?? '').trim().isNotEmpty &&
          (item.arrivalDate ?? '').trim() != (item.departureDate ?? '').trim())
        item.arrivalDate!.trim(),
    ].where((value) => value.trim().isNotEmpty).join('  ');
    if (routeSummary.isNotEmpty) {
      return routeSummary;
    }
    return (item.subtitle ?? '').trim();
  }

  static String? _extractLogoUrl(ChecklistDetailItem item) {
    final merged = '${item.subtitle ?? ''} ${item.routeText ?? ''}'.trim();
    final match = RegExp(
      r'(https?:\/\/\S+\.(?:png|jpg|jpeg|webp|gif))',
      caseSensitive: false,
    ).firstMatch(merged);
    return match?.group(1);
  }
}

class _CompactItemViewData {
  const _CompactItemViewData({
    required this.title,
    required this.imageUrl,
    required this.shortAddress,
    required this.displayPrice,
  });

  final String title;
  final String? imageUrl;
  final String shortAddress;
  final String displayPrice;

  factory _CompactItemViewData.fromItem({
    required ChecklistDetailItem item,
    required AppLocalizations? t,
  }) {
    final title = item.title.trim().isNotEmpty
        ? item.title.trim()
        : (item.providerName ?? '').trim().isNotEmpty
        ? item.providerName!.trim()
        : item.groupType.trim();
    return _CompactItemViewData(
      title: title.isEmpty ? item.groupType : title,
      // 真实地点优先展示 Places 图片，旧数据再回退到文本中的 URL。
      imageUrl: (item.photoUrl ?? '').trim().isNotEmpty
          ? item.photoUrl!.trim()
          : _extractImageUrl(
              '${item.subtitle ?? ''} ${item.routeText ?? ''} ${item.detailRouteTarget ?? ''}',
            ),
      shortAddress: formatShortAddress(item.address),
      displayPrice: formatDisplayPrice(item, t),
    );
  }

  // 仅用于前端显示的短地址格式化，不改原始地址数据。
  static String formatShortAddress(String? rawAddress) {
    final resolved = (rawAddress ?? '').trim();
    if (resolved.isEmpty) {
      return '';
    }

    var text = resolved.replaceAll(RegExp(r'\s+'), ' ').trim();
    final commaParts = text
        .split(',')
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList(growable: false);

    if (commaParts.length >= 2) {
      final filtered = commaParts
          .where((part) {
            final normalized = part.toLowerCase();
            if (RegExp(r'^\d{3,}$').hasMatch(normalized)) {
              return false;
            }
            if (normalized.contains('prefecture') ||
                normalized == 'japan' ||
                normalized == 'china' ||
                normalized == 'united states') {
              return false;
            }
            if (RegExp(
              r'^(tokyo|osaka|kyoto|paris|london|shanghai|beijing)$',
            ).hasMatch(normalized)) {
              return false;
            }
            return true;
          })
          .toList(growable: false);
      if (filtered.isNotEmpty) {
        text = filtered.length >= 2
            ? filtered.sublist(0, 2).join(', ')
            : filtered.first;
      }
    }

    return text;
  }

  // 价格只保留单行核心信息，避免 About、区间和重复文案撑爆卡片。
  static String formatDisplayPrice(
    ChecklistDetailItem item,
    AppLocalizations? t,
  ) {
    final amount = _readAverageAmount(item);
    final normalizedType = (item.type ?? '').trim().toLowerCase();
    final normalizedGroup = item.groupType.trim().toLowerCase();
    final isHotel = normalizedType == 'hotel' || normalizedGroup == 'stay';
    final isRestaurant =
        normalizedType == 'restaurant' ||
        normalizedType == 'food' ||
        normalizedGroup == 'food';
    final isActivity =
        normalizedType == 'activity' || normalizedGroup == 'activity';

    if (isActivity && amount != null && amount <= 0) {
      return t?.checklistPriceFree ?? 'Free';
    }

    if (amount == null) {
      return t?.checklistPriceUnavailable ?? 'Price unavailable';
    }

    final currencySymbol = _resolveCurrencySymbol(item.currency);
    final amountText = NumberFormat.decimalPattern().format(amount);
    final unitText = isHotel
        ? (t?.checklistPriceUnitNight ?? 'night')
        : (t?.checklistPriceUnitPerson ?? 'person');
    if (isRestaurant || isActivity || isHotel) {
      return '$currencySymbol$amountText / $unitText';
    }
    return '$currencySymbol$amountText';
  }

  static double? _readAverageAmount(ChecklistDetailItem item) {
    final structuredMin = item.estimatedCostMin;
    final structuredMax = item.estimatedCostMax;
    if (structuredMin != null && structuredMax != null) {
      return (structuredMin + structuredMax) / 2;
    }
    if (structuredMin != null || structuredMax != null) {
      return structuredMin ?? structuredMax;
    }

    final legacyMin = item.estimatedPriceMin;
    final legacyMax = item.estimatedPriceMax;
    if (legacyMin != null && legacyMax != null) {
      return (legacyMin + legacyMax) / 2;
    }
    return legacyMin ?? legacyMax;
  }

  static String _resolveCurrencySymbol(String? currencyCode) {
    switch ((currencyCode ?? '').trim().toUpperCase()) {
      case 'CNY':
      case 'JPY':
        return '\u00A5';
      case 'USD':
        return '\$';
      case 'EUR':
        return '\u20AC';
      case 'GBP':
        return '\u00A3';
      default:
        final code = (currencyCode ?? '').trim();
        return code.isNotEmpty ? '$code ' : '\u00A5';
    }
  }

  static String? _extractImageUrl(String source) {
    final match = RegExp(
      r'(https?:\/\/\S+\.(?:png|jpg|jpeg|webp|gif))',
      caseSensitive: false,
    ).firstMatch(source);
    return match?.group(1)?.trim();
  }
}

class _ChecklistCompactItemCard extends StatelessWidget {
  const _ChecklistCompactItemCard({
    required this.item,
    required this.onToggleCompleted,
    required this.title,
    required this.imageUrl,
    required this.shortAddress,
    required this.displayPrice,
    required this.placeholderIcon,
    this.onTap,
  });

  final ChecklistDetailItem item;
  final ValueChanged<bool> onToggleCompleted;
  final VoidCallback? onTap;
  final String title;
  final String? imageUrl;
  final String shortAddress;
  final String displayPrice;
  final IconData placeholderIcon;

  @override
  Widget build(BuildContext context) {
    final titleColor = item.isCompleted
        ? const Color(0xFF6B7280)
        : const Color(0xFF111827);
    final secondaryColor = item.isCompleted
        ? const Color(0xFF9CA3AF)
        : const Color(0xFF667085);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(ChecklistItemTile._hotelCardRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(ChecklistItemTile._hotelCardRadius),
        child: Ink(
          decoration: BoxDecoration(
            color: item.isCompleted ? const Color(0xFFF4F5F7) : Colors.white,
            borderRadius: BorderRadius.circular(
              ChecklistItemTile._hotelCardRadius,
            ),
            border: Border.all(color: const Color(0xFFE5E7EB)),
            boxShadow: item.isCompleted
                ? const <BoxShadow>[]
                : const <BoxShadow>[
                    BoxShadow(
                      color: Color(0x04000000),
                      blurRadius: 4,
                      offset: Offset(0, 1),
                    ),
                  ],
          ),
          child: Opacity(
            opacity: item.isCompleted ? 0.65 : 1,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15,
                            height: 1.2,
                            fontWeight: FontWeight.w700,
                            color: titleColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: Checkbox(
                          value: item.isCompleted,
                          onChanged: (value) =>
                              onToggleCompleted(value ?? false),
                          visualDensity: VisualDensity.compact,
                          activeColor: const Color(0xFF3B6EEA),
                          checkColor: Colors.white,
                          side: const BorderSide(
                            color: Color(0xFFC5C8D0),
                            width: 1.2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      _HotelImage(
                        url: imageUrl,
                        width: 96,
                        height: 72,
                        placeholderIcon: placeholderIcon,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SizedBox(
                          height: 72,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              Flexible(
                                child: Text(
                                  shortAddress,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    height: 1.35,
                                    fontWeight: FontWeight.w500,
                                    color: secondaryColor,
                                  ),
                                ),
                              ),
                              Text(
                                displayPrice,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 14,
                                  height: 1.15,
                                  fontWeight: FontWeight.w700,
                                  color: titleColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HotelImage extends StatelessWidget {
  const _HotelImage({
    required this.url,
    required this.width,
    required this.height,
    this.placeholderIcon = Icons.hotel_rounded,
  });

  final String? url;
  final double width;
  final double height;
  final IconData placeholderIcon;

  @override
  Widget build(BuildContext context) {
    final resolved = (url ?? '').trim();
    if (resolved.isEmpty) {
      return _buildPlaceholder();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: AppNetworkImage(
        imageUrl: resolved,
        pageName: 'checklist.hotelImage',
        width: width,
        height: height,
        fit: BoxFit.cover,
        placeholderBuilder: (context) => _buildPlaceholder(),
        errorBuilder: (context, error) => _buildPlaceholder(),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFECEFF3),
        borderRadius: BorderRadius.circular(6),
      ),
      alignment: Alignment.center,
      child: Icon(placeholderIcon, size: 26, color: const Color(0xFF98A2B3)),
    );
  }
}

class _AirlineLogo extends StatelessWidget {
  const _AirlineLogo({required this.url, required this.isCompleted});

  final String? url;
  final bool isCompleted;

  @override
  Widget build(BuildContext context) {
    final hasUrl = (url ?? '').trim().isNotEmpty;
    if (!hasUrl) {
      return _buildFallbackIcon();
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: AppNetworkImage(
        imageUrl: url!.trim(),
        pageName: 'checklist.airlineLogo',
        width: 18,
        height: 18,
        fit: BoxFit.cover,
        placeholderBuilder: (context) => _buildFallbackIcon(),
        errorBuilder: (context, error) => _buildFallbackIcon(),
      ),
    );
  }

  Widget _buildFallbackIcon() {
    return SizedBox(
      width: 18,
      height: 18,
      child: Icon(
        Icons.flight_takeoff_rounded,
        size: 16,
        color: isCompleted ? const Color(0xFF98A2B3) : const Color(0xFF667085),
      ),
    );
  }
}

class _EstimatePriceBadge extends StatelessWidget {
  const _EstimatePriceBadge({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF5FF),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Color(0xFF2F61F6),
        ),
      ),
    );
  }
}

class _FlightFixedTemplateBlock extends StatelessWidget {
  const _FlightFixedTemplateBlock({
    required this.departureTime,
    required this.arrivalTime,
    required this.departureAirport,
    required this.arrivalAirport,
    required this.airportColor,
    required this.timeColor,
    required this.routeSummary,
  });

  final String? departureTime;
  final String? arrivalTime;
  final String? departureAirport;
  final String? arrivalAirport;
  final Color airportColor;
  final Color timeColor;
  final String routeSummary;

  bool get _hasTimeline =>
      departureTime != null &&
      arrivalTime != null &&
      departureAirport != null &&
      arrivalAirport != null;

  @override
  Widget build(BuildContext context) {
    if (_hasTimeline) {
      return _FlightTimelineBlock(
        departureTime: departureTime!,
        arrivalTime: arrivalTime!,
        departureAirport: departureAirport!,
        arrivalAirport: arrivalAirport!,
        airportColor: airportColor,
        timeColor: timeColor,
      );
    }

    if (routeSummary.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        routeSummary,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 12,
          height: 1.35,
          color: airportColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _FlightTimelineBlock extends StatelessWidget {
  const _FlightTimelineBlock({
    required this.departureTime,
    required this.arrivalTime,
    required this.departureAirport,
    required this.arrivalAirport,
    required this.airportColor,
    required this.timeColor,
  });

  final String departureTime;
  final String arrivalTime;
  final String departureAirport;
  final String arrivalAirport;
  final Color airportColor;
  final Color timeColor;

  static const double _rowHeight = 22;
  static const double _connectorHeight = 12;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(
          width: 14,
          child: Column(
            children: <Widget>[
              SizedBox(
                height: _rowHeight,
                child: Center(
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(
                        color: const Color(0xFF9CA3AF),
                        width: 1.2,
                      ),
                    ),
                  ),
                ),
              ),
              Container(
                width: 1,
                height: _connectorHeight,
                color: const Color(0xFFD1D5DB),
              ),
              SizedBox(
                height: _rowHeight,
                child: Center(
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF4B5563),
                      border: Border.all(
                        color: const Color(0xFF9CA3AF),
                        width: 1.2,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 18),
        Expanded(
          child: Column(
            children: <Widget>[
              SizedBox(
                height: _rowHeight,
                child: _FlightTimelineTextRow(
                  timeText: departureTime,
                  airportText: departureAirport,
                  airportColor: airportColor,
                  timeColor: timeColor,
                ),
              ),
              const SizedBox(height: _connectorHeight),
              SizedBox(
                height: _rowHeight,
                child: _FlightTimelineTextRow(
                  timeText: arrivalTime,
                  airportText: arrivalAirport,
                  airportColor: airportColor,
                  timeColor: timeColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FlightTimelineTextRow extends StatelessWidget {
  const _FlightTimelineTextRow({
    required this.timeText,
    required this.airportText,
    required this.airportColor,
    required this.timeColor,
  });

  final String timeText;
  final String airportText;
  final Color airportColor;
  final Color timeColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Text(
          timeText,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            height: 1,
            color: timeColor,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _AirportLabel(text: airportText, color: airportColor),
        ),
      ],
    );
  }
}

class _AirportLabel extends StatelessWidget {
  const _AirportLabel({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final suffixMatch = RegExp(r'([A-Z]{3}\s*T\d+)$').firstMatch(text.trim());
    final suffix = suffixMatch?.group(1);
    if (suffix == null) {
      return Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 11.5,
          height: 1.2,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      );
    }

    final prefix = text.substring(0, suffixMatch!.start).trimRight();
    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            prefix,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11.5,
              height: 1.2,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          suffix,
          style: TextStyle(
            fontSize: 11.5,
            height: 1.2,
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          color: Color(0xFF475467),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
