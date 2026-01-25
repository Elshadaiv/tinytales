import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:tinytales/data/baby_data.dart';
import 'package:tinytales/pages/baby_profile_page.dart';
import 'package:tinytales/components/my_button.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tinytales/pages/immunisation_passport_page.dart';
import 'package:tinytales/services/firestore.dart';



class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key, this.CreateBabyProifle, this.toImmunisationPassportPage});
  final Function()? CreateBabyProifle, toImmunisationPassportPage;


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


  bool validDate(String dateString) {
    final reg = RegExp(r'^(\d{2})[\/\.-](\d{2})[\/\.-](\d{4})$');
    final match = reg.firstMatch(dateString);

    if (match == null) {
      return false;
    }
    final day = int.parse(match.group(1)!);
    final month = int.parse(match.group(2)!);
    final year = int.parse(match.group(3)!);

    if (day == null || month == null || year == null) {
      return false;
    }

    if (month < 1 || month > 12 || day < 01 || day > 31) {
      return false;
    }

    final formatted = '$year-${match.group(2)!}-${match.group(1)!}';
    final parsed = DateTime.tryParse(formatted);

    if (parsed == null) {
      return false;
    }

    if (parsed.isAfter(DateTime.now())) {
      return false;
    }
    return true;
  }


  void saveBabyProfile() async
  {

  String name = newBabyNameController.text.trim();
  String gender = newBabyGenderController.text.trim();
  String dob = newBabyDOBController.text.trim();
  String weight = newBabyWeightController.text.trim();
  String height = newBabyHeightController.text.trim();
String hospital = newBabyHospitalController.text.trim();


if (name.isEmpty || gender.isEmpty || dob.isEmpty || weight.isEmpty || height.isEmpty || hospital.isEmpty)
  {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please Enter all fields before uploading')
      ),
    );
    return;
  }

  if (!RegExp(r'^[0-9/.-]+$').hasMatch(dob)) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Date of birth must contain numbers (e.g. 12/05/2024).')),
    );
    return;
  }

  if(RegExp(r'[0-9]').hasMatch(name)) {
    ScaffoldMessenger.of(context).showSnackBar(

      const SnackBar(
          content: Text('Name cannot contain any numbers, try again!')
      ),
    );
    return;
  }


  if(RegExp(r'[0-9]').hasMatch(gender))
  {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Gender cannot contain any numbers, try again!')
      ),
    );
    return;
  }




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
    final docRef = firestore.collection('baby_profiles').doc();
    final baby = babyData(
      babyId: docRef.id,
      name: newBabyNameController.text,
      gender: newBabyGenderController.text,
      dob: newBabyDOBController.text,
      weight: newBabyWeightController.text,
      height: newBabyHeightController.text,
      hospital: newBabyHospitalController.text,
      userId: currentUser.uid,
    );

    try {
      await docRef.set(baby.toMap());
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

    void createBabyProfile() // NEED TO DO ERROR HANDLING + DELETE + UPDATE METHODS FOR BABY
    {
      final BuildContext stateContext = this.context;
      showDialog(
        context: stateContext,
        builder: (BuildContext)
        {
          return StatefulBuilder(
            builder: (context, setDialogState) => AlertDialog(
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
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        children: [
                          Text(
                            "Gender",
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                          Spacer(),

                          GestureDetector(
                            onTap: ()
                            {
                              setDialogState(()
                              {
                                newBabyGenderController.text = "Male";
                              });
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: newBabyGenderController.text == "Male"
                                    ? Colors.purpleAccent
                                    : Colors.grey[300],
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                "Male",
                                style: TextStyle(
                                  color: newBabyGenderController.text == "Male"
                                      ? Colors.white
                                      : Colors.black,
                                ),
                              ),
                            ),
                          ),

                          SizedBox(width: 10),

                          GestureDetector(
                            onTap: ()
                            {
                              setDialogState(()
                              {
                                newBabyGenderController.text = "Female";
                              });
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: newBabyGenderController.text == "Female"
                                    ? Colors.purpleAccent
                                    : Colors.grey[300],
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                "Female",
                                style: TextStyle(
                                  color: newBabyGenderController.text == "Female"
                                      ? Colors.white
                                      : Colors.black,
                                ),
                              ),
                            ),
                          ),
                        ],
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
                          labelText: "Height (Cms)"
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
        },
      );
    }
    void deleteBaby() async
  {
    final snapshot = await FirebaseFirestore.instance
        .collection('baby_profiles')
        .where('userId', isEqualTo: currentUser.uid)
        .get();

    final babies = snapshot.docs;

    if (babies.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Theres no baby profiles to delete. Create one!',
            style: TextStyle(
                color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500
            ),


          ),
          backgroundColor: Colors.purple,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 6,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Delete Baby Profile'
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: babies.length,
              itemBuilder: (context, index) {
                final data = babies[index].data() as Map<String, dynamic>;
                return ListTile(
                  leading: const Icon(Icons.child_care),
                  title: Text(data['name'] ?? 'Unnamed Baby'),

                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      Navigator.pop(context);
                      confirmDeleteBaby(babies[index].id, data ['name']);
                    },
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },

    );
  }

    void confirmDeleteBaby(String babyId, String babyName)
    {
      showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text( 'Confirm Delete',
              style: TextStyle(
                fontWeight: FontWeight.bold),
              ),

            content: Text( 'Are you sure you want to delete $babyName\'s profile?'
            ' All saved information, including the baby immunisations passport will be lost'
            ),
              actions: [
                TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
                ),
                TextButton(
                    onPressed: () async
                {
                  Navigator.pop(context);
                  await FirebaseFirestore.instance
                .collection('baby_profiles')
                .doc(babyId)
                .delete();

                  ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                content: Text('Profile has been deleted',
                style: TextStyle(color: Colors.white),
                ),

                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
                shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
                ),
                );
                },

      child: Text(
    'Delete',
    style: TextStyle(color: Colors.purple),

    ),
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
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ImmunisationPassportPage(
                            babyId: data['babyId'],
                            babyName: data['name'],
                          ),
                        ),
                        );
                      },

                  ),
                );
              },
          );
        },
),
          const SizedBox(
              height: 20
          ),

        ],


      ),
      floatingActionButton: Padding(
          padding: const EdgeInsets.only(bottom: 15.0, right: 10.0),
      child: FloatingActionButton(
          backgroundColor: Colors.red,
          onPressed: deleteBaby,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      ),

      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
    );
  }






  void toImmunisationPassportPage(String babyId, String babyName) /// reminder this callout will be useful when i want to move the create baby methpds ontp its seeprate pages
  {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ImmunisationPassportPage(
          babyId: babyId,
          babyName: babyName,
        ),
  ),
  );
  }
}