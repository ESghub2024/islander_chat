import 'package:flutter/material.dart';
import 'package:islander_chat/components/my_buttons.dart';
import 'package:islander_chat/components/my_text_field.dart';
import 'package:islander_chat/services/authentication/auth_service.dart';
import 'package:provider/provider.dart';

class LoginPage extends StatefulWidget {
  final void Function()? onTap;
  
  const LoginPage({
    super.key,
    required this.onTap,
    });

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  //Controllers
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  //Login
  void signIn() async{
    //Authentication service
    final authService = Provider.of<AuthService>(context, listen: false);

    try{
      await authService.signInWithEmailandPassword(
        emailController.text, 
        passwordController.text,
        );
    } catch (e){
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString(), ),),);
    }
  
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 50.0),
          child: Column(
            children: [
              const SizedBox(height: 40.0),
              //TAMUCC Logo
              Image.asset('images/Islander.png', scale: 2),
              
              //Welcome to Islanders Chat
              const Text(
                "Welcome to Islanders Chat Application!",
                style: TextStyle(
                  fontSize: 10,
                ),
              ),
              const SizedBox(height: 20.0),
          
              //Email
              MyTextField(
                controller: emailController, 
                hintText: "Student Email", 
                obscureText: false,
                ),
              const SizedBox(height: 20.0),
          
              //Password
              MyTextField(
                controller: passwordController, 
                hintText: "Password", 
                obscureText: true,
                ),
              const SizedBox(height: 20.0),

              //Sigin
              MyButtons(onTap: signIn, text: "Login"),
              const SizedBox(height: 20.0),
          
              //Register
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('New user.'),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: widget.onTap,
                    child: const Text('Register.',
                    style: TextStyle(
                      fontStyle: FontStyle.normal,
                      backgroundColor: Colors.yellow,
                    ),
                    ),
                  ),
                ],
                )
            ],),
        ),
      )
    );
  }
}