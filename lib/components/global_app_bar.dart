import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:islander_chat/pages/profile_page.dart';

class GlobalAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onAddGroup;
  final bool showLogout;
  final bool showProfile;
  final List<Widget> actions;

  const GlobalAppBar({
    super.key,
    required this.title,
    this.onAddGroup,
    this.showLogout = true,
    this.showProfile = true,
    required this.actions, required bool showInbox,
  });

  Future<void> logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (context.mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  List<Widget> _buildActions(BuildContext context) {
    final builtActions = <Widget>[];

    if (onAddGroup != null) {
      builtActions.add(
        IconButton(
          icon: const Icon(Icons.group_add),
          tooltip: 'Create Group',
          onPressed: onAddGroup,
        ),
      );
    }

    if (showProfile) {
      builtActions.add(
        IconButton(
          icon: const Icon(Icons.person),
          tooltip: 'Profile',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            );
          },
        ),
      );
    }

    if (showLogout) {
      builtActions.add(
        IconButton(
          icon: const Icon(Icons.logout),
          tooltip: 'Logout',
          onPressed: () => logout(context),
        ),
      );
    }

    builtActions.addAll(actions);
    return builtActions;
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Theme.of(context).appBarTheme.foregroundColor ?? Colors.white,
              fontWeight: FontWeight.bold,
            ),
      ),
      backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
      actions: _buildActions(context),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
