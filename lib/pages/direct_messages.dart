import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:islander_chat/components/global_app_bar.dart';
import 'package:islander_chat/pages/chat_page.dart';
import 'package:islander_chat/services/theme_service.dart';
import 'package:provider/provider.dart';

class DirectMessages extends StatefulWidget {
  const DirectMessages({Key? key}) : super(key: key);

  @override
  State<DirectMessages> createState() => _DirectMessagesState();
}

class _DirectMessagesState extends State<DirectMessages> {
  final _auth = FirebaseAuth.instance;
  final Stream<QuerySnapshot> _usersStream =
      FirebaseFirestore.instance.collection('users').snapshots();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Use your global app bar here:
      appBar: GlobalAppBar(
        title: 'Direct Messages',
        showInbox: false,
      ),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: _usersStream,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Error loading users:\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              );
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final docs = snapshot.data!.docs;
            if (docs.isEmpty) {
              return const Center(child: Text('No other users found.'));
            }
            return ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: docs.length,
              itemBuilder: (context, index) {
                return _buildUserListItem(docs[index]);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildUserListItem(DocumentSnapshot document) {
    final data = document.data()! as Map<String, dynamic>;
    final currentEmail = _auth.currentUser?.email;

    // don't show yourself in the DM list
    if (data['email'] == currentEmail) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        elevation: 2,
        borderRadius: BorderRadius.circular(12),
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF2A2A2A)
            : const Color(0xFFF4F4F4),
        child: ListTile(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          leading: const CircleAvatar(child: Icon(Icons.person)),
          title: Text(
            data['nickname'] ?? data['email'] ?? 'Unknown',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 18),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChatPage(
                  receiverUserEmail: data['email'] as String,
                  receiverUserID: data['uid'] as String,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
