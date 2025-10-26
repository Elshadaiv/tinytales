import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:tinytales/data/baby_data.dart';


class immunisationPassportPage extends StatefulWidget {
  const immunisationPassportPage({super.key, required this.babyId});
  final String babyId;
  @override
  State<immunisationPassportPage> createState() => _immunisationPassportPageState();
}

class _immunisationPassportPageState extends State<immunisationPassportPage> {

  List<Immunisation> vaccines =
  [
    Immunisation(name: '6-In-1 Vaccine'),
    Immunisation(name: 'MMR'),
    Immunisation(name: 'Polio'),
    Immunisation(name: 'MenB'),

  ];

  final FirebaseFirestore firestore = FirebaseFirestore.instance;


  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.grey[300],
      appBar: AppBar(
        backgroundColor: Colors.grey[300],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
                itemCount: vaccines.length,
                itemBuilder: (context, index) {
                  final vaccine = vaccines[index];
                  return ListTile(
                    title: Text(vaccine.name),
                    leading: Checkbox(value: vaccine.isGiven,
                        onChanged: (val) {
                          setState(() {
                            vaccine.isGiven = val!;
                          });
                        }
                    ),

                    trailing: SizedBox(
                      width: 120,
                      child: TextField(
                        controller: TextEditingController(
                            text: vaccine.dateGiven),
                        decoration: InputDecoration(
                          labelText: 'Date Taken',
                        ),
                        onChanged: (val) {
                          vaccine.dateGiven = val;
                        },
                      ),
                    ),
                  );
                }
            ),
          ),

          ElevatedButton(
            onPressed: () async
            {
              for (var vaccine in vaccines) {
                await firestore
                    .collection('baby_profiles')
                    .doc(widget.babyId)
                    .collection('immunisations')
                    .doc(vaccine.name)
                    .set(vaccine.toMap());
              }

              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text('Ssaved'))
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
  }