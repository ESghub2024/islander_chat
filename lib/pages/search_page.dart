import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:islander_chat/pages/chatroom_page.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUid == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Search Classrooms')),
        body: const Center(child: Text('Please log in to search classrooms.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Search Classrooms')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by name...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onChanged: (v) => setState(() => _searchQuery = v.trim()),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('groups')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('Error loading classrooms'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final name = data['name'] as String? ?? '';
                  final members = List<String>.from(data['members'] ?? []);
                  final matchesSearch = _searchQuery.isEmpty ||
                      name.toLowerCase().contains(_searchQuery.toLowerCase());
                  final notMember = !members.contains(currentUid);
                  return matchesSearch && notMember;
                }).toList();

                if (docs.isEmpty) {
                  return const Center(child: Text('No classrooms found'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final groupName = data['name'] as String? ?? 'Unnamed';
                    final groupId = doc.id;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        title: Text(groupName),
                        subtitle: Text('ID: $groupId'),
                        trailing: ElevatedButton(
                          onPressed: () async {
                            final groupRef = FirebaseFirestore.instance
                                .collection('groups')
                                .doc(groupId);
                            // join the class
                            await groupRef.update({
                              'members': FieldValue.arrayUnion([currentUid])
                            });
                            setState(() {});
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                          child: const Text('Join'),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChatroomPage(
                                groupId: groupId,
                                chatroomName: groupName, chatroomId: '',
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
