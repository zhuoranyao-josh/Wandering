import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/app_router.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../l10n/app_localizations.dart';
import '../controllers/activity_controller.dart';
import '../support/activity_category.dart';
import '../support/activity_date_formatter.dart';
import '../widgets/activity_event_card.dart';

class ActivityPage extends StatefulWidget {
  const ActivityPage({super.key});

  @override
  State<ActivityPage> createState() => _ActivityPageState();
}

class _ActivityPageState extends State<ActivityPage> {
  late final ActivityController _controller;
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _controller = ServiceLocator.activityController;
    _searchController = TextEditingController(text: _controller.searchQuery);
    _controller.ensureInitialized();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _showDateFilterActions(AppLocalizations t) async {
    final selectedAction = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.date_range_outlined),
                  title: Text(t.activitySelectDateRange),
                  onTap: () => Navigator.of(context).pop('pick'),
                ),
                if (_controller.selectedDateRange != null)
                  ListTile(
                    leading: const Icon(Icons.clear_rounded),
                    title: Text(t.activityClearDateFilter),
                    onTap: () => Navigator.of(context).pop('clear'),
                  ),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted || selectedAction == null) return;

    if (selectedAction == 'clear') {
      _controller.clearDateRange();
      return;
    }

    final now = DateTime.now();
    final initialRange =
        _controller.selectedDateRange ?? DateTimeRange(start: now, end: now);

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 5),
      initialDateRange: initialRange,
      saveText: t.save,
      cancelText: t.cancel,
      helpText: t.activitySelectDateRange,
    );

    if (!mounted) return;
    _controller.updateDateRange(picked);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    if (t == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final localeTag = Localizations.localeOf(context).toLanguageTag();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return Column(
              children: [
                // 顶部固定筛选区：搜索、日期筛选、分类按钮都放在这里。
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  color: const Color(0xFFF8FAFC),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              onChanged: _controller.updateSearchQuery,
                              textInputAction: TextInputAction.search,
                              decoration: InputDecoration(
                                hintText: t.activitySearchHint,
                                prefixIcon: const Icon(Icons.search_rounded),
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(18),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Material(
                            color: _controller.selectedDateRange == null
                                ? Colors.white
                                : const Color(0xFFDBEAFE),
                            borderRadius: BorderRadius.circular(18),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(18),
                              onTap: () => _showDateFilterActions(t),
                              child: SizedBox(
                                width: 54,
                                height: 54,
                                child: Icon(
                                  Icons.calendar_month_outlined,
                                  color: _controller.selectedDateRange == null
                                      ? const Color(0xFF1F2937)
                                      : const Color(0xFF2563EB),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 40,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: ActivityCategories.all.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            final option = ActivityCategories.all[index];
                            final isSelected = option.isAll
                                ? _controller.selectedCategory == null
                                : _controller.selectedCategory?.key ==
                                      option.key;

                            return ChoiceChip(
                              label: Text(option.label(t)),
                              selected: isSelected,
                              onSelected: (_) =>
                                  _controller.toggleCategory(option),
                              showCheckmark: false,
                              selectedColor: const Color(0xFF2563EB),
                              backgroundColor: Colors.white,
                              labelStyle: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : const Color(0xFF374151),
                                fontWeight: FontWeight.w600,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(999),
                                side: BorderSide(
                                  color: isSelected
                                      ? const Color(0xFF2563EB)
                                      : const Color(0xFFE5E7EB),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      if (_controller.selectedDateRange != null) ...[
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '${t.activityDateFilterLabel}: ${ActivityDateFormatter.formatDateFilter(dateRange: _controller.selectedDateRange!, localeTag: localeTag)}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF2563EB),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // 固定标题区：保持“即将开始”始终在列表上方可见。
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      t.activityUpcomingTitle,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF111827),
                      ),
                    ),
                  ),
                ),
                Expanded(child: _buildBody(t)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildBody(AppLocalizations t) {
    if (_controller.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_controller.errorCode != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                t.activityLoadFailed,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _controller.retry,
                child: Text(t.activityRetry),
              ),
            ],
          ),
        ),
      );
    }

    if (_controller.visibleEvents.isEmpty) {
      final isFiltering =
          _controller.searchQuery.trim().isNotEmpty ||
          _controller.selectedCategory != null ||
          _controller.selectedDateRange != null;

      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            isFiltering ? t.activityEmptyFiltered : t.activityEmptyDefault,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              height: 1.6,
              color: Color(0xFF6B7280),
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        _controller.retry();
      },
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        itemCount: _controller.visibleEvents.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final event = _controller.visibleEvents[index];
          return ActivityEventCard(
            event: event,
            onTap: () {
              context.push(AppRouter.activityDetail(event.id), extra: event);
            },
          );
        },
      ),
    );
  }
}
