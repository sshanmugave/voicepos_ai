import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/app_state.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: appState.notifications.isEmpty
                ? null
                : () => appState.clearNotifications(),
            child: const Text('Clear'),
          ),
        ],
      ),
      body: SafeArea(
        child: appState.notifications.isEmpty
            ? const Center(child: Text('No notifications yet'))
            : ListView.builder(
                itemCount: appState.notifications.length,
                itemBuilder: (context, index) {
                  final n = appState.notifications[index];
                  return Card(
                    child: ListTile(
                      leading: Icon(
                        n.isRead ? Icons.notifications_none : Icons.notifications_active,
                      ),
                      title: Text(n.title),
                      subtitle: Text(n.message),
                      trailing: n.isRead
                          ? null
                          : TextButton(
                              onPressed: () => appState.markNotificationRead(n.id),
                              child: const Text('Mark read'),
                            ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
