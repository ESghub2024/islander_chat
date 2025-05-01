// lib/profile_screen.dart
import 'dart:io' show File;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:file_picker/file_picker.dart';
import 'package:mime/mime.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:islander_chat/components/text_box.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final currentUser = FirebaseAuth.instance.currentUser!;
  // Use the exact same collection name everywhere:
  final usersCollection = FirebaseFirestore.instance.collection('users');

  Future<void> editField(String field, String currentValue) async {
    final controller = TextEditingController(text: currentValue);
    final newValue = await showDialog<String>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Edit $field'),
            content: TextField(
              controller: controller,
              decoration: InputDecoration(hintText: 'Enter new $field'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, controller.text),
                child: const Text('Save'),
              ),
            ],
          ),
    );
    controller.dispose();

    if (newValue != null && newValue.trim().isNotEmpty) {
      try {
        await usersCollection.doc(currentUser.uid).update({
          field: newValue.trim(),
        });
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('$field updated.')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error updating $field: $e')));
        }
      }
    }
  }

  Future<void> changePassword() async {
    final controller = TextEditingController();
    final newPassword = await showDialog<String>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Change Password'),
            content: TextField(
              controller: controller,
              obscureText: true,
              decoration: const InputDecoration(
                hintText: 'New password (min 6 chars)',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, controller.text),
                child: const Text('Update'),
              ),
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
          const SnackBar(
            content: Text('Password must be at least 6 characters.'),
          ),
        );
      }
    }
  }

  /*
  Future<void> changeProfileImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: kIsWeb,
    );
    if (result == null) return; // User cancelled

    final picked = result.files.single;
    final userId = currentUser.uid;
    final bucket = FirebaseStorage.instance.app.options.storageBucket;
    final storageRef = FirebaseStorage.instanceFor(
      bucket: bucket,
    ).ref().child('profile_images/$userId.jpg');

    try {
      if (kIsWeb) {
        final bytes = picked.bytes;
        if (bytes == null) throw Exception('No file bytes available for web');
        await storageRef.putData(bytes);
      } else {
        final path = picked.path;
        if (path == null) {
          throw Exception('No file path available on this platform');
        }
        final mimeType = lookupMimeType(path) ?? 'application/octet-stream';
        final file = File(path);
        final metadata = SettableMetadata(contentType: mimeType);
        await storageRef.putFile(file, metadata);
      }

      final downloadUrl = await storageRef.getDownloadURL();
      await usersCollection.doc(userId).update({'photoUrl': downloadUrl});

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Profile image updated.')));
      }
    } catch (e) {
      debugPrint('Error uploading image: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error uploading image: $e')));
      }
    }
  }
*/
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: const Color.fromARGB(255, 0, 103, 197),
        leading: const BackButton(),
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
                                child:
                                    (photoUrl != null && photoUrl.isNotEmpty)
                                        ? Image.network(
                                          photoUrl,
                                          key: ValueKey(photoUrl),
                                          fit: BoxFit.cover,
                                          loadingBuilder: (ctx, child, prog) {
                                            if (prog == null) return child;
                                            return const Center(
                                              child:
                                                  CircularProgressIndicator(),
                                            );
                                          },
                                          errorBuilder: (ctx, err, stack) {
                                            debugPrint(
                                              '⚠️ Image.network failed: $err',
                                            );
                                            return Container(
                                              color: Colors.grey.shade200,
                                              child: const Icon(
                                                Icons.person,
                                                size: 200,
                                                color: Colors.grey,
                                              ),
                                            );
                                          },
                                        )
                                        : Container(
                                          color: Colors.grey.shade200,
                                          child: const Icon(
                                            Icons.person,
                                            size: 200,
                                            color: Colors.grey,
                                          ),
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
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'My Details',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const Divider(height: 24),
                          MyTextBox(
                            text: userData['nickname'] ?? '',
                            sectionName: 'Nickname',
                            onPressed:
                                () => editField(
                                  'nickname',
                                  userData['nickname'] ?? '',
                                ),
                          ),
                          const SizedBox(height: 12),
                          MyTextBox(
                            text: userData['bio'] ?? '',
                            sectionName: 'Bio',
                            onPressed:
                                () => editField('bio', userData['bio'] ?? ''),
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
