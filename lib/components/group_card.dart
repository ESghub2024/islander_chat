import 'package:flutter/material.dart';

/// A simple card widget displaying a classroom name and ID, with a customizable footer and tap handler.
class GroupCard extends StatelessWidget {
  final String groupName;
  final String groupId;
  final Widget footer;
  final VoidCallback onTap;

  const GroupCard({
    Key? key,
    required this.groupName,
    required this.groupId,
    required this.footer,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              groupName,
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            Text(
              'ID: $groupId',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            footer,
          ],
        ),
      ),
    );
  }
}
