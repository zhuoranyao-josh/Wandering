import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/activity_event.dart';

class ActivityDetailPage extends StatelessWidget {
  final String eventId;
  final ActivityEvent? initialEvent;

  const ActivityDetailPage({
    super.key,
    required this.eventId,
    this.initialEvent,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    if (t == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final title = initialEvent?.title.trim();
    final displayTitle = (title != null && title.isNotEmpty)
        ? title
        : t.activityDetailTitle;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          // 详情页先使用最简单的返回逻辑，方便后续继续扩展页面内容。
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            }
          },
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
        title: Text(
          displayTitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Color(0xFF111827),
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: false,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            t.activityDetailEmpty,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 15,
              height: 1.6,
            ),
          ),
        ),
      ),
    );
  }
}
