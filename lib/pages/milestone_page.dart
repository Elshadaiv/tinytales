import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class milestone_page extends StatelessWidget {
  const milestone_page({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Welcome back! ${FirebaseAuth.instance.currentUser?.email ?? 'Unknown'}',
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }
}
