import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GlobalAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showInbox;

  const GlobalAppBar({super.key, required this.title, this.showInbox = true});

  void logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      actions: [
        if (showInbox)
          IconButton(
            icon: const Icon(Icons.mail_outline),
            tooltip: 'Direct Messages',
            onPressed: () {
              Navigator.pushNamed(context, '/inbox');
            },
          ),
        IconButton(
          icon: const Icon(Icons.brightness_6),
          tooltip: 'Toggle Theme',
          onPressed: () {
            // optionally implement global theme toggling here
          },
        ),
        IconButton(
          icon: const Icon(Icons.person),
          tooltip: 'Profile (not implemented)',
          onPressed: () {},
        ),
        IconButton(
          icon: const Icon(Icons.logout),
          tooltip: 'Logout',
          onPressed: () => logout(context),
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
