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
    if(_messageController.text.isNotEmpty){
      await _chatService.sendMessage(
        widget.receiverUserID, 
        _messageController.text,
        isImage: false,
        );
      
      //Clear the text controller after message is sent
      _messageController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.receiverUserEmail)),
      body: Column(
        children: [
        //Messages
        Expanded(
          child: _buildMessageList(),
          ),

        //User inputs
        _buildMessageInput(),
        _buildPostImageButton(),
        ],
        ),
      );   
  }

  //Build message list
  Widget _buildMessageList() {
    return StreamBuilder(
      stream: _chatService.getMessages(
        widget.receiverUserID, _firebaseAuth.currentUser!.uid),
      builder: (context, snapshot) {
        if(snapshot.hasError){
          return Text('Error${snapshot.error}');
        }

        if(snapshot.connectionState == ConnectionState.waiting){
          return const Text('loading...');
        }

        return ListView(
          children: snapshot.data!.docs
          .map((document) => _buildMessageItem(document))
          .toList(),
        );
      },
      );
  }

  //Build message item
  Widget _buildMessageItem(DocumentSnapshot document) {
    Map<String, dynamic>data = document.data() as Map<String, dynamic>;
    return Container(
      child: Column(
        crossAxisAlignment: (data['senderId'] == _firebaseAuth.currentUser!.uid) 
        ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          _buildProfilePicture(data['senderEmail']),
          const SizedBox(height: 5),
          ChatBubble(message: data['message']),
          const SizedBox(height: 5),
        ],
        ),
      );
  }

  //Build message input
  Widget _buildMessageInput() {
    return Row(
      children: [
        //TextField
        Expanded(
          child: MyTextField(
            controller: _messageController,
            hintText: 'Enter message',
            obscureText: false,
          ),
        ),

        //Send Button
        IconButton(
          onPressed: sendMessage, 
          icon: const Icon(
            Icons.arrow_upward, 
            size: 40,
            ),
            ),
      ],
      );
  }

//Build image post button
Widget _buildPostImageButton() {
  return IconButton(
    onPressed: _pickImage, 
    icon: const Icon(Icons.image),
    );
}

//pick image from gallery
void _pickImage() async {
  final ImagePicker _picker = ImagePicker();
  final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

  if(image != null){
    //Upload image to Firebase Storage
    String imageUrl = await _chatService.uploadImage(image.path);
    
    //Send image message
    await _chatService.sendMessage(
      widget.receiverUserID, 
      imageUrl,
      isImage: true,
      );
  }
  
  
}

//Build profile picture
Widget _buildProfilePicture(String email) {
  return Align(
    alignment: Alignment.centerLeft,
    child: CircleAvatar(
      backgroundColor: Colors.lightGreen,
      child: Text(email[0]),
      radius: 20,
      ),
    );
  }
}

