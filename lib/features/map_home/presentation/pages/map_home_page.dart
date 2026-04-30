import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import '../../../../app/app_router.dart';
import '../../../../core/config/mapbox_config.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/system_ui/app_system_ui.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../features/checklist/domain/entities/checklist_destination_snapshot.dart';
import '../../../../features/checklist/presentation/controllers/checklist_controller.dart';
import '../../../../l10n/app_localizations.dart';
import '../controllers/map_home_controller.dart';
import '../../domain/entities/map_home_city_search_result_entity.dart';
import '../../domain/entities/place_entity.dart';
import '../models/place_detail_ui_model.dart';
import '../support/place_localizations.dart';
import '../widgets/map_icon_action_button.dart';
import '../widgets/map_home_status_panel.dart';
import '../widgets/map_mode_toggle_button.dart';
import '../widgets/place_preview_card.dart';

class MapHomePage extends StatefulWidget {
  const MapHomePage({super.key});

  @override
  State<MapHomePage> createState() => _MapHomePageState();
}

class _MapHomePageState extends State<MapHomePage> {
  static const double _initialMapZoom = 1.45;
  static const double _topActionHorizontalMargin = 16;
  static const double _topActionTopMargin = 24;
  static const double _topActionToCompassGap = 10;
  static const double _searchFieldHeight = 56;
  static const double _searchToActionGap = 12;
  static const double _ornamentBottomMargin = 8;
  static const double _floatingInset = 16;

  late final MapHomeController _controller =
      ServiceLocator.createMapHomeController(
        initialMarkerZoom: _initialMapZoom,
      );
  late final ChecklistController _checklistController =
      ServiceLocator.checklistController;
  final TextEditingController _searchController = TextEditingController();
  Locale? _lastLocale;
  bool? _lastHasPreviewCard;
  int? _lastLocationNoticeVersion;
  bool _isCreatingChecklist = false;

  CameraOptions get _initialCameraOptions => CameraOptions(
    center: Point(coordinates: Position(105.0, 30.0)),
    zoom: _initialMapZoom,
    bearing: 0.0,
    pitch: 0.0,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final locale = Localizations.localeOf(context);
    if (_lastLocale == locale) {
      return;
    }

    _lastLocale = locale;
    unawaited(_controller.syncBasemapLanguageWithLocale(locale));
  }

