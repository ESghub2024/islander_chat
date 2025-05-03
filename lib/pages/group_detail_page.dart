import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GroupDetailPage extends StatefulWidget {
  final String groupId;
  final String groupName;

  const GroupDetailPage({
    super.key,
    required this.groupId,
    required this.groupName,
  });

  @override
  State<GroupDetailPage> createState() => _GroupDetailPageState();
}

class _GroupDetailPageState extends State<GroupDetailPage> {
  final TextEditingController _chatroomController = TextEditingController();
  bool _isCreating = false;

  @override
  void dispose() {
    _chatroomController.dispose();
    super.dispose();
  }

  Future<void> _createChatroom() async {
    final String name = _chatroomController.text.trim();
    if (name.isEmpty) return;

    setState(() => _isCreating = true);

    try {
      await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .collection('chatrooms')
          .add({
        'name': name,
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (mounted) Navigator.pop(context);
      _chatroomController.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to create chatroom')),
        );
      }
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  void _showCreateChatroomDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Create Chatroom'),
        content: TextField(
          controller: _chatroomController,
          decoration: const InputDecoration(
            hintText: 'Chatroom name',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _chatroomController.clear();
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _isCreating ? null : _createChatroom,
            child: _isCreating
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Create'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.groupName),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Create Chatroom',
            onPressed: _showCreateChatroomDialog,
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('groups')
            .doc(widget.groupId)
            .collection('chatrooms')
            .orderBy('createdAt', descending: false)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Something went wrong.'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final chatrooms = snapshot.data!.docs;

          if (chatrooms.isEmpty) {
            return const Center(child: Text('No chatrooms yet.'));
          }

          return ListView.builder(
            itemCount: chatrooms.length,
            itemBuilder: (context, index) {
              final doc = chatrooms[index];
              final data = doc.data() as Map<String, dynamic>;
              final chatroomId = doc.id;
              final chatroomName = data['name'] ?? 'Unnamed Chatroom';

              return ListTile(
                title: Text(chatroomName),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    '/chatroom',
                    arguments: {
                      'groupId': widget.groupId,
                      'chatroomId': chatroomId,
                      'chatroomName': chatroomName,
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}