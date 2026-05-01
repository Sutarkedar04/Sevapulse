import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:badges/badges.dart' as badges;
import '../../../core/theme/theme_extensions.dart'; // ✅ ADD THEME EXTENSION
import '../../../data/providers/notification_provider.dart';
import '../screens/notifications_screen.dart';

class NotificationBell extends StatelessWidget {
  const NotificationBell({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationProvider>(
      builder: (context, provider, child) {
        return badges.Badge(
          showBadge: provider.unreadCount > 0,
          badgeContent: Text(
            '${provider.unreadCount}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          badgeStyle: badges.BadgeStyle(
            badgeColor: Colors.red,
            padding: const EdgeInsets.all(4),
          ),
          position: badges.BadgePosition.topEnd(top: 8, end: 8),
          child: IconButton(
            icon: Icon(
              Icons.notifications_outlined,
              color: Colors.white,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationsScreen(),
                ),
              );
            },
            tooltip: 'Notifications',
          ),
        );
      },
    );
  }
}