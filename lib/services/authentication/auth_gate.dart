import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:islander_chat/pages/main_page.dart';
import 'package:islander_chat/services/authentication/login_or_register.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          //User is logged in
          if (snapshot.hasData) {
            return const MainPage();
          }
          //User is not logged in
          else {
            return const LoginOrRegister();
          }
        },
      ),
    );
  }
}
