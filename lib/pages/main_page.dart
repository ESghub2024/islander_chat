import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:islander_chat/components/group_card.dart';
import 'package:islander_chat/components/global_app_bar.dart';
import 'package:islander_chat/pages/chatroom_page.dart';
import 'package:islander_chat/pages/create_group_page.dart';
import 'package:islander_chat/pages/direct_messages.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  bool isDarkMode = false;
  String searchQuery = '';
  final TextEditingController searchController = TextEditingController();
  Timer? _debounce;

  Stream<QuerySnapshot> getGroups() {
    return FirebaseFirestore.instance
        .collection('groups')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  void toggleTheme() {
    setState(() => isDarkMode = !isDarkMode);
  }

  void onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      setState(() => searchQuery = query.trim());
    });
  }

  void navigateToCreateGroup({DocumentSnapshot? existingGroup}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateGroupPage(groupDoc: existingGroup),
      ),
    );
  }

  void navigateToDirectMessages() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const DirectMessages()),
    );
  }

  void openChatroom(String groupId, String groupName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatroomPage(
          groupId: groupId,
          chatroomId: groupId,
          chatroomName: groupName,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: isDarkMode ? ThemeData.dark() : ThemeData.light(),
      home: Scaffold(
        appBar: GlobalAppBar(
          title: '',
          showInbox: false,
          actions: [
            IconButton(
              icon: const Icon(Icons.message),
              tooltip: 'Direct Messages',
              onPressed: navigateToDirectMessages,
            ),
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: 'Create Group',
              onPressed: () => navigateToCreateGroup(),
            ),
            IconButton(
              icon: Icon(isDarkMode ? Icons.light_mode : Icons.dark_mode),
              tooltip: 'Toggle Theme',
              onPressed: toggleTheme,
            ),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: searchController,
                onChanged: onSearchChanged,
                decoration: const InputDecoration(
                  labelText: 'Search Groups',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: getGroups(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(child: Text('Something went wrong.'));
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final groups = snapshot.data!.docs.where((doc) {
                    final name = (doc['name'] ?? '').toString().toLowerCase();
                    return name.contains(searchQuery.toLowerCase());
                  }).toList();

                  if (groups.isEmpty) {
                    return const Center(child: Text('No groups found.'));
                  }

                  return ListView.builder(
                    itemCount: groups.length,
                    itemBuilder: (context, index) {
                      final doc = groups[index];
                      final data = doc.data() as Map<String, dynamic>;
                      final groupName = data['name'] ?? 'Unnamed Group';
                      final groupId = doc.id;

                      return GroupCard(
                        groupDoc: doc,
                        onEnterChatroom: () => openChatroom(groupId, groupName),
                        onEdit: (groupDoc) => navigateToCreateGroup(existingGroup: groupDoc),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
