/*
Name: Team WAVE, iChat
Class: COSC 4354.001 Spring 2025
Instructor: Dr. Mamta Yadav
Program description: A cross-platform application for Text Chats,
programmed using Flutter with Visual Studio Code.
*/

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:islander_chat/firebase_options.dart';
import 'package:islander_chat/pages/direct_messages.dart';
import 'package:islander_chat/pages/group_detail_page.dart';
import 'package:islander_chat/pages/login_page.dart';
import 'package:islander_chat/pages/register_page.dart';
import 'package:islander_chat/pages/main_page.dart';
import 'package:islander_chat/pages/search_page.dart';
import 'package:islander_chat/services/authentication/auth_gate.dart';
import 'package:islander_chat/services/authentication/auth_service.dart';
import 'package:islander_chat/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => NotificationService()),
      ],
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
        '/login': (context) => LoginPage(
              onTap: () {
                Navigator.pushNamed(context, '/register');
              },
            ),
        '/register': (context) => RegisterPage(
              onTap: () {
                Navigator.pop(context);
              },
            ),
        '/main': (context) => const MainPage(),
        '/search': (_) => const SearchPage(),
        '/group_detail': (context) {
          final args =
              ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return GroupDetailPage(
            groupId: args['groupId'],
            groupName: args['groupName'],
          );
        },
        '/inbox': (context) => const DirectMessages(),
      },
    );
  }
}
