import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class InsightsPage extends StatefulWidget {
  const InsightsPage({super.key});

  @override
  State<InsightsPage> createState() => _InsightsPageState();
}

class _InsightsPageState extends State<InsightsPage> {
  @override
  Widget build(BuildContext context) {

    final user = FirebaseAuth.instance.currentUser;

    return  Scaffold(
        backgroundColor: Colors.grey[300],
        appBar: AppBar(
          backgroundColor: Colors.grey[300],
        ),
       body:  Center(
          child: Text('Insight Page ' + (FirebaseAuth.instance.currentUser?.email ?? 'Unknown')),
        ),
    );
  }
}
