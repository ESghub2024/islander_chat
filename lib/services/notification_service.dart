import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationItem {
  final String title;
  final String subtitle;
  final DateTime timestamp;
  NotificationItem({
    required this.title,
    required this.subtitle,
    required this.timestamp,
  });
}

class NotificationService extends ChangeNotifier {
  final List<NotificationItem> _items = [];
  List<NotificationItem> get items => List.unmodifiable(_items);
  int get unreadCount => _items.length;

  NotificationService() {
    _init();
  }

  void _init() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    FirebaseFirestore.instance
        .collection('notifications')
        .where('recipientId', isEqualTo: uid)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen((snap) {
      _items
        ..clear()
        ..addAll(snap.docs.map((doc) {
          final data = doc.data();
          return NotificationItem(
            title: data['title'] ?? '',
            subtitle: data['subtitle'] ?? '',
            timestamp: (data['timestamp'] as Timestamp).toDate(),
          );
        }));
      notifyListeners();
    });
  }
}
