import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:tinytales/data/baby_data.dart';


class ImmunisationPassportPage extends StatefulWidget {
  const ImmunisationPassportPage({super.key, required this.babyId,required this.babyName});
  final String babyId;
  final String babyName;
  @override
  State<ImmunisationPassportPage> createState() => _ImmunisationPassportPageState();
}

class _ImmunisationPassportPageState extends State<ImmunisationPassportPage> {

  List<Immunisation> vaccines =
  [
    Immunisation(name: '6-In-1 Vaccine'),
    Immunisation(name: 'MMR'),
    Immunisation(name: 'Polio'),
    Immunisation(name: 'MenB'),

  ];

  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  String? babyDob;


  @override
  void initState() {
    super.initState();
    fetchBabyDob();
  }


  Future<void> fetchBabyDob() async
  {
    final doc = await firestore.collection('baby_profiles').doc(widget.babyId).get();
    if(doc.exists)
      {
        setState(() {
          babyDob = doc['dob'];
        });
      }
  }


  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.grey[300],
      appBar: AppBar(
        backgroundColor: Colors.grey[300],
        title: Text(
          "${widget.babyName}'s Immnisation Passport",
          style: const TextStyle(
            fontWeight: FontWeight.bold
          ),
        ),
        centerTitle: true,
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

          StreamBuilder<QuerySnapshot>(
            stream: firestore
                .collection('baby_profiles')
                .doc(widget.babyId)
                .collection('immunisations')
                .snapshots(),
            builder: (context, snapshot)
            {
              if (snapshot.connectionState == ConnectionState.waiting)
              {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'There\'s no immunisation records yet.',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                );
              }

              final immunisations = snapshot.data!.docs;

              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Vaccine Name')),
                    DataColumn(label: Text('Date Given')),
                    DataColumn(label: Text('Status')),
                  ],
                  rows: immunisations.map((doc)
                  {
                    final data = doc.data() as Map<String, dynamic>;
                    return DataRow(
                      cells: [
                        DataCell(Text(data['name'] ?? 'Unknown')),
                        DataCell(Text(data['dateGiven'] ?? 'N/A')),
                        DataCell(
                          Icon(
                            (data['isGiven'] ?? false)
                                ? Icons.check_circle
                                : Icons.cancel,
                            color: (data['isGiven'] ?? false)
                                ? Colors.green
                                : Colors.red,
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              );
            },
          ),






          Padding(
            padding: const EdgeInsets.only(bottom: 40.0),
            child: ElevatedButton(
              onPressed: () async
              { if(babyDob == null)
                {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                    content: const Text('Baby Date of Birth was not found',
                      style: TextStyle(
                          color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500
                      ),
                    ),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 6,

                    ),
                  );
                  return ;
                }

                bool hasError = false;
                DateTime? dobDate;

              try
              {
                final parts = babyDob!.split(RegExp(r'[\/\.-]'));
                dobDate = DateTime(
                  int.parse(parts[2]),
                  int.parse(parts[1]),
                  int.parse(parts[0]),
                );
              } catch (e)
              {
                dobDate = null;
              }

              for (var vaccine in vaccines) {
                final dateText = vaccine.dateGiven.trim();


                if (dateText.isEmpty) {
                 continue;
                }

                try {
                  final parts = dateText.split(RegExp(r'[\/\.-]'));
                  final enteredDate = DateTime(
                    int.parse(parts[2]),
                    int.parse(parts[1]),
                    int.parse(parts[0]),
                  );

                  if (dobDate != null && enteredDate.isBefore(dobDate)) {
                    hasError = true;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Sorry! This date is BEFORE your child birth!',
                          style: TextStyle(
                            color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500
                          ),

                        ),
                        backgroundColor: Colors.red,
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
                } catch (e) {
                  hasError = true;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content:  Text('Incorrect date format',
                      style: TextStyle(
                        color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500
                      ),


                    ),
                      backgroundColor: Colors.red,
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
              }

                if (hasError) return;


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
                        content: const Text('Ssaved',
                            style: TextStyle(
                                color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500
                            ),


                        ),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 6,
                    ),

                );
              },
              child: const Text('Save'),
            ),
          ),
        ],
    ),
      );

  }
  }