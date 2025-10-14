import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:tinytales/pages/auth_page.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
 await  Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const TinyTalesApp());
}

class TinyTalesApp extends StatelessWidget {
  const TinyTalesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return  MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.purple
      ),
      home: const AuthPage(),
    );
  }
}



