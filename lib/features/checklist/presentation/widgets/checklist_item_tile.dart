import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/checklist_detail.dart';

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
      return _buildHotelStayTile();
    }
    if (_isFoodOrActivityItem(item)) {
      return _buildFoodActivityTile();
    }
    return _buildDefaultTile(t);
  }

  Widget _buildDefaultTile(AppLocalizations? t) {
    final demoBadge = item.dataSource?.trim() == 'demo_estimated'
        ? t?.checklistDemoEstimateBadge
        : null;
    final estimatedText = _buildEstimatedText();
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
                    if (estimatedText.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 4),
                      Text(
                        estimatedText,
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
    final titleParts = _splitFlightTitle(viewData.title);

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
                            titleParts.$1,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: _flightPrimaryFontSize,
                              fontWeight: FontWeight.w400,
                              height: 1.15,
                              color: titleColor,
                            ),
                          ),
                          if (titleParts.$2 != null) ...<Widget>[
                            const SizedBox(height: 4),
                            Text(
                              titleParts.$2!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: _flightSecondaryFontSize,
                                fontWeight: FontWeight.w400,
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
                if (viewData.hasTimeline) ...<Widget>[
                  const SizedBox(height: 12),
                  _FlightTimelineBlock(
                    departureTime: viewData.departureTime!,
                    arrivalTime: viewData.arrivalTime!,
                    departureAirport: viewData.departureAirport!,
                    arrivalAirport: viewData.arrivalAirport!,
                    airportColor: airportColor,
                    timeColor: titleColor,
                  ),
                ] else if (viewData.compactSubtitle.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 12),
                  Text(
                    viewData.compactSubtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: _defaultSubtitleFontSize,
                      color: airportColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHotelStayTile() {
    final viewData = _HotelStayViewData.fromItem(item);
    final titleColor = item.isCompleted
        ? const Color(0xFF6B7280)
        : const Color(0xFF111827);
    final secondaryColor = item.isCompleted
        ? const Color(0xFF9CA3AF)
        : const Color(0xFF667085);
    final timeColor = item.isCompleted
        ? const Color(0xFF9CA3AF)
        : const Color(0xFF7A8294);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(_hotelCardRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(_hotelCardRadius),
        child: Ink(
          decoration: BoxDecoration(
            color: item.isCompleted ? const Color(0xFFF4F5F7) : Colors.white,
            borderRadius: BorderRadius.circular(_hotelCardRadius),
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
                  // 顶部标题区：左侧酒店名，右侧保留勾选操作。
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          viewData.title,
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
                  LayoutBuilder(
                    builder: (context, constraints) {
                      // 图片宽度约占卡片内容区 3/8，并保持 4:3 比例。
                      final imageWidth = (constraints.maxWidth * 0.375).clamp(
                        96.0,
                        116.0,
                      );
                      final imageHeight = imageWidth * 3 / 4;

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          _HotelImage(
                            url: viewData.imageUrl,
                            width: imageWidth,
                            height: imageHeight,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: SizedBox(
                              height: imageHeight,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  // 右侧描述块轻微下移，贴近参考图视觉。
                                  const SizedBox(height: 2),
                                  if (viewData.timeText != null ||
                                      viewData.descriptionText.isNotEmpty)
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: <Widget>[
                                        if (viewData.timeText !=
                                            null) ...<Widget>[
                                          Text(
                                            viewData.timeText!,
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                              color: timeColor,
                                              height: 1.2,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                        ],
                                        Expanded(
                                          child: Text(
                                            viewData.descriptionText,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.w500,
                                              color: secondaryColor,
                                              height: 1.35,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  if (viewData.priceText != null) ...<Widget>[
                                    const Spacer(),
                                    // 价格固定在图片右侧底部上方。
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 2),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: <Widget>[
                                          Flexible(
                                            child: Text(
                                              viewData.priceText!,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w700,
                                                color: titleColor,
                                                height: 1.1,
                                              ),
                                            ),
                                          ),
                                          if (viewData.nightUnitText !=
                                              null) ...<Widget>[
                                            const SizedBox(width: 6),
                                            Text(
                                              viewData.nightUnitText!,
                                              style: TextStyle(
                                                fontSize: 12.5,
                                                fontWeight: FontWeight.w500,
                                                color: secondaryColor,
                                                height: 1.2,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFoodActivityTile() {
    final isFood = _isFoodItem(item);
    final viewData = _FoodActivityViewData.fromItem(item: item, isFood: isFood);
    final titleColor = item.isCompleted
        ? const Color(0xFF6B7280)
        : const Color(0xFF111827);
    final secondaryColor = item.isCompleted
        ? const Color(0xFF9CA3AF)
        : const Color(0xFF667085);
    final timeColor = item.isCompleted
        ? const Color(0xFF9CA3AF)
        : const Color(0xFF7A8294);
    final placeholderIcon = isFood
        ? Icons.restaurant_rounded
        : Icons.local_activity_rounded;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(_hotelCardRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(_hotelCardRadius),
        child: Ink(
          decoration: BoxDecoration(
            color: item.isCompleted ? const Color(0xFFF4F5F7) : Colors.white,
            borderRadius: BorderRadius.circular(_hotelCardRadius),
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
                  // 标题行样式与 Hotel 保持一致。
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          viewData.title,
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
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final imageWidth = (constraints.maxWidth * 0.375).clamp(
                        96.0,
                        116.0,
                      );
                      final imageHeight = imageWidth * 3 / 4;

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          _HotelImage(
                            url: viewData.imageUrl,
                            width: imageWidth,
                            height: imageHeight,
                            placeholderIcon: placeholderIcon,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: SizedBox(
                              height: imageHeight,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  const SizedBox(height: 2),
                                  if (viewData.timeText != null ||
                                      viewData.descriptionText.isNotEmpty)
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: <Widget>[
                                        if (viewData.timeText !=
                                            null) ...<Widget>[
                                          Text(
                                            viewData.timeText!,
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                              color: timeColor,
                                              height: 1.2,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                        ],
                                        Expanded(
                                          child: Text(
                                            viewData.descriptionText,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.w500,
                                              color: secondaryColor,
                                              height: 1.35,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  if (viewData.priceText != null) ...<Widget>[
                                    const Spacer(),
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 2),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: <Widget>[
                                          Flexible(
                                            child: Text(
                                              viewData.priceText!,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w700,
                                                color: titleColor,
                                                height: 1.1,
                                              ),
                                            ),
                                          ),
                                          if (viewData.unitText !=
                                              null) ...<Widget>[
                                            const SizedBox(width: 6),
                                            Text(
                                              viewData.unitText!,
                                              style: TextStyle(
                                                fontSize: 12.5,
                                                fontWeight: FontWeight.w500,
                                                color: secondaryColor,
                                                height: 1.2,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
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

  bool _isFoodItem(ChecklistDetailItem value) {
    final type = (value.type ?? '').trim().toLowerCase();
    final group = value.groupType.trim().toLowerCase();
    return type == 'food' || group == 'food';
  }

  String _buildEstimatedText() {
    final directText = (item.estimatedPriceText ?? '').trim();
    if (directText.isNotEmpty) {
      return directText;
    }
    if (item.estimatedPriceMin != null && item.estimatedPriceMax != null) {
      return '${item.currency ?? ''} ${item.estimatedPriceMin!.round()} - ${item.estimatedPriceMax!.round()}';
    }
    if (item.estimatedCostMin != null && item.estimatedCostMax != null) {
      return '${item.currency ?? ''} ${item.estimatedCostMin!.round()} - ${item.estimatedCostMax!.round()}';
    }
    return '';
  }

  (String, String?) _splitFlightTitle(String title) {
    final trimmed = title.trim();
    if (trimmed.isEmpty) {
      return ('', null);
    }
    final match = RegExp(
      r'^(.*?)(\b[A-Z]{1,3}\s?\d{2,4}\b)$',
    ).firstMatch(trimmed);
    if (match == null) {
      return (trimmed, null);
    }
    final airline = (match.group(1) ?? '').trim();
    final flightNumber = (match.group(2) ?? '').trim().replaceAll(' ', '');
    return (
      airline.isEmpty ? trimmed : airline,
      flightNumber.isEmpty ? null : flightNumber,
    );
  }
}

class _TransportFlightViewData {
  const _TransportFlightViewData({
    required this.title,
    required this.compactSubtitle,
    required this.logoUrl,
    required this.departureTime,
    required this.arrivalTime,
    required this.departureAirport,
    required this.arrivalAirport,
    required this.estimateBadgeText,
  });

  final String title;
  final String compactSubtitle;
  final String? logoUrl;
  final String? departureTime;
  final String? arrivalTime;
  final String? departureAirport;
  final String? arrivalAirport;
  final String? estimateBadgeText;

  bool get hasTimeline =>
      departureTime != null &&
      arrivalTime != null &&
      departureAirport != null &&
      arrivalAirport != null;

  factory _TransportFlightViewData.fromItem({
    required ChecklistDetailItem item,
    required AppLocalizations? t,
  }) {
    final title = _buildTitle(item);
    final estimateBadgeText = _buildEstimateBadgeText(item: item, t: t);
    final timeline = _parseTimeline(item);
    final subtitle = (item.subtitle ?? item.routeText ?? '').trim();
    final logoUrl = _extractLogoUrl(item);

    return _TransportFlightViewData(
      title: title,
      compactSubtitle: subtitle,
      logoUrl: logoUrl,
      departureTime: timeline.$1,
      arrivalTime: timeline.$2,
      departureAirport: timeline.$3,
      arrivalAirport: timeline.$4,
      estimateBadgeText: estimateBadgeText,
    );
  }

  static String _buildTitle(ChecklistDetailItem item) {
    final rawTitle = item.title.trim();
    final rawProvider = (item.providerName ?? '').trim();
    final title =
        (rawTitle.isEmpty ||
            rawTitle.toLowerCase() == 'flights' ||
            rawTitle.toLowerCase() == 'flight')
        ? (rawProvider.isNotEmpty ? rawProvider : rawTitle)
        : rawTitle;

    final combinedText =
        '${item.title} ${item.subtitle ?? ''} ${item.routeText ?? ''}';
    final flightNumber = _extractFlightNumber(combinedText);
    final displayTitle = title;
    if (displayTitle.isEmpty) {
      return flightNumber ?? item.groupType;
    }
    if (flightNumber == null || displayTitle.contains(flightNumber)) {
      return displayTitle;
    }
    return '$displayTitle $flightNumber';
  }

  static String? _buildEstimateBadgeText({
    required ChecklistDetailItem item,
    required AppLocalizations? t,
  }) {
    final currencySymbol = _resolveCurrencySymbol(item.currency);
    final valueText = _resolveEstimateValue(item, currencySymbol);
    if (valueText == null) {
      return null;
    }
    final prefix = t?.checklistEstimateShort ?? 'EST.';
    return '$prefix $valueText';
  }

  static String? _resolveEstimateValue(
    ChecklistDetailItem item,
    String symbol,
  ) {
    final directText = (item.estimatedPriceText ?? '').trim();
    if (directText.isNotEmpty) {
      final directNumber = _extractPriceNumber(directText);
      if (directNumber != null) {
        return '$symbol$directNumber';
      }
      return directText;
    }

    final number =
        item.estimatedPriceMin ??
        item.estimatedPriceMax ??
        item.estimatedCostMin ??
        item.estimatedCostMax;
    if (number == null) {
      return null;
    }
    final formatted = NumberFormat.decimalPattern().format(number.round());
    return '$symbol$formatted';
  }

  static String? _extractPriceNumber(String source) {
    final match = RegExp(r'([0-9][0-9,]*)').firstMatch(source);
    return match?.group(1);
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

  // 解析时间轴：只依赖数据字段，不在 UI 层补假值。

  static (String?, String?, String?, String?) _parseTimeline(
    ChecklistDetailItem item,
  ) {
    final subtitle = (item.subtitle ?? '').trim();
    final routeText = (item.routeText ?? '').trim();
    final fullText = '$subtitle\n$routeText';

    final timeMatches = RegExp(r'((?:[01]?\d|2[0-3]):[0-5]\d)')
        .allMatches(fullText)
        .map((m) => m.group(1) ?? '')
        .where((s) => s.isNotEmpty)
        .toList(growable: false);

    String? departureTime;
    String? arrivalTime;
    if (timeMatches.length >= 2) {
      departureTime = timeMatches[0];
      arrivalTime = timeMatches[1];
    }

    String? departureAirport;
    String? arrivalAirport;
    final airportsFromList = item.suggestedAirports
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList(growable: false);
    if (airportsFromList.length >= 2) {
      departureAirport = airportsFromList[0];
      arrivalAirport = airportsFromList[1];
    } else {
      final airportsFromRoute = _parseAirportsFromRoute(routeText);
      if (airportsFromRoute.length >= 2) {
        departureAirport = airportsFromRoute[0];
        arrivalAirport = airportsFromRoute[1];
      } else {
        final airportsFromSubtitle = _parseAirportsFromSubtitle(subtitle);
        if (airportsFromSubtitle.length >= 2) {
          departureAirport = airportsFromSubtitle[0];
          arrivalAirport = airportsFromSubtitle[1];
        }
      }
    }

    return (departureTime, arrivalTime, departureAirport, arrivalAirport);
  }

  static List<String> _parseAirportsFromRoute(String routeText) {
    if (routeText.isEmpty) {
      return const <String>[];
    }
    final parts = routeText.split(RegExp('\\s*(?:->|\\u2192)\\s*'));
    if (parts.length < 2) {
      return const <String>[];
    }
    return parts
        .take(2)
        .map(_cleanupAirportText)
        .where((value) => value.isNotEmpty)
        .toList(growable: false);
  }

  static List<String> _parseAirportsFromSubtitle(String subtitle) {
    if (subtitle.isEmpty) {
      return const <String>[];
    }
    final lines = subtitle
        .split(RegExp(r'[\r\n]+'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList(growable: false);
    if (lines.length < 2) {
      return const <String>[];
    }

    return lines
        .take(2)
        .map(_cleanupAirportText)
        .where((line) => line.isNotEmpty)
        .toList(growable: false);
  }

  static String _cleanupAirportText(String source) {
    final textWithoutTime = source.replaceFirst(
      RegExp(r'^\s*(?:[01]?\d|2[0-3]):[0-5]\d\s*'),
      '',
    );
    final textWithoutHint = textWithoutTime.replaceFirst(
      RegExp(r'\s*-\s*Estimated.*$', caseSensitive: false),
      '',
    );
    return textWithoutHint.trim();
  }

  static String? _extractFlightNumber(String text) {
    final upper = text.toUpperCase();
    final match = RegExp(r'\b[A-Z]{1,3}\s?\d{2,4}\b').firstMatch(upper);
    return match?.group(0)?.replaceAll(' ', '');
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

class _HotelStayViewData {
  const _HotelStayViewData({
    required this.title,
    required this.imageUrl,
    required this.timeText,
    required this.descriptionText,
    required this.priceText,
    required this.nightUnitText,
  });

  final String title;
  final String? imageUrl;
  final String? timeText;
  final String descriptionText;
  final String? priceText;
  final String? nightUnitText;

  factory _HotelStayViewData.fromItem(ChecklistDetailItem item) {
    final subtitle = (item.subtitle ?? '').trim();
    final routeText = (item.routeText ?? '').trim();
    final combinedText = '$subtitle $routeText ${item.detailRouteTarget ?? ''}';

    final title = item.title.trim().isNotEmpty
        ? item.title.trim()
        : (item.providerName ?? '').trim();
    final imageUrl = _extractImageUrl(combinedText);
    final timeText = _extractFirstTime('$subtitle\n$routeText');
    final descriptionText = _resolveDescription(
      subtitle: subtitle,
      routeText: routeText,
      fallback: title,
    );

    final currencySymbol = _TransportFlightViewData._resolveCurrencySymbol(
      item.currency,
    );
    final priceText = _resolvePriceText(item, currencySymbol);
    final nightUnitText = _resolveNightUnitText(item, subtitle);

    return _HotelStayViewData(
      title: title.isEmpty ? item.groupType : title,
      imageUrl: imageUrl,
      timeText: timeText,
      descriptionText: descriptionText,
      priceText: priceText,
      nightUnitText: nightUnitText,
    );
  }

  static String? _resolvePriceText(ChecklistDetailItem item, String symbol) {
    final directText = (item.estimatedPriceText ?? '').trim();
    if (directText.isNotEmpty) {
      final number = RegExp(r'([0-9][0-9,]*)').firstMatch(directText)?.group(1);
      return number == null ? directText : '$symbol$number';
    }

    final priceValue =
        item.estimatedPriceMin ??
        item.estimatedPriceMax ??
        item.estimatedCostMin ??
        item.estimatedCostMax;
    if (priceValue == null) {
      return null;
    }
    final formatted = NumberFormat.decimalPattern().format(priceValue.round());
    return '$symbol$formatted';
  }

  static String? _resolveNightUnitText(
    ChecklistDetailItem item,
    String source,
  ) {
    final costUnit = (item.costUnit ?? '').trim().toLowerCase();
    if (costUnit == 'per_night') {
      final unitMatch = RegExp(
        r'(/ ?night)\b',
        caseSensitive: false,
      ).firstMatch(source);
      return unitMatch?.group(1);
    }

    final unitMatch = RegExp(
      r'(/ ?night)\b',
      caseSensitive: false,
    ).firstMatch(source);
    if (unitMatch != null) {
      return unitMatch.group(1);
    }
    return null;
  }

  static String _resolveDescription({
    required String subtitle,
    required String routeText,
    required String fallback,
  }) {
    final source = subtitle.isNotEmpty ? subtitle : routeText;
    if (source.isEmpty) {
      return fallback;
    }

    var text = source;
    text = text.replaceAll(RegExp(r'https?:\/\/\S+'), '');
    text = text.replaceAll(RegExp(r'((?:[01]?\d|2[0-3]):[0-5]\d)'), '');
    text = text.replaceAll(
      RegExp(r'\s*-\s*Estimated.*$', caseSensitive: false),
      '',
    );
    text = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    return text.isEmpty ? fallback : text;
  }

  static String? _extractImageUrl(String source) {
    final match = RegExp(
      r'(https?:\/\/\S+\.(?:png|jpg|jpeg|webp|gif))',
      caseSensitive: false,
    ).firstMatch(source);
    return match?.group(1)?.trim();
  }

  static String? _extractFirstTime(String source) {
    final match = RegExp(r'((?:[01]?\d|2[0-3]):[0-5]\d)').firstMatch(source);
    return match?.group(1);
  }
}

class _FoodActivityViewData {
  const _FoodActivityViewData({
    required this.title,
    required this.imageUrl,
    required this.timeText,
    required this.descriptionText,
    required this.priceText,
    required this.unitText,
  });

  final String title;
  final String? imageUrl;
  final String? timeText;
  final String descriptionText;
  final String? priceText;
  final String? unitText;

  factory _FoodActivityViewData.fromItem({
    required ChecklistDetailItem item,
    required bool isFood,
  }) {
    final subtitle = (item.subtitle ?? '').trim();
    final routeText = (item.routeText ?? '').trim();
    final combinedText = '$subtitle $routeText ${item.detailRouteTarget ?? ''}';

    final title = item.title.trim().isNotEmpty
        ? item.title.trim()
        : item.groupType.trim();
    final imageUrl = _HotelStayViewData._extractImageUrl(combinedText);
    final timeText = _HotelStayViewData._extractFirstTime(
      '$subtitle\n$routeText',
    );
    final descriptionText = _HotelStayViewData._resolveDescription(
      subtitle: subtitle,
      routeText: routeText,
      fallback: title,
    );
    final currencySymbol = _TransportFlightViewData._resolveCurrencySymbol(
      item.currency,
    );
    final priceText = _HotelStayViewData._resolvePriceText(
      item,
      currencySymbol,
    );
    final unitText = _resolveUnitText(
      item: item,
      source: subtitle,
      isFood: isFood,
      hasPrice: priceText != null,
    );

    return _FoodActivityViewData(
      title: title,
      imageUrl: imageUrl,
      timeText: timeText,
      descriptionText: descriptionText,
      priceText: priceText,
      unitText: unitText,
    );
  }

  static String? _resolveUnitText({
    required ChecklistDetailItem item,
    required String source,
    required bool isFood,
    required bool hasPrice,
  }) {
    final costUnit = (item.costUnit ?? '').trim().toLowerCase();
    switch (costUnit) {
      case 'per_person':
        return '/ person';
      case 'per_meal':
        return '/ meal';
      case 'per_ticket':
        return '/ ticket';
      case 'per_night':
        return '/ night';
    }

    final unitMatch = RegExp(
      r'(/ ?(?:person|meal|ticket|night))\b',
      caseSensitive: false,
    ).firstMatch(source);
    if (unitMatch != null) {
      return unitMatch.group(1);
    }

    if (isFood && hasPrice) {
      return '/ person';
    }
    return null;
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
      child: Image.network(
        resolved,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
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
      child: Image.network(
        url!.trim(),
        width: 18,
        height: 18,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildFallbackIcon(),
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
