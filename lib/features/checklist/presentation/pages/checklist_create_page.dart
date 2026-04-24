import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

class ChecklistCreatePage extends StatelessWidget {
  const ChecklistCreatePage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    if (t == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: Text(t.createChecklist)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            t.checklistCreateComingSoon,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF6B7280)),
          ),
        ),
      ),
    );
  }
}
