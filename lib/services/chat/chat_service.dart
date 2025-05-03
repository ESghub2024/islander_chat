import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Creates or fetches a conversation ID for a direct message.
  Future<String> getOrCreateDirectConversationId(String otherUserId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null || otherUserId.isEmpty) {
      throw Exception("Invalid users for conversation.");
    }

    final ids = [currentUser.uid, otherUserId]..sort();
    final conversationId = ids.join("_");

    final docRef = _firestore.collection('direct_messages').doc(conversationId);
    final doc = await docRef.get();

    if (!doc.exists) {
      await docRef.set({
        'participants': ids,
        'createdAt': FieldValue.serverTimestamp(),
      });
      print("Created conversation: $conversationId with participants $ids");
    } else {
      print("Existing conversation: $conversationId");
    }

    return conversationId;
  }

  /// Sends a message (text or image) to another user.
  Future<void> sendDirectMessage(String receiverId, String message, {bool isImage = false}) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null || message.trim().isEmpty || receiverId.isEmpty) return;

    final conversationId = await getOrCreateDirectConversationId(receiverId);

    await _firestore
        .collection('direct_messages')
        .doc(conversationId)
        .collection('messages')
        .add({
      'senderID': currentUser.uid,
      'senderEmail': currentUser.email ?? '',
      'receiverId': receiverId,
      'message': message.trim(),
      'timestamp': Timestamp.now(),
      'isImage': isImage,
    });

    print("Sent ${isImage ? 'image' : 'text'} message to $receiverId");
  }

  /// Streams messages between the current user and another user.
  Stream<QuerySnapshot> getDirectMessages(String userId, String otherUserId) {
    final ids = [userId, otherUserId]..sort();
    final conversationId = ids.join("_");

    return _firestore
        .collection('direct_messages')
        .doc(conversationId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  /// Sends a message in a group chatroom.
  Future<void> sendGroupMessage(String groupId, String chatroomId, String message) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null || message.trim().isEmpty) return;

    await _firestore
        .collection('groups')
        .doc(groupId)
        .collection('chatrooms')
        .doc(chatroomId)
        .collection('messages')
        .add({
      'senderId': currentUser.uid,
      'senderEmail': currentUser.email ?? '',
      'text': message.trim(),
      'timestamp': Timestamp.now(),
    });
  }

  /// Streams messages from a group chatroom.
  Stream<QuerySnapshot> getGroupMessages(String groupId, String chatroomId) {
    return _firestore
        .collection('groups')
        .doc(groupId)
        .collection('chatrooms')
        .doc(chatroomId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }
}
