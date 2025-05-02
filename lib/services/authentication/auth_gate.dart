import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:islander_chat/pages/main_page.dart';
import 'package:islander_chat/services/authentication/login_or_register.dart';

/// Decides whether to show the signed-in UI (MainPage)
/// or the login/register flow (LoginOrRegister).
class AuthGate extends StatelessWidget {
  const AuthGate({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // While checking auth state, show a loader
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          // If we have a user, go to your main screen
          if (snapshot.hasData) {
            return const MainPage();
          }
          // Otherwise, show login/register
          return const LoginOrRegister();
        },
      ),
    );
  }
}
