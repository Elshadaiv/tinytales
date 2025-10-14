import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:tinytales/pages/home_page.dart';
import 'package:tinytales/pages/login_or_register_page.dart';
import 'package:tinytales/pages/login_page.dart';

class AuthPage extends StatelessWidget {
  const AuthPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot)
          {
            if(snapshot.hasData)
              {
                return HomePage();
              }

            //not logged in
            else
              {
                return LoginOrRegisterPage();
              }

          }

      ),
    );
  }
}
