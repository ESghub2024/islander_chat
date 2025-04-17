import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../components/group_card.dart';
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
              if (mounted) Navigator.pop(context);
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
        appBar: AppBar(
          title: const Text(
            'Your Classrooms',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          actions: [
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
              onPressed: toggleTheme,
            ),
            IconButton(
              icon: const Icon(Icons.person),
              tooltip: 'Profile (not implemented)',
              onPressed: () {},
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Logout',
              onPressed: logout,
            ),
          ],
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
              width: 1900,
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
                    children: [
                      ...groups.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final groupName = data['name'] ?? 'Unnamed Group';
                        final groupId = doc.id;
                        final ownerId = data['owner'];
                        final currentUserId = FirebaseAuth.instance.currentUser?.uid;

                        return Stack(
                          children: [
                            SizedBox(
                              width: 400,
                              height: 780,
                              child: GroupCard(
                                groupName: groupName,
                                groupId: groupId,
                                onTap: () {
                                  Navigator.pushNamed(
                                    context,
                                    '/group_detail',
                                    arguments: {
                                      'groupId': groupId,
                                      'groupName': groupName
                                    },
                                  );
                                },
                              ),
                            ),
                            if (ownerId == currentUserId)
                              Positioned(
                                top: 8,
                                right: 8,
                                child: IconButton(
                                  icon: const Icon(Icons.close),
                                  color: Colors.red,
                                  tooltip: 'Delete Group',
                                  onPressed: () => confirmDeleteGroup(groupId),
                                ),
                              ),
                          ],
                        );
                      }).toList(),
                      SizedBox(
                        width: 160,
                        height: 160,
                        child: InkWell(
                          onTap: showCreateGroupDialog,
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.secondaryContainer,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Theme.of(context).colorScheme.outline,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Icon(Icons.add, size: 40),
                            ),
                          ),
                        ),
                      ),
                    ],
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