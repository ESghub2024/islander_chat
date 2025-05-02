import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../services/notification_service.dart';

class GlobalAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showInbox;
  final bool showSearch;
  final VoidCallback? onAddGroup;
  final VoidCallback? onSearch;
  final VoidCallback? onToggleTheme;
  final VoidCallback? onProfile;

  const GlobalAppBar({
    Key? key,
    required this.title,
    this.showInbox = true,
    this.showSearch = false,
    this.onAddGroup,
    this.onSearch,
    this.onToggleTheme,
    this.onProfile,
  }) : super(key: key);

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    // wipe the back stack and go to login
    Navigator.of(context,rootNavigator: true).pushNamedAndRemoveUntil('/login', (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final notifSvc = context.watch<NotificationService>();

    return AppBar(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      actions: [
        if (onAddGroup != null)
          IconButton(
            icon: const Icon(Icons.group_add),
            tooltip: 'Create Group',
            onPressed: onAddGroup,
          ),

        if (showSearch)
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Search',
            onPressed: onSearch ?? () => Navigator.pushNamed(context, '/search'),
          ),

        if (showInbox)
          IconButton(
            icon: const Icon(Icons.mail_outline),
            tooltip: 'Direct Messages',
            onPressed: () => Navigator.pushNamed(context, '/inbox'),
          ),

        // Bell + badge
        Stack(alignment: Alignment.topRight, children: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
            tooltip: 'Notifications',
            onPressed: () => _showNotificationsSheet(context),
          ),
          if (notifSvc.unreadCount > 0)
            Positioned(
              right: 11,
              top: 11,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(6),
                ),
                constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                child: Text(
                  '${notifSvc.unreadCount}',
                  style: const TextStyle(color: Colors.white, fontSize: 8),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ]),

        // Theme toggle
        IconButton(
          icon: const Icon(Icons.brightness_6),
          tooltip: 'Toggle Theme',
          onPressed: onToggleTheme ?? () {},
        ),

        // Profile
        IconButton(
          icon: const Icon(Icons.person),
          tooltip: 'Profile',
          onPressed: onProfile ?? () => Navigator.pushNamed(context, '/profile'),
        ),

        // Logout
        IconButton(
          icon: const Icon(Icons.logout),
          tooltip: 'Logout',
          onPressed: () => _logout(context),
        ),
      ],
    );
  }

  void _showNotificationsSheet(BuildContext context) {
    final notifs = context.read<NotificationService>().items;
    showModalBottomSheet(
      context: context,
      builder: (_) => ListView.separated(
        padding: const EdgeInsets.all(8),
        itemCount: notifs.length,
        separatorBuilder: (_, __) => const Divider(),
        itemBuilder: (c, i) {
          final n = notifs[i];
          return ListTile(
            title: Text(n.title),
            subtitle: Text(n.subtitle),
            trailing: Text(timeago.format(n.timestamp)),
            onTap: () {
              // TODO: deep-link into the classroom / DM
            },
          );
        },
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
