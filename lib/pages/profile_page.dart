import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:tinytales/pages/baby_profile_page.dart';
import 'package:tinytales/components/my_button.dart';

import 'package:tinytales/services/firestore.dart';



class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key, this.CreateBabyProifle});
  final Function()? CreateBabyProifle;


  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {


  final newBabyNameController = TextEditingController();
  final newBabyDOBController = TextEditingController();
  final newBabyWeightController = TextEditingController();
  final newBabyHeightController = TextEditingController();
  final newBabyGenderController = TextEditingController();
  final newBabyHospitalController = TextEditingController();

  final currentUser = FirebaseAuth.instance.currentUser!;
  void save()
  {
    Navigator.pop(context);
  }

  void cancel()
  {
    Navigator.pop(context);

  }

  void createBabyProfile()
  {
    final BuildContext stateContext = this.context;
    showDialog(
    context: stateContext,
    builder: (BuildContext) => AlertDialog (
      title: Text("Baby Profile"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: newBabyNameController,
                decoration: const InputDecoration(
                    labelText: "Name"
                ),
              ),
              TextField(
                controller: newBabyDOBController,
                decoration: const InputDecoration(
                    labelText: "Date of Birth"
                ),
              ),
              TextField(
                controller: newBabyWeightController,
                decoration: const InputDecoration(
                    labelText: "Weight"
                ),
              ),
              TextField(
                controller: newBabyHeightController,
                decoration: const InputDecoration(
                    labelText: "Height"
                ),
              ),
              TextField(
                controller: newBabyGenderController,
                decoration: const InputDecoration(
                    labelText: "Gender"
                ),
              ),
              TextField(
                controller: newBabyHospitalController,
                decoration: const InputDecoration(
                    labelText: "Hospital"
                ),
              ),
            ],
          ),
        ),
      actions: [
        MaterialButton(
          onPressed: cancel,
          child: Text("Cancel"),
        ),
        MaterialButton(
          onPressed: save,
          child: Text("Upload"),
        ),
      ],
    ),
    );
  }


  @override
  Widget build(BuildContext context) {

    final FirestoreService firestoreService = FirestoreService();

    return Scaffold(
      backgroundColor: Colors.grey[300],
      appBar: AppBar(
        backgroundColor: Colors.grey[300],
      ),
      body: ListView(
        children: [
          const SizedBox(
            height: 20
          ),
          Icon(
              Icons.person,
                  size: 72,
          ),
          const SizedBox(
              height: 20
          ),
          Text(
            currentUser.email!,
            textAlign: TextAlign.center,
          ),
          const SizedBox(
              height: 20
          ),
          MyButton(
            text: 'Create Baby Profile',
            onTap: createBabyProfile,
          ),
        ],
      ),
    );
  }
}