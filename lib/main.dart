/*
Name: Team WAVE, IChat 
Class: COSC 4354.001 Spring 2025
Instructor: Dr. Mamta Yadav
Program description: A cross-platform application for Text Chats, 
it is programmed using Flutter with Visual Studio Code.
*/

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:islander_chat/firebase_options.dart';
import 'package:islander_chat/pages/direct_messages.dart';
import 'package:islander_chat/pages/group_detail_page.dart';
import 'package:islander_chat/pages/login_page.dart';
import 'package:islander_chat/pages/main_page.dart';
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

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'iChat',
      debugShowCheckedModeBanner: false,
      home: const AuthGate(),
      routes: {
        '/main': (context) => const MainPage(),
        '/login': (context) => LoginPage(onTap: () {}),
        '/group_detail': (context) {
          final args =
              ModalRoute.of(context)!.settings.arguments
                  as Map<String, dynamic>;
          return GroupDetailPage(
            groupId: args['groupId'],
            groupName: args['groupName'],
          );
        },
        '/inbox': (context) => DirectMessages(),
      },
    );
  }
}
