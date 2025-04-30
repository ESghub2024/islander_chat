import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:islander_chat/components/group_card.dart';
import 'package:islander_chat/components/global_app_bar.dart';
import 'chatroom_page.dart';
import 'direct_messages.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  bool isDarkMode = false;

  void toggleTheme() {
    setState(() {
      isDarkMode = !isDarkMode;
    });
  }

  void logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  void showCreateGroupDialog() {
    final TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Group'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Enter group name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              String groupName = controller.text.trim();
              if (groupName.isNotEmpty) {
                final uid = FirebaseAuth.instance.currentUser?.uid;
                await FirebaseFirestore.instance.collection('groups').add({
                  'name': groupName,
                  'owner': uid,
                  'members': [uid],
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

  void confirmDeleteGroup(String groupId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Group'),
        content: const Text('Are you sure you want to delete this group?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance.collection('groups').doc(groupId).delete();
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: isDarkMode ? ThemeData.dark() : ThemeData.light(),
      routes: {
        '/inbox': (context) => const DirectMessages(),
      },
      home: Scaffold(
        appBar: GlobalAppBar(
          title: 'Your Classrooms',
          onAddGroup: showCreateGroupDialog,
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('groups')
              .orderBy('createdAt', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Center(child: Text('Something went wrong.'));
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final groups = snapshot.data!.docs;

            return SizedBox(
              width: double.infinity,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.all(24),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(16),
                    color: Theme.of(context).colorScheme.background,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(24),
                  child: Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: groups.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final groupName = data['name'] ?? 'Unnamed Group';
                      final groupId = doc.id;
                      final ownerId = data['owner'];
                      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
                      final members = List<String>.from(data['members'] ?? []);
                      final isMember = members.contains(currentUserId);

                      return SizedBox(
                        width: 250,
                        height: 450,
                        child: GroupCard(
                          groupName: groupName,
                          groupId: groupId,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ChatroomPage(
                                  groupId: groupId,
                                  chatroomId: 'some_chatroom_id', // Replace if needed
                                  chatroomName: groupName,
                                ),
                              ),
                            );
                          },
                          footer: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              ElevatedButton(
                                onPressed: () {
                                  final groupRef = FirebaseFirestore.instance
                                      .collection('groups')
                                      .doc(groupId);
                                  if (isMember) {
                                    showDialog(
                                      context: context,
                                      builder: (_) => AlertDialog(
                                        title: const Text('Leave Class'),
                                        content: const Text('Are you sure you want to leave this class?'),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(context),
                                            child: const Text('Cancel'),
                                          ),
                                          ElevatedButton(
                                            onPressed: () async {
                                              await groupRef.update({
                                                'members': FieldValue.arrayRemove([currentUserId])
                                              });
                                              Navigator.pop(context);
                                            },
                                            child: const Text('Leave'),
                                          ),
                                        ],
                                      ),
                                    );
                                  } else {
                                    groupRef.update({
                                      'members': FieldValue.arrayUnion([currentUserId])
                                    });
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isMember ? Colors.red : Colors.green,
                                ),
                                child: Text(isMember ? 'Leave' : 'Join'),
                              ),
                              if (ownerId == currentUserId)
                                ElevatedButton(
                                  onPressed: () => confirmDeleteGroup(groupId),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                  ),
                                  child: const Text('Delete'),
                                ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
