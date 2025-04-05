import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfilePage extends StatefulWidget {
  final String name;
  final String email;
  final String profilePicture;
  const UserProfilePage({
    super.key,
    required this.name,
    required this.email,
    required this.profilePicture,
    });

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
  }
  
  class _UserProfilePageState extends State<UserProfilePage> {
  
    @override
    Widget build(BuildContext context) {
      return Scaffold(
      appBar: AppBar(
        title: const Text('User Profile'),
        backgroundColor: Colors.lightGreen,
        ),
        body: Column(
          children: [
          ],
          )
      );
  }

}









