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
  void showCreateChatroomDialog() {
    final TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Create New Chatroom'),
            content: TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'Enter chatroom name',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  String roomName = controller.text.trim();
                  if (roomName.isNotEmpty) {
                    await FirebaseFirestore.instance
                        .collection('groups')
                        .doc(widget.groupId)
                        .collection('chatrooms')
                        .add({
                          'name': roomName,
                          'createdAt': FieldValue.serverTimestamp(),
                        });
                    Navigator.pop(context);
                  }
                },
                child: const Text('Create'),
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
            onPressed: showCreateChatroomDialog,
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('groups')
                .doc(widget.groupId)
                .collection('chatrooms')
                .orderBy('createdAt')
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
              final roomId = doc.id;
              final roomName = data['name'] ?? 'Unnamed Room';

              return ListTile(
                title: Text(roomName),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    '/chatroom',
                    arguments: {
                      'groupId': widget.groupId,
                      'chatroomId': roomId,
                      'chatroomName': roomName,
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
