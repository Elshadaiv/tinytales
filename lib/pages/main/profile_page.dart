import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:tinytales/data/baby_data.dart';
import 'package:tinytales/pages/baby/baby_profile_page.dart';
import 'package:tinytales/components/my_button.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tinytales/pages/immunisation/immunisation_passport_page.dart';
import 'package:tinytales/pages/database/firestore.dart';
import 'dart:io';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';


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

    String selectedHospital = "";
    bool showOtherHospitalField = false;

    final List<String> irishHospitals = [
      "The Rotunda Hospital",
      "The Coombe Hospital",
      "National Maternity Hospital",
      "Cork University Maternity Hospital",
      "University Maternity Hospital Limerick",
      "University Hospital Galway",
      "Mayo University Hospital",
      "University Hospital Kerry",
      "Letterkenny University Hospital",
      "Sligo University Hospital",
      "Wexford General Hospital",
      "Portiuncula University Hospital",
      "Midland Regional Hospital Portlaoise",
      "Our Lady of Lourdes Hospital Drogheda",
      "Cavan General Hospital",
      "Other",
    ];

  final currentUser = FirebaseAuth.instance.currentUser!;

    final ImagePicker picker = ImagePicker();
    String? uploadingBabyId;

  bool validDate(String dateString) {
    final reg = RegExp(r'^(\d{2})[\/\.-](\d{2})[\/\.-](\d{4})$');
    final match = reg.firstMatch(dateString);

    if (match == null) {
      return false;
    }
    final day = int.tryParse(match.group(1)!);
    final month = int.tryParse(match.group(2)!);
    final year = int.tryParse(match.group(3)!);

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
      SnackBar(content: Text('Please Enter all fields before uploading')
      ),
    );
    return;
  }

  if (!validDate(dob)) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Date of birth must contain numbers (e.g. 12/05/2024).')),
    );
    return;
  }

  final weightValue = double.tryParse(weight);
  final heightValue = double.tryParse(height);
  if (weightValue == null)
  {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Weight must be a number."),
      ),
    );
    return;
  }

  if (heightValue == null)
  {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Height must be a number."),
      ),
    );
    return;
  }

  if(RegExp(r'[0-9]').hasMatch(name)) {
    ScaffoldMessenger.of(context).showSnackBar(

       SnackBar(
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
      selectedHospital = "";
      showOtherHospitalField = false;

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
                      decoration: InputDecoration(
                          labelText: "Date of Birth"
                      ),
                    ),
                    TextField(
                      controller: newBabyWeightController,
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                          labelText: "Weight"
                      ),
                    ),
                    TextField(
                      controller: newBabyHeightController,
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                          labelText: "Height (Cms)"
                      ),
                    ),

                    SizedBox(height: 12),

                    DropdownButtonFormField<String>(
                      value: selectedHospital.isEmpty ? null : selectedHospital,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: "Hospital",
                      ),
                      items: irishHospitals.map((hospital)
                      {
                        return DropdownMenuItem<String>(
                          value: hospital, child: Text(
                          hospital,
                          overflow: TextOverflow.ellipsis,
                        ),
                        );
                      }).toList(),
                      onChanged: (value)
                      {
                        if (value == null)
                        {
                          return;
                        }
                        setDialogState(()
                        {
                          selectedHospital = value;
                          showOtherHospitalField = value == "Other";
                          if (value != "Other")
                          {
                            newBabyHospitalController.text = value;
                          }
                          else
                          {
                            newBabyHospitalController.clear();
                          }
                        });
                      },
                    ),

                    if (showOtherHospitalField)
                      TextField(
                        controller: newBabyHospitalController,
                        decoration: InputDecoration(
                          labelText: "Enter hospital name",
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


    Future<void> _uploadBabyImage(String babyId) async
    {
      try
      {
        if (uploadingBabyId == babyId)
        {
          return;
        }

        setState(()
        {
          uploadingBabyId = babyId;
        });

        final XFile? pickedFile = await picker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 25,
          maxWidth: 300,
          maxHeight: 300,
        );

        if (pickedFile == null)
        {
          setState(()
          {
            uploadingBabyId = null;
          });
          return;
        }

        final file = File(pickedFile.path);
        final bytes = await file.readAsBytes();
        final base64String = base64Encode(bytes);

        await FirebaseFirestore.instance
            .collection("baby_profiles")
            .doc(babyId)
            .update({
          "imageBase64": base64String,
        });

        setState(()
        {
          uploadingBabyId = null;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Baby image updated"),
          ),
        );
      }
      catch (e)
      {
        setState(()
        {
          uploadingBabyId = null;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to update baby image"),
          ),
        );
      }
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
                final babyId = babies[index].id;
                final imageBase64 = (data["imageBase64"] ?? "").toString();
                final isUploading = uploadingBabyId == babyId;

                return GestureDetector(
                  onTap: ()
                  {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ImmunisationPassportPage(
                          babyId: data['babyId'], babyName: data['name'],
                        ),
                      ),
                    );
                  },
                  child: Container(
                    margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: ()
                          {
                            _uploadBabyImage(babyId);
                          },
                          child: CircleAvatar(
                            radius: 34,
                            backgroundColor: Colors.purple.shade100,
                            backgroundImage: imageBase64.isNotEmpty
                                ? MemoryImage(base64Decode(imageBase64))
                                : null,
                            child: isUploading
                                ? SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.purple,
                              ),
                            )
                                : imageBase64.isEmpty
                                ? Icon(Icons.add_a_photo, color: Colors.purple)
                                : null,
                          ),
                        ),

                        SizedBox(width: 16),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                data['name'] ?? 'Unknown Baby',
                                style: TextStyle(
                                  fontSize: 17, fontWeight: FontWeight.w800,
                                ),
                              ),
                              SizedBox(height: 6),
                              Text(
                                "DOB: ${data['dob'] ?? 'N/A'}",
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.black54,
                                ),
                              ),
                              SizedBox(height: 3),
                              Text(
                                "Gender: ${data['gender'] ?? 'N/A'}",
                                style: TextStyle(fontSize: 13,
                                  color: Colors.black54,
                                ),
                              ),
                              SizedBox(height: 3),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 16, color: Colors.grey,
                        ),
                      ],
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
}///////