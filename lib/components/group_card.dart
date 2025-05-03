import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GroupCard extends StatelessWidget {
  final DocumentSnapshot groupDoc;
  final VoidCallback onEnterChatroom;
  final Function(DocumentSnapshot groupDoc) onEdit;

  const GroupCard({
    super.key,
    required this.groupDoc,
    required this.onEnterChatroom,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final data = groupDoc.data() as Map<String, dynamic>;
    final groupName = data['name'] ?? 'Unnamed Group';
    final groupId = groupDoc.id;
    final members = (data['members'] as List?)?.length ?? 0;
    final user = FirebaseAuth.instance.currentUser;
    final isOwner = user != null && data['owner'] == user.uid;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: Colors.lightBlue,
                  child: const Icon(Icons.group, size: 28, color: Colors.white),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        groupName,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ID: $groupId',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      Text(
                        '$members member${members == 1 ? '' : 's'}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                if (isOwner)
                  PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == 'edit') {
                        onEdit(groupDoc);
                      } else if (value == 'delete') {
                        _confirmAndDeleteGroup(context, groupDoc);
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: 'edit', child: Text('Edit Group')),
                      PopupMenuItem(value: 'delete', child: Text('Delete Group')),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: onEnterChatroom,
                icon: const Icon(Icons.forum),
                label: const Text('Enter Chatroom'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmAndDeleteGroup(BuildContext context, DocumentSnapshot groupDoc) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final data = groupDoc.data() as Map<String, dynamic>;
    final ownerId = data['owner'];

    if (ownerId != user.uid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Only the group owner can delete this group.')),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Group'),
        content: const Text('Are you sure you want to delete this group? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final chatrooms = await groupDoc.reference.collection('chatrooms').get();
      for (final chatroom in chatrooms.docs) {
        final messages = await chatroom.reference.collection('messages').get();
        for (final msg in messages.docs) {
          await msg.reference.delete();
        }
        await chatroom.reference.delete();
      }

      await groupDoc.reference.delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Group deleted successfully.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting group: $e')),
      );
    }
  }
}
