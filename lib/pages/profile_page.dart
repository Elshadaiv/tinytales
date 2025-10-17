import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:tinytales/data/baby_data.dart';
import 'package:tinytales/pages/baby_profile_page.dart';
import 'package:tinytales/components/my_button.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tinytales/services/firestore.dart';



class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key, this.CreateBabyProifle});
  final Function()? CreateBabyProifle;


  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {


  final newBabyNameController = TextEditingController();
  final newBabyGenderController = TextEditingController();
  final newBabyDOBController = TextEditingController();
  final newBabyWeightController = TextEditingController();
  final newBabyHeightController = TextEditingController();
  final newBabyHospitalController = TextEditingController();

  final currentUser = FirebaseAuth.instance.currentUser!;


  void saveBabyProfile() async
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

    final firestore = FirebaseFirestore.instance;
    final baby = babyData(
      name: newBabyNameController.text,
      gender: newBabyGenderController.text,
      dob: newBabyDOBController.text,
      weight: newBabyWeightController.text,
      height: newBabyHeightController.text,
      hospital: newBabyHospitalController.text,
      userId: currentUser.uid,
    );

    try {
      await firestore.collection('baby_profiles').add(baby.toMap());
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(
              'Your baby has sucessfully been added to your profile.'))
      );

      newBabyNameController.clear();
      newBabyGenderController.clear();
      newBabyDOBController.clear();
      newBabyWeightController.clear();
      newBabyHeightController.clear();
      newBabyHospitalController.clear();
    } catch (e) {
      print('Error');
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create baby profile.'))
      );
    }
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
                controller: newBabyGenderController,
                decoration: const InputDecoration(
                    labelText: "Gender"
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
          onPressed: saveBabyProfile,
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
      body: ListView.(
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