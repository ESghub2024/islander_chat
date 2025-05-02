// lib/pages/profile_page.dart
import 'dart:io' show File;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:file_picker/file_picker.dart';
import 'package:mime/mime.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:islander_chat/components/global_app_bar.dart';
import 'package:islander_chat/components/text_box.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final currentUser = FirebaseAuth.instance.currentUser!;
  final usersCollection = FirebaseFirestore.instance.collection('users');

  Future<void> editField(String field, String currentValue) async {
    final controller = TextEditingController(text: currentValue);
    final newValue = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit $field'),
        content: Container(
          color: Colors.grey.shade200,
          padding: const EdgeInsets.all(7.0),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: MediaQuery.of(context).size.width * 0.6,
              maxWidth: MediaQuery.of(context).size.width * 0.9,
              minHeight: 25.0,
              maxHeight: 150.0,
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              reverse: true,
              child: TextField(
                controller: controller,
                keyboardType: TextInputType.multiline,
                maxLines: null,
                decoration: InputDecoration.collapsed(
                  hintText: 'Enter new $field',
                ),
              ),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('Save')),
        ],
      ),
    );
    controller.dispose();

    if (newValue != null && newValue.trim().isNotEmpty) {
      try {
        await usersCollection.doc(currentUser.uid).update({ field: newValue.trim() });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$field updated.')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error updating $field: $e')),
          );
        }
      }
    }
  }

  Future<void> changePassword() async {
    final controller = TextEditingController();
    final newPassword = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: TextField(
          controller: controller,
          obscureText: true,
          decoration: const InputDecoration(hintText: 'New password (min 6 chars)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('Update')),
        ],
      ),
    );
    controller.dispose();

    if (newPassword != null && newPassword.trim().length >= 6) {
      try {
        await currentUser.updatePassword(newPassword.trim());
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Password updated successfully.')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error updating password: $e')),
          );
        }
      }
    } else if (newPassword != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password must be at least 6 characters.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const GlobalAppBar(
        title: 'My Profile',
        showInbox: false,
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: usersCollection.doc(currentUser.uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final doc = snapshot.data;
          if (doc == null || !doc.exists) {
            return const Center(child: Text('No user data found.'));
          }
          final userData = doc.data()!;
          final photoUrl = userData['photoUrl'] as String?;

          return SingleChildScrollView(
            child: Column(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      height: 450,
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage('images/profile_bg.jpg'),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 200,
                      left: 0,
                      right: 0,
                      child: Column(
                        children: [
                          GestureDetector(
                            child: SizedBox(
                              width: 250,
                              height: 250,
                              child: ClipOval(
                                child: (photoUrl != null && photoUrl.isNotEmpty)
                                    ? Image.network(
                                        photoUrl,
                                        key: ValueKey(photoUrl),
                                        fit: BoxFit.cover,
                                        loadingBuilder: (ctx, child, prog) {
                                          if (prog == null) return child;
                                          return const Center(child: CircularProgressIndicator());
                                        },
                                        errorBuilder: (ctx, err, stack) {
                                          return Container(
                                            color: Colors.grey.shade200,
                                            child: const Icon(Icons.person, size: 200, color: Colors.grey),
                                          );
                                        },
                                      )
                                    : Container(
                                        color: Colors.grey.shade200,
                                        child: const Icon(Icons.person, size: 200, color: Colors.grey),
                                      ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 15),
                          Text(
                            currentUser.email!,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Joined: ${DateFormat.yMMMd().format(currentUser.metadata.creationTime!.toLocal())}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 100),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text('My Details', style: Theme.of(context).textTheme.titleMedium),
                          const Divider(height: 24),
                          MyTextBox(
                            text: userData['nickname'] ?? '',
                            sectionName: 'Nickname',
                            onPressed: () => editField('nickname', userData['nickname'] ?? ''),
                          ),
                          const SizedBox(height: 12),
                          MyTextBox(
                            text: userData['bio'] ?? '',
                            sectionName: 'Bio',
                            onPressed: () => editField('bio', userData['bio'] ?? ''),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: changePassword,
                            icon: const Icon(Icons.lock_outline),
                            label: const Text('Change Password'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }
}
