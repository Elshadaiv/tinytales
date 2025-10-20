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
      Navigator.pop(context);
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

          const SizedBox(
              height: 20
          ),

    StreamBuilder<QuerySnapshot>(
  stream: FirebaseFirestore.instance.
        collection('baby_profiles')
      .where('userId',isEqualTo: currentUser.uid)
      .snapshots(),

      builder: (context, snapshot)
        {
          if(snapshot.connectionState == ConnectionState.waiting)
            {
              return Center(child: CircularProgressIndicator());
            }

          if(!snapshot.hasData || snapshot.data!.docs.isEmpty)
            {
              return Center(child: Text('Theres not profiles created yet. Get started!'));
            }

          final babies = snapshot.data!.docs;

          return ListView.builder(
            physics: NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: babies.length,
              itemBuilder: (context, index)
              {
                final data = babies[index].data() as Map<String, dynamic>;
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  color: Colors.white,
                  child: ListTile(
                    leading: Icon(
                      Icons.child_care,
                      color:Colors.black ,
                    ),
                    title: Text(data['name'] ?? 'Baby is unkown',
                    ),
                    subtitle: Text(
                        'DOB: ${data['dob'] ?? 'N/A'}\nGender: ${data['gender'] ?? 'N/A'}',
                    ),
                  ),
                );
              },
          );
        },
),
          const SizedBox(
              height: 20
          ),

          MyButton(
            text: 'Immunisation Passport ',
            onTap: createBabyProfile,
          ),


        ],
      ),
    );
  }
}