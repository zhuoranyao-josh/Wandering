import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/error/app_exception.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/post_location.dart';
import '../controllers/community_controller.dart';

class LocationSearchPage extends StatefulWidget {
  const LocationSearchPage({super.key});

  @override
  State<LocationSearchPage> createState() => _LocationSearchPageState();
}

class _LocationSearchPageState extends State<LocationSearchPage> {
  late final TextEditingController _searchController;
  late final CommunityController _communityController;
  Timer? _debounce;
  List<PostLocation> _results = const <PostLocation>[];
  bool _isLoading = false;
  String? _errorCode;
  String _currentQuery = '';
  int _requestId = 0;
  String? _resolvingLocationId;
  late String _sessionToken;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _communityController = ServiceLocator.communityController;
    _sessionToken = _buildSessionToken();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    final cleanQuery = value.trim();

    if (cleanQuery.isEmpty) {
      setState(() {
        _currentQuery = '';
        _results = const <PostLocation>[];
        _errorCode = null;
        _isLoading = false;
        _sessionToken = _buildSessionToken();
      });
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 350), () {
      _searchLocations(cleanQuery);
    });
  }

  Future<void> _searchLocations(String query) async {
    final requestId = ++_requestId;
    setState(() {
      _currentQuery = query;
      _isLoading = true;
      _errorCode = null;
    });

    try {
      final results = await _communityController.searchLocations(
        query: query,
        sessionToken: _sessionToken,
      );
      if (!mounted || requestId != _requestId) {
        return;
      }

      setState(() {
        _results = results;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted || requestId != _requestId) {
        return;
      }

      setState(() {
        _results = const <PostLocation>[];
        _isLoading = false;
        _errorCode = error is AppException
            ? error.code
            : 'community_location_search_failed';
      });
    }
  }

  Future<void> _selectLocation(PostLocation suggestion) async {
    final resolvingId = suggestion.mapboxId ?? suggestion.fullLabel ?? '';
    setState(() {
      _resolvingLocationId = resolvingId;
    });

    try {
      final resolvedLocation = await _communityController.retrieveLocation(
        suggestion,
      );
      if (!mounted) {
        return;
      }
      context.pop(resolvedLocation);
    } catch (error) {
      if (!mounted) {
        return;
      }

      final errorCode = error is AppException
          ? error.code
          : 'community_location_search_failed';
      final t = AppLocalizations.of(context);
      _errorCode = errorCode;
      final message = _messageForError(t);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) {
        setState(() {
          _resolvingLocationId = null;
        });
      }
    }
  }

  String _messageForError(AppLocalizations? t) {
    if (t == null) {
      return '';
    }

    switch (_errorCode) {
      case 'community_location_search_failed':
        return t.communityLocationSearchFailed;
      default:
        return t.errorUnknown;
    }
  }

  String _buildSessionToken() {
    final timestamp = DateTime.now().microsecondsSinceEpoch.toRadixString(16);
    final random = Random.secure().nextInt(1 << 32).toRadixString(16);
    return 'community-$timestamp-$random';
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    if (t == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(title: Text(t.communityLocationSearchTitle)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: t.communityLocationSearchHint,
                  prefixIcon: const Icon(Icons.search_rounded),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(child: _buildBody(t)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(AppLocalizations t) {
    if (_currentQuery.isEmpty) {
      return Center(
        child: Text(
          t.communityLocationSearchEmptyHint,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14, color: Color(0xFF64748B)),
        ),
      );
    }

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorCode != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _messageForError(t),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF334155),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => _searchLocations(_currentQuery),
              child: Text(t.communityRetry),
            ),
          ],
        ),
      );
    }

    if (_results.isEmpty) {
      return Center(
        child: Text(
          t.communityLocationSearchEmptyResult,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14, color: Color(0xFF64748B)),
        ),
      );
    }

    // 列表先展示 suggest 结果，点击后再换取包含坐标的完整地点详情。
    return ListView.separated(
      itemCount: _results.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final location = _results[index];
        final locationId = location.mapboxId ?? location.fullLabel ?? '';
        final isResolving = _resolvingLocationId == locationId;
        return Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          child: ListTile(
            onTap: isResolving ? null : () => _selectLocation(location),
            leading: const Icon(Icons.place_outlined, color: Color(0xFFDC2626)),
            title: Text(
              location.fullName ?? location.fullLabel ?? '',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0F172A),
              ),
            ),
            subtitle: _buildSubtitle(location),
            trailing: isResolving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xFF94A3B8),
                  ),
          ),
        );
      },
    );
  }

  Widget? _buildSubtitle(PostLocation location) {
    final subtitle = location.placeFormatted ?? location.summaryLabel;
    if (subtitle == null || subtitle.trim().isEmpty) {
      return null;
    }

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        subtitle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
      ),
    );
  }
}
