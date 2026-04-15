import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/error/app_exception.dart';
import '../../domain/entities/activity_event.dart';
import '../../domain/repositories/activity_repository.dart';
import '../support/activity_category.dart';

class ActivityController extends ChangeNotifier {
  final ActivityRepository activityRepository;

  StreamSubscription<List<ActivityEvent>>? _eventsSubscription;
  bool _isInitialized = false;
  bool _isLoading = false;
  String? _errorCode;
  String _searchQuery = '';
  ActivityCategoryOption? _selectedCategory;
  DateTimeRange? _selectedDateRange;
  List<ActivityEvent> _allEvents = const <ActivityEvent>[];
  List<ActivityEvent> _visibleEvents = const <ActivityEvent>[];

  ActivityController(this.activityRepository);

  bool get isLoading => _isLoading;
  String? get errorCode => _errorCode;
  String get searchQuery => _searchQuery;
  ActivityCategoryOption? get selectedCategory => _selectedCategory;
  DateTimeRange? get selectedDateRange => _selectedDateRange;
  List<ActivityEvent> get visibleEvents => _visibleEvents;

  void ensureInitialized() {
    if (_isInitialized) return;

    _isInitialized = true;
    _isLoading = true;
    _errorCode = null;
    notifyListeners();

    // 进入页面后持续监听 Firestore，后续新增活动时列表会自动刷新。
    _eventsSubscription = activityRepository.watchPublishedEvents().listen(
      (events) {
        _allEvents = events;
        _isLoading = false;
        _errorCode = null;
        _applyFilters();
      },
      onError: (Object error) {
        _isLoading = false;
        if (error is AppException) {
          _errorCode = error.code;
        } else {
          _errorCode = 'activity_load_failed';
        }
        notifyListeners();
      },
    );
  }

  Future<ActivityEvent?> getEventById(String id) async {
    final cached = _allEvents.where((event) => event.id == id).firstOrNull;
    if (cached != null) return cached;

    return activityRepository.getEventById(id);
  }

  void updateSearchQuery(String value) {
    if (_searchQuery == value) return;
    _searchQuery = value;
    _applyFilters();
  }

  void toggleCategory(ActivityCategoryOption option) {
    if (option.isAll) {
      _selectedCategory = null;
    } else if (_selectedCategory?.key == option.key) {
      _selectedCategory = null;
    } else {
      _selectedCategory = option;
    }
    _applyFilters();
  }

  void updateDateRange(DateTimeRange? value) {
    _selectedDateRange = value;
    _applyFilters();
  }

  void clearDateRange() {
    if (_selectedDateRange == null) return;
    _selectedDateRange = null;
    _applyFilters();
  }

  void retry() {
    _eventsSubscription?.cancel();
    _eventsSubscription = null;
    _isInitialized = false;
    ensureInitialized();
  }

  void _applyFilters() {
    final normalizedQuery = _normalize(_searchQuery);
    final filtered =
        _allEvents
            .where((event) {
              if (_selectedCategory != null) {
                final rawCategory = ActivityCategories.fromRawCategory(
                  event.category,
                );
                if (rawCategory?.key != _selectedCategory?.key) {
                  return false;
                }
              }

              if (_selectedDateRange != null &&
                  !_isWithinDateRange(event, _selectedDateRange!)) {
                return false;
              }

              if (normalizedQuery.isNotEmpty) {
                final title = _normalize(event.title);
                final cityName = _normalize(event.cityName);
                if (!title.contains(normalizedQuery) &&
                    !cityName.contains(normalizedQuery)) {
                  return false;
                }
              }

              return true;
            })
            .toList(growable: false)
          ..sort(_compareEventOrder);

    _visibleEvents = filtered;
    notifyListeners();
  }

  int _compareEventOrder(ActivityEvent a, ActivityEvent b) {
    final aStart = a.startAt;
    final bStart = b.startAt;

    // 仍然以 startAt 升序为主，但没有 startAt 的长期营业活动放到后面，
    // 这样“即将开始”列表会优先展示有明确时间的活动。
    if (aStart != null && bStart != null) {
      final startCompare = aStart.compareTo(bStart);
      if (startCompare != 0) {
        return startCompare;
      }
    } else if (aStart != null) {
      return -1;
    } else if (bStart != null) {
      return 1;
    }

    final aUpdated = a.updatedAt ?? a.createdAt;
    final bUpdated = b.updatedAt ?? b.createdAt;

    if (aUpdated != null && bUpdated != null) {
      final updatedCompare = bUpdated.compareTo(aUpdated);
      if (updatedCompare != 0) {
        return updatedCompare;
      }
    } else if (aUpdated != null) {
      return -1;
    } else if (bUpdated != null) {
      return 1;
    }

    return a.title.toLowerCase().compareTo(b.title.toLowerCase());
  }

  bool _isWithinDateRange(ActivityEvent event, DateTimeRange range) {
    // 日期筛选使用“活动时间是否与选择区间重叠”的规则。
    // 允许开始或结束时间为空时，也按开放区间来判断：
    // 1. startAt/endAt 都为空：视为长期营业，始终可见
    // 2. 只有 startAt：从 startAt 起持续开放
    // 3. 只有 endAt：表示在 endAt 前都可视为有效
    final filterStart = DateTime(
      range.start.year,
      range.start.month,
      range.start.day,
    );
    final filterEndExclusive = DateTime(
      range.end.year,
      range.end.month,
      range.end.day + 1,
    );

    final eventStart = event.startAt ?? DateTime(1970, 1, 1);
    final eventEnd = event.endAt ?? DateTime(9999, 12, 31, 23, 59, 59);

    return eventStart.isBefore(filterEndExclusive) &&
        !eventEnd.isBefore(filterStart);
  }

  String _normalize(String value) {
    return value.trim().toLowerCase();
  }

  @override
  void dispose() {
    _eventsSubscription?.cancel();
    super.dispose();
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull {
    if (isEmpty) return null;
    return first;
  }
}
