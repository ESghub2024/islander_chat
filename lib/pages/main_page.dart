import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:islander_chat/components/global_app_bar.dart';
import 'package:islander_chat/components/group_card.dart';
import 'package:islander_chat/pages/chatroom_page.dart';
import 'package:islander_chat/pages/direct_messages.dart';
import 'package:islander_chat/pages/profile_page.dart';
import 'package:islander_chat/services/theme_service.dart';
import 'package:provider/provider.dart';

class MainPage extends StatefulWidget {
  const MainPage({Key? key}) : super(key: key);

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  bool isDarkMode = false;

  void toggleTheme() {
    setState(() => isDarkMode = !isDarkMode);
  }

  void logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.of(context, rootNavigator: true).pushReplacementNamed('/login');
  }

  void goToProfileScreen() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const ProfileScreen()));
  }

  void showCreateGroupDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Create New Classroom'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Enter name'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                final uid = FirebaseAuth.instance.currentUser!.uid;
                await FirebaseFirestore.instance.collection('groups').add({
                  'name': name,
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

  void confirmDeleteGroup(String id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Classroom'),
        content: const Text('Delete this classroom?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('groups')
                  .doc(id)
                  .delete();
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
    final currentUid = FirebaseAuth.instance.currentUser?.uid;

    return MaterialApp(
      theme: isDarkMode ? ThemeData.dark() : ThemeData.light(),
      debugShowCheckedModeBanner: false,
      routes: {
        '/inbox': (_) => const DirectMessages(),
      },
      home: Scaffold(
        appBar: GlobalAppBar(
          title: 'Your Classrooms',
          showSearch: true,
          showInbox: true,
          onAddGroup: showCreateGroupDialog,
          onSearch: () {
            Navigator.pushNamed(context, '/search');
          },
          onToggleTheme: () => context.read<ThemeService>().toggleTheme(),
          onProfile: goToProfileScreen,
        ),

        body: currentUid == null
            ? const Center(
                child: Text('Please log in to view your classrooms.'),
              )
            : StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('groups')
                    .where('members', arrayContains: currentUid)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = snapshot.data!.docs;
                  if (docs.isEmpty) {
                    return const Center(
                        child: Text('You are not enrolled in any classrooms.'));
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final doc = docs[index];
                      final data = doc.data() as Map<String, dynamic>;
                      final name = data['name'] as String? ?? 'Unnamed';
                      final id = doc.id;
                      final owner = data['owner'] as String?;
                      final isOwner = owner == currentUid;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: GroupCard(
                          groupName: name,
                          groupId: id,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChatroomPage(
                                groupId: id,
                                chatroomName: name,
                              ),
                            ),
                          ),
                          footer: Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () async {
                                    if (isOwner) {
                                      await FirebaseFirestore.instance
                                          .collection('groups')
                                          .doc(id)
                                          .delete();
                                    } else {
                                      await FirebaseFirestore.instance
                                          .collection('groups')
                                          .doc(id)
                                          .update({
                                        'members': FieldValue.arrayRemove(
                                            [currentUid])
                                      });
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          isOwner ? Colors.red : Colors.orange),
                                  child:
                                      Text(isOwner ? 'Delete' : 'Leave'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.copy),
                                tooltip: 'Copy ID',
                                onPressed: () {
                                  Clipboard.setData(
                                      ClipboardData(text: id));
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(const SnackBar(
                                          content:
                                              Text('Classroom ID copied')));
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
      ),
    );
  }
}
