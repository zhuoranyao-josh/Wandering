import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/app_router.dart';
import '../../../../l10n/app_localizations.dart';

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    if (t == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: Text(t.adminDashboardTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Card(
            child: ListTile(
              leading: const Icon(Icons.place_outlined),
              title: Text(t.adminManagePlaces),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push(AppRouter.adminPlaces),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.local_activity_outlined),
              title: Text(t.adminManageActivities),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push(AppRouter.adminActivities),
            ),
          ),
        ],
      ),
    );
  }
}
