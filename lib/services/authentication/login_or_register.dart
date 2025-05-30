import 'package:flutter/material.dart';
import 'package:islander_chat/pages/login_page.dart';
import 'package:islander_chat/pages/register_page.dart';

class LoginOrRegister extends StatefulWidget {
  const LoginOrRegister({super.key});

  @override
  State<LoginOrRegister> createState() => _LoginOrRegisterState();
}

class _LoginOrRegisterState extends State<LoginOrRegister> {
  //Show login_page
  bool showLoginPage = true;

  //Toggle between login and register
  void togglePages() {
    setState(() {
      showLoginPage = !showLoginPage;
    });
  }
  @override
  Widget build(BuildContext context) {
    if(showLoginPage){
      return LoginPage(onTap: togglePages);
    }
    else
    {
      return RegisterPage(onTap: togglePages);
    }
  }
}