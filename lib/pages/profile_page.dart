import 'package:flutter/material.dart';
import 'package:tinytales/pages/baby_profile_page.dart';
import 'package:tinytales/services/firestore.dart';



class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key,});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  Widget build(BuildContext context) {

    final FirestoreService firestoreService = FirestoreService();

    return Scaffold(
      backgroundColor: Colors.grey[300],
      appBar: AppBar(
        backgroundColor: Colors.grey[300],
      ),
      body: ListView(
        children: [],
      ),
    );

  }
}