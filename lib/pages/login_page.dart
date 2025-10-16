import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:tinytales/components/my_button.dart';
import 'package:tinytales/components/my_textfield.dart';

class LoginPage extends StatefulWidget {
  final Function()? onTap;
  const LoginPage({super.key, required this.onTap});

  @override
  State<LoginPage> createState() => LoginPageState();
}

class LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  void signIn() async
  {

    final BuildContext stateContext = this.context;
    showDialog(
      context: stateContext,
      builder: (BuildContext dialogContext)
      {
        return const Center(
          child:  CircularProgressIndicator(),
        );
      },
    );



    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text,
        password: passwordController.text,
      );
      Navigator.pop(stateContext);
    } on FirebaseAuthException catch (e) {
      Navigator.pop(stateContext);
      showErrorMessage(e.code);
      }
    }

  void showErrorMessage(String message) {
    final BuildContext stateContext = this.context;

    showDialog(
      context: stateContext,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.amber,
          title: Center(
            child: Text(
              message,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 50),

              const Icon(
                Icons.lock,
                size: 100,
              ),

              const SizedBox(height: 50),

              const Text(
                'Welcome',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                ),
              ),

              const SizedBox(height: 25),

              // EMAIL TextField
              MyTextField(
                controller: emailController,
                hintText: 'Email',
                obscureText: false,
                ),

              const SizedBox(height: 25),

              //PASSWORD TEXT FIELD
              MyTextField(
                controller: passwordController,
                hintText: 'Password',
                obscureText: true,

              ),
              const SizedBox(height: 25),

              MyButton(
                text: 'Sign in',
              onTap: signIn,
              ),

              const SizedBox(height: 25),

              Row(
              mainAxisAlignment: MainAxisAlignment.center,
                children: [

                  Text('A New Beginging?',
                    style: TextStyle(color: Colors.black),
                  ),

                  const SizedBox(width: 4,),
                  GestureDetector(
                    onTap: widget.onTap,
                    child: const Text(
                      'Register Here',
                          style: TextStyle(
                            color:  Colors.blueAccent, fontWeight:FontWeight.bold
                          ),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
      )
    );
  }
}
