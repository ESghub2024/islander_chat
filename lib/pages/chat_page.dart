import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:islander_chat/components/chat_bubble.dart';
import 'package:islander_chat/components/my_text_field.dart';
import 'package:islander_chat/services/chat/chat_service.dart';

class ChatPage extends StatefulWidget {
  final String receiverUserEmail;
  final String receiverUserID;

  const ChatPage({
    super.key,
    required this.receiverUserEmail,
    required this.receiverUserID,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ChatService _chatService = ChatService();
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  void sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isNotEmpty) {
      await _chatService.sendDirectMessage(
        widget.receiverUserID,
        message,
        isImage: false,
      );
      _messageController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.receiverUserEmail)),
      body: Column(
        children: [
          Expanded(child: _buildMessageList()),
          _buildMessageInput(),
          _buildPostImageButton(),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    final currentUserId = _firebaseAuth.currentUser?.uid;
    if (currentUserId == null) return const SizedBox.shrink();

    return StreamBuilder(
      stream: _chatService.getDirectMessages(currentUserId, widget.receiverUserID),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        return ListView(
          reverse: true,
          children: snapshot.data!.docs
              .map((document) => _buildMessageItem(document))
              .toList(),
        );
      },
    );
  }

  Widget _buildMessageItem(DocumentSnapshot document) {
    final data = document.data() as Map<String, dynamic>;
    final isMe = data['senderID'] == _firebaseAuth.currentUser?.uid;
    final message = data['message'] ?? '';
    final isImage = data['isImage'] == true;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: ChatBubble(
        message: message,
        isMe: isMe,
        isImage: isImage,
      ),
    );
  }

  Widget _buildMessageInput() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: MyTextField(
              controller: _messageController,
              hintText: 'Enter message',
              obscureText: false,
            ),
          ),
          IconButton(
            onPressed: sendMessage,
            icon: const Icon(Icons.arrow_upward, size: 30),
          ),
        ],
      ),
    );
  }

  Widget _buildPostImageButton() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: IconButton(
        onPressed: _pickImage,
        icon: const Icon(Icons.image),
        tooltip: 'Send Image',
      ),
    );
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    try {
      File file = File(image.path);
      String fileName = '${DateTime.now().millisecondsSinceEpoch}_${image.name}';
      String filePath = 'images/$fileName';

      await FirebaseStorage.instance.ref(filePath).putFile(file);
      String downloadUrl = await FirebaseStorage.instance.ref(filePath).getDownloadURL();

      await _chatService.sendDirectMessage(
        widget.receiverUserID,
        downloadUrl,
        isImage: true,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload image: $e')),
      );
    }
  print("Current UID: ${FirebaseAuth.instance.currentUser?.uid}");
  print("Receiver UID: ${widget.receiverUserID}");
  
  }
}
