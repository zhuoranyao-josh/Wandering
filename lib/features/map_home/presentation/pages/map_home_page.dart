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
import '../../../../l10n/app_localizations.dart';
import '../controllers/map_home_controller.dart';
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
  static const double _topActionTopMargin = 12;
  static const double _topActionSize = 52;
  static const double _topActionToCompassGap = 10;
  static const double _ornamentBottomMargin = 8;
  static const double _floatingInset = 16;

  late final MapHomeController _controller =
      ServiceLocator.createMapHomeController(
        initialMarkerZoom: _initialMapZoom,
      );
  Locale? _lastLocale;
  bool? _lastHasSelectedPlace;
  int? _lastLocationNoticeVersion;

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
            final hasSelectedPlace = _controller.selectedPlace != null;
            if (_lastHasSelectedPlace != hasSelectedPlace) {
              _lastHasSelectedPlace = hasSelectedPlace;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                unawaited(
                  _controller.updateScaleBarVisibility(!hasSelectedPlace),
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
                _buildTopRightAction(t),
                if (_controller.selectedPlace != null)
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
        _topActionSize +
        _topActionToCompassGap;

    await mapboxMap.scaleBar.updateSettings(
      ScaleBarSettings(
        enabled: _controller.selectedPlace == null,
        position: OrnamentPosition.BOTTOM_RIGHT,
        marginRight: _topActionHorizontalMargin,
        marginBottom: _ornamentBottomMargin,
      ),
    );

    await mapboxMap.compass.updateSettings(
      CompassSettings(
        position: OrnamentPosition.TOP_RIGHT,
        marginRight: _topActionHorizontalMargin,
        marginTop: compassTop,
      ),
    );
  }

  Widget _buildTopRightAction(AppLocalizations t) {
    final isNightMode = _controller.lightPreset == MapHomeLightPreset.night;

    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(
        _topActionHorizontalMargin,
        _topActionTopMargin,
        _topActionHorizontalMargin,
        0,
      ),
      child: Align(
        alignment: Alignment.topRight,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 顶部操作按钮继续集中在右上角，避免影响现有卡片和地图手势区域。
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
    if (place == null) {
      return const SizedBox.shrink();
    }

    // 卡片文案直接走实体本地化方法，UI 不再自己判断语言分支。
    final languageCode = Localizations.localeOf(context).languageCode;
    final copy = place.localizedCopy(languageCode);

    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(
        _floatingInset,
        _floatingInset,
        _floatingInset,
        _floatingInset,
      ),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: PlacePreviewCard(
          title: copy.name,
          description: copy.description,
          imageUrl: place.coverImage,
          buttonText: t.viewDetails,
          onClose: _controller.clearSelectedPlace,
          onPressed: () {
            // 仅传递当前已有真实字段，详情数据后续由正式数据链路接管。
            final initialModel = PlaceDetailUiModel.fromPlaceEntity(
              place: place,
            );
            context.push(AppRouter.placeDetails(place.id), extra: initialModel);
          },
        ),
      ),
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
    }
  }
}
