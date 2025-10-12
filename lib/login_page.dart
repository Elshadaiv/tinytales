import 'package:flutter/material.dart';




import 'package:flutter/material.dart';
import 'package:tinytales/components/my_button.dart';
import 'package:tinytales/components/my_textfield.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});
void homePage()
{

}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      body: SafeArea(
        child: Center(
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

              // Username TextField
              MyTextField(
                hintText: 'Email',
                obscureText: false,
                ),

              const SizedBox(height: 25),

              //PASSWORD TEXT FIELD
              MyTextField(
                hintText: 'Password',
                obscureText: true,

              ),
              const SizedBox(height: 25),

              MyButton(
              onTap: homePage,
              ),

              const SizedBox(height: 25),

              Row(
              mainAxisAlignment: MainAxisAlignment.center,
                children: [

                  Text('A New Beginging?',
                    style: TextStyle(color: Colors.black),
                  ),

                  const SizedBox(width: 4,),
                  const Text(
                    'Register Here',
                        style: TextStyle(
                          color:  Colors.blueAccent, fontWeight:FontWeight.bold
                        ),
                  ),
                ],

              )
            ],
          ),
        ),
      ),
    );
  }
}
