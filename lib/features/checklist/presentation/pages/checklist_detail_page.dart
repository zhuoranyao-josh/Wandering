import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

class ChecklistDetailPage extends StatelessWidget {
  const ChecklistDetailPage({super.key, required this.checklistId});

  final String checklistId;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    if (t == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: Text(t.checklistDetailTitle)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            t.checklistDetailComingSoon,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF6B7280)),
          ),
        ),
      ),
    );
  }
}
