import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:tinytales/pages/main/home_page.dart';
import 'package:tinytales/pages/authentication/login_or_register_page.dart';
import 'package:tinytales/pages/authentication/login_page.dart';
import 'package:tinytales/pages/main/profile_page.dart';


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
              final userId = snapshot.data!.uid;

              return FutureBuilder(
                future: FirebaseFirestore.instance
                    .collection("baby_profiles")
                    .where("userId", isEqualTo: userId)
                    .limit(1)
                    .get(),
                builder: (context, babySnapshot)
                {
                  if (babySnapshot.connectionState == ConnectionState.waiting)
                  {
                    return Center(
                      child: CircularProgressIndicator(color: Colors.purple),
                    );
                  }

                  if (babySnapshot.hasData && babySnapshot.data!.docs.isEmpty)
                  {
                    return ProfilePage();
                  }

                  return HomePage();
                },
              );
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
