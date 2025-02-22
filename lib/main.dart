/*
Name: Team WAVE, IChat 
Class: COSC 4354.001 Spring 2025
Instructor: Dr. Mamta Yadav
Program description: A mobile application for Text Chats, 
it is programmed using Flutter with Visual Studio Code.
*/

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:islander_chat/firebase_options.dart';
import 'package:islander_chat/services/authentication/auth_gate.dart';
import 'package:islander_chat/services/authentication/auth_service.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(
    ChangeNotifierProvider(
      create: (context) => AuthService(),
      child: const MyApp(),
      ),
    );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Flutter Demo',
      home: AuthGate(),
    );
  }
}