  @override
  void dispose() {
    _searchController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    if (t == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!MapboxConfig.isSupportedPlatform) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: MapHomeStatusPanel(
            icon: const Icon(
              Icons.phone_iphone_rounded,
              size: 42,
              color: Color(0xFF3563E9),
            ),
            title: t.mapHomeUnsupportedTitle,
            message: t.mapHomeUnsupportedMessage,
          ),
        ),
      );
    }

    if (!MapboxConfig.hasAccessToken) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: MapHomeStatusPanel(
            icon: const Icon(
              Icons.vpn_key_outlined,
              size: 42,
              color: Color(0xFF3563E9),
            ),
            title: t.mapHomeMissingTokenTitle,
            message: t.mapHomeMissingTokenMessage,
          ),
        ),
      );
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppSystemUi.lightOverlayStyle,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final hasPreviewCard = _controller.hasActivePreviewCard;
            if (_lastHasPreviewCard != hasPreviewCard) {
              _lastHasPreviewCard = hasPreviewCard;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                unawaited(
                  _controller.updateScaleBarVisibility(!hasPreviewCard),
                );
              });
            }
            _showLocationNoticeIfNeeded(context, t);

            return Stack(
              fit: StackFit.expand,
              children: [
                // 地图在底层，所有状态面板和卡片都作为浮层叠上来。
                _buildMapWidget(),
                _buildFutureOverlaySlots(),
                _buildTopBar(t),
                if (_controller.hasActivePreviewCard)
                  _buildPlacePreviewCard(context, t),
                if (_controller.isLoading) _buildLoadingOverlay(t),
                if (_controller.hasError) _buildErrorOverlay(t),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildMapWidget() {
    return MapWidget(
      key: ValueKey<int>(_controller.mapWidgetVersion),
      styleUri: MapboxStyles.STANDARD_SATELLITE,
      textureView: true,
      cameraOptions: _initialCameraOptions,
      onMapCreated: (mapboxMap) {
        _controller.onMapCreated(mapboxMap);
        unawaited(_configureMapOrnaments(mapboxMap));
      },
      onStyleLoadedListener: (_) {
        _controller.onStyleLoaded();
      },
      onCameraChangeListener: _controller.onCameraChanged,
      onTapListener: _controller.onMapTap,
      onMapLoadErrorListener: (event) {
        _controller.onMapLoadError(event.message);
      },
    );
  }

  Future<void> _configureMapOrnaments(MapboxMap mapboxMap) async {
    final topPadding = MediaQuery.of(context).padding.top;
    final compassTop =
        topPadding +
        _topActionTopMargin +
        _searchFieldHeight +
        _topActionToCompassGap;

    await mapboxMap.scaleBar.updateSettings(
      ScaleBarSettings(
        enabled: !_controller.hasActivePreviewCard,
        position: OrnamentPosition.BOTTOM_RIGHT,
        marginRight: _topActionHorizontalMargin,
        marginBottom: _ornamentBottomMargin,
      ),
    );

    await mapboxMap.compass.updateSettings(
      CompassSettings(
        position: OrnamentPosition.TOP_LEFT,
        marginLeft: _topActionHorizontalMargin,
        marginTop: compassTop,
      ),
    );
  }

  Widget _buildTopBar(AppLocalizations t) {
    final isNightMode = _controller.lightPreset == MapHomeLightPreset.night;

    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(
        _topActionHorizontalMargin,
        _topActionTopMargin,
        _topActionHorizontalMargin,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSearchField(t),
          const SizedBox(height: _searchToActionGap),
          Align(
            alignment: Alignment.topRight,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 搜索框单独占满一行，地图操作按钮放在下方，避免顶部信息区过于拥挤。
                MapModeToggleButton(
                  isNightMode: isNightMode,
                  enabled: _controller.canToggleLightPreset,
                  tooltip: isNightMode
                      ? t.mapHomeSwitchToDay
                      : t.mapHomeSwitchToNight,
                  onPressed: _controller.toggleLightPreset,
                ),
                const SizedBox(height: 10),
                MapIconActionButton(
                  tooltip: t.locateMe,
                  enabled: !_controller.isLocating,
                  onPressed: _controller.locateMe,
                  child: _controller.isLocating
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2.4),
                        )
                      : const Icon(
                          Icons.my_location_rounded,
                          color: Color(0xFF111827),
                          size: 24,
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField(AppLocalizations t) {
    return Material(
      color: Colors.white.withValues(alpha: 0.94),
      borderRadius: BorderRadius.circular(20),
      elevation: 6,
      shadowColor: const Color(0x33000000),
      child: TextField(
        controller: _searchController,
        textInputAction: TextInputAction.search,
        onChanged: (_) => setState(() {}),
        onSubmitted: _submitCitySearch,
        style: const TextStyle(fontSize: 15, color: Color(0xFF111827)),
        decoration: InputDecoration(
          hintText: t.mapHomeSearchHint,
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: Color(0xFF6B7280),
          ),
          suffixIcon: _buildSearchSuffixIcons(),
          border: InputBorder.none,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildSearchSuffixIcons() {
    if (_controller.isSearching) {
      return const Padding(
        padding: EdgeInsets.all(14),
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2.2),
        ),
      );
    }

    if (_searchController.text.isEmpty) {
      return const SizedBox.shrink();
    }

    return IconButton(
      onPressed: () {
        _searchController.clear();
        setState(() {});
      },
      icon: const Icon(Icons.close_rounded, color: Color(0xFF6B7280)),
    );
  }

  Widget _buildFutureOverlaySlots() {
    return IgnorePointer(
      child: SafeArea(
        minimum: const EdgeInsets.fromLTRB(
          _floatingInset,
          _floatingInset,
          _floatingInset,
          32,
        ),
        child: Column(
          children: const [
            SizedBox(height: 68),
            Spacer(),
            SizedBox(height: 140),
          ],
        ),
      ),
    );
  }

  Widget _buildPlacePreviewCard(BuildContext context, AppLocalizations t) {
    final place = _controller.selectedPlace;
    final temporaryCity = _controller.selectedTemporaryCity;
    if (place == null && temporaryCity == null) {
      return const SizedBox.shrink();
    }

    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(
        _floatingInset,
        _floatingInset,
        _floatingInset,
        _floatingInset,
      ),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: place != null
            ? _buildOfficialPlacePreviewCard(context, t, place)
            : _buildTemporaryPlacePreviewCard(t, temporaryCity!),
      ),
    );
  }

  Widget _buildOfficialPlacePreviewCard(
    BuildContext context,
    AppLocalizations t,
    PlaceEntity place,
  ) {
    // 卡片文案直接走实体本地化方法，UI 不再自己判断语言分支。
    final languageCode = Localizations.localeOf(context).languageCode;
    final copy = place.localizedCopy(languageCode);

    return PlacePreviewCard(
      title: copy.name,
      description: copy.description,
      imageUrl: place.coverImage,
      primaryButtonText: t.viewDetails,
      onClose: _controller.clearSelectedPlace,
      onPrimaryPressed: () {
        // 仅传递当前已有真实字段，详情数据后续由正式数据链路接管。
        final initialModel = PlaceDetailUiModel.fromPlaceEntity(place: place);
        context.push(AppRouter.placeDetails(place.id), extra: initialModel);
      },
    );
  }

  Widget _buildTemporaryPlacePreviewCard(
    AppLocalizations t,
    MapHomeCitySearchResultEntity city,
  ) {
    return PlacePreviewCard(
      title: city.displayName,
      description: null,
      imageUrl: null,
      imageAssetPath: null,
      primaryButtonText: t.placeDetailsStartJourney,
      primaryButtonLoading: _isCreatingChecklist,
      onClose: _controller.clearSelectedPlace,
      onPrimaryPressed: _isCreatingChecklist
          ? null
          : () => _handleTemporaryPlaceStartJourney(t, city),
    );
  }

  Widget _buildLoadingOverlay(AppLocalizations t) {
    return ColoredBox(
      color: Colors.black.withValues(alpha: 0.14),
      child: MapHomeStatusPanel(
        icon: const SizedBox(
          width: 34,
          height: 34,
          child: CircularProgressIndicator(strokeWidth: 3),
        ),
        title: t.mapHomeLoadingTitle,
        message: t.mapHomeLoadingMessage,
      ),
    );
  }

  Widget _buildErrorOverlay(AppLocalizations t) {
    final details = _controller.errorDetails;
    final message = details == null || details.trim().isEmpty
        ? t.mapHomeLoadFailedMessage
        : '${t.mapHomeLoadFailedMessage}\n\n$details';

    return ColoredBox(
      color: Colors.black.withValues(alpha: 0.38),
      child: SafeArea(
        child: MapHomeStatusPanel(
          icon: const Icon(
            Icons.public_off_outlined,
            size: 42,
            color: Color(0xFFEF4444),
          ),
          title: t.mapHomeLoadFailedTitle,
          message: message,
          action: AppButton(text: t.mapHomeRetry, onPressed: _controller.retry),
        ),
      ),
    );
  }

  void _showLocationNoticeIfNeeded(BuildContext context, AppLocalizations t) {
    final notice = _controller.locationNotice;
    final version = _controller.locationNoticeVersion;
    if (notice == null || _lastLocationNoticeVersion == version) {
      return;
    }

    _lastLocationNoticeVersion = version;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      final messenger = ScaffoldMessenger.maybeOf(context);
      if (messenger == null) {
        return;
      }

      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(_locationNoticeText(t, notice))));
    });
  }

  String _locationNoticeText(AppLocalizations t, MapHomeLocationNotice notice) {
    switch (notice) {
      case MapHomeLocationNotice.serviceDisabled:
        return t.locationServiceDisabled;
      case MapHomeLocationNotice.permissionDenied:
        return t.locationPermissionDenied;
      case MapHomeLocationNotice.permissionDeniedForever:
        return t.locationPermissionDeniedForever;
      case MapHomeLocationNotice.unavailable:
        return t.currentLocationUnavailable;
      case MapHomeLocationNotice.failed:
        return t.currentLocationFailed;
      case MapHomeLocationNotice.searchNoCityResults:
        return t.mapHomeSearchNoCityResults;
      case MapHomeLocationNotice.searchFailed:
        return t.mapHomeSearchFailed;
    }
  }

  Future<void> _submitCitySearch(String value) async {
    FocusScope.of(context).unfocus();
    final locale = Localizations.localeOf(context);
    await _controller.searchCity(value, locale.languageCode);
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _handleTemporaryPlaceStartJourney(
    AppLocalizations t,
    MapHomeCitySearchResultEntity city,
  ) async {
    if (_isCreatingChecklist) {
      return;
    }

    setState(() {
      _isCreatingChecklist = true;
    });

    try {
      final checklistId = await _checklistController
          .createChecklistFromDestinationSnapshot(
            destinationSnapshot: ChecklistDestinationSnapshot(
              name: city.displayName,
              latitude: city.latitude,
              longitude: city.longitude,
              coverImageUrl: null,
              provider: ChecklistDestinationSourceType.mapbox,
              providerPlaceId: city.mapboxId.trim().isEmpty
                  ? null
                  : city.mapboxId.trim(),
              placeLevel: 'city',
              country: city.countryName,
              region: city.regionName,
            ),
            destinationNames: _buildMapboxDestinationNames(city),
          );
      if (!mounted) {
        return;
      }

      if (checklistId == null || checklistId.trim().isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(t.checklistCreateFailed)));
        return;
      }

      context.go(AppRouter.checklistDetail(checklistId));
    } finally {
      if (mounted) {
        setState(() {
          _isCreatingChecklist = false;
        });
      }
    }
  }

  Map<String, String> _buildMapboxDestinationNames(
    MapHomeCitySearchResultEntity city,
  ) {
    final locale = Localizations.localeOf(context).languageCode.toLowerCase();
    final key = locale.startsWith('zh') ? 'zh' : 'en';
    final value = city.displayName.trim();
    if (value.isEmpty) {
      return const <String, String>{};
    }
    // Mapbox 临时地点通常只有当前语言名称，这里只写当前语言并保留 destination 兜底。
    return <String, String>{key: value};
  }
}
