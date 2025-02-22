import 'package:flutter/material.dart';
import 'package:islander_chat/components/my_buttons.dart';
import 'package:islander_chat/components/my_text_field.dart';
import 'package:islander_chat/services/authentication/auth_service.dart';
import 'package:provider/provider.dart';

class RegisterPage extends StatefulWidget {
  final void Function()? onTap;

  const RegisterPage({
    super.key,
    required this.onTap,
    });

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  //Controllers
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  //Sign up member
  void signUp() async {
    if(passwordController.text != confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Passwords do not match"),
          ),
      );
      return;
    }
    
    //Get authentication service
    final authService = Provider.of<AuthService>(context, listen: false);

    try{
      await authService.signUpWithEmailandPassword(
        emailController.text, 
        passwordController.text,
        );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()),),);
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
              //Create an Account
              const Text(
                "Create a New Account.",
                style: TextStyle(
                  fontSize: 20, 
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

              //Confirm
              MyTextField(
                controller: confirmPasswordController, 
                hintText: "Confirm Password", 
                obscureText: true,
                ),
              const SizedBox(height: 20.0),

              //Sign Up
              MyButtons(onTap: signUp, text: "Sign Up"),
              const SizedBox(height: 20.0),
          
              //Register
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Existing Member.'),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: widget.onTap,
                    child: const Text('Login',
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