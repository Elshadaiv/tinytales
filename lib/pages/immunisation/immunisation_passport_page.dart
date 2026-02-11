import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:tinytales/data/baby_data.dart';
import 'package:tinytales/services/notification_service.dart';
import 'package:tinytales/services/pdf_service.dart';


class ImmunisationPassportPage extends StatefulWidget {
  const ImmunisationPassportPage({super.key, required this.babyId,required this.babyName});
  final String babyId;
  final String babyName;

  @override
  State<ImmunisationPassportPage> createState() => _ImmunisationPassportPageState();
}

class _ImmunisationPassportPageState extends State<ImmunisationPassportPage> {


  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  String? babyDob;

  final Map<int, List<String>> vaccineSchedule =
  {
    2: ['6-in-1', 'PCV', 'Rotavirus', 'MenB'],
    4: ['6-in-1', 'PCV', 'Rotavirus'],
    6: ['6-in-1', 'MenB'],
    12: ['MMR', 'MenB', 'PCV'],
    13: ['Hib/MenC', 'PCV'],
  };

  int selectedMonth = 2;

  final Map<String, String> selectedDates =
  {
  };

  final Map<String, int> selectedDose =
  {
  };

  List<String> recommendedVaccines = [];



  @override
  void initState() {
    super.initState();
    fetchBabyDob();
    selectedMonth = 2;
    _resetSelectedDates();
  }

  void _resetSelectedDates()
  {
    selectedDates.clear();
    selectedDose.clear();

    final list = vaccineSchedule[selectedMonth] ?? [];

    for (final v in list)
    {
      selectedDates[v] = '';
      selectedDose[v] = 1;
    }
  }


  Future<void> fetchBabyDob() async
  {
    final doc = await firestore.collection('baby_profiles').doc(widget.babyId).get();
    if(doc.exists)
    {
      setState(() {
        babyDob = doc['dob'];
        final part = babyDob!.split(RegExp(r'[\/\.-]'));
        final birthDate = DateTime(
          int.parse(part[2]),
          int.parse(part[1]),
          int.parse(part[0]),
        );
        final now = DateTime.now();

        final ageMonths = (now.year - birthDate.year) * 12 + (now.month - birthDate.month);

        final Map<int, List <String>> vaccinesSchedule =
        {
          2: ['6-in-1', 'PVC', 'Rotavirus', 'MenB'],
          4: ['6-in-1', 'PVC','Rotavirus'],
          6: ['6-in-1', 'MemB'],
          12:['MMR', 'MenB', 'PVC'],
          13:['Hib/MenC','PCV'],
        };
        recommendedVaccines = [];
        vaccinesSchedule.forEach((month, vaccines)
        {
          if(ageMonths >= month && ageMonths < month + 2)
          {
            recommendedVaccines = vaccines;
          }
        });

        if (recommendedVaccines.isNotEmpty)
        {
          NotificationService.showNotification(
            title: "Vaccine Reminder",
            body: "It's time for ${recommendedVaccines.join(', ')}!",
          );
        }
      });
    }
  }


  Widget _doseBoxOption(String vaccineName, int dose)
  {
    final int current = selectedDose[vaccineName] ?? 1;
    final bool checked = current == dose;

    return InkWell(
      onTap: ()
      {
        setState(()
        {
          selectedDose[vaccineName] = dose;
        });
      },
      child: Row(
        children: [
          Icon(
            checked ? Icons.check_box : Icons.check_box_outline_blank,
            size: 20,
          ),
          SizedBox(width: 4),
          Text(
            dose.toString(),
            style: TextStyle(fontSize: 13),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    final months = vaccineSchedule.keys.toList();
    months.sort();

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
          SizedBox(height: 16),

          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  "Select Month",
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                Spacer(),
                DropdownButton<int>(
                  value: selectedMonth,
                  items: months.map((m)
                  {
                    return DropdownMenuItem<int>(
                      value: m,
                      child: Text("$m months"),
                    );
                  }).toList(),
                  onChanged: (val)
                  {
                    if (val == null)
                    {
                      return;
                    }
                    setState(()
                    {
                      selectedMonth = val;
                      _resetSelectedDates();
                    });
                  },
                ),
              ],
            ),
          ),

          SizedBox(height: 10),

          Expanded(
            child: ListView(
              padding: EdgeInsets.symmetric(horizontal: 12),
              children: [
                ...((vaccineSchedule[selectedMonth] ?? []).map((vaccineName)
                {
                  return Card(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ListTile(
                            title: Text(vaccineName),
                            trailing: SizedBox(
                              width: 130,
                              child: TextField(
                                decoration: InputDecoration(
                                  hintText: "Enter Date",
                                ),
                                onChanged: (val)
                                {
                                  selectedDates[vaccineName] = val;
                                },
                              ),
                            ),
                          ),

                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              children: [
                                Text(
                                  "Dose",
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600
                                  ),
                                ),
                                SizedBox(width: 12),

                                _doseBoxOption(vaccineName, 1),
                                SizedBox(width: 8),
                                _doseBoxOption(vaccineName, 2),
                                SizedBox(width: 8),
                                _doseBoxOption(vaccineName, 3),
                                SizedBox(width: 8),
                                _doseBoxOption(vaccineName, 4),
                              ],
                            ),
                          ),

                          SizedBox(height: 6),
                        ],
                      ),
                    ),
                  );
                }).toList()),
              ],
            ),
          ),

          SizedBox(
            height: 190,
            child: StreamBuilder<QuerySnapshot>(
              stream: firestore
                  .collection('baby_profiles')
                  .doc(widget.babyId)
                  .collection('immunisations')
                  .snapshots(),
              builder: (context, snapshot)
              {
                if (snapshot.connectionState == ConnectionState.waiting)
                {
                  return Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
                {
                  return Padding(
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
                    columns: [
                      DataColumn(label: Text('Vaccine Name')),
                      DataColumn(label: Text('Date Given')),
                    ],
                    rows: immunisations.map((doc)
                    {
                      final data = doc.data() as Map<String, dynamic>;

                      final List<dynamic> datesList = data['dates'] ?? [];
                      final List<String> dates = datesList.map((d) => d.toString()).toList();

                      return DataRow(
                        cells: [
                          DataCell(Text(data['name'] ?? 'Unknown')),
                          DataCell(
                            dates.isEmpty
                                ? Text('-')
                                : SizedBox(
                              height: 120,
                              width: 150,
                              child: Scrollbar(
                                thumbVisibility: true,
                                radius: Radius.circular(8),
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.vertical,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: dates.map((d)
                                    {
                                      return Padding(
                                        padding: EdgeInsets.symmetric(vertical: 2.0),
                                        child: Text(
                                          "• $d",
                                          style: TextStyle(fontSize: 14),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                );
              },
            ),
          ),

          Padding(
            padding: EdgeInsets.only(bottom: 40.0),
            child: ElevatedButton(
              onPressed: () async
              {
                if(babyDob == null)
                {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Baby Date of Birth was not found',
                        style: TextStyle(
                            color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500
                        ),
                      ),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                      margin: EdgeInsets.symmetric(horizontal: 20, vertical: 40),
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
                }
                catch (e)
                {
                  dobDate = null;
                }

                final vaccinesForMonth = vaccineSchedule[selectedMonth] ?? [];

                for (final vaccineName in vaccinesForMonth)
                {
                  final dateText = (selectedDates[vaccineName] ?? '').trim();

                  if (dateText.isEmpty)
                  {
                    continue;
                  }

                  try
                  {
                    final parts = dateText.split(RegExp(r'[\/\.-]'));
                    final enteredDate = DateTime(
                      int.parse(parts[2]),
                      int.parse(parts[1]),
                      int.parse(parts[0]),
                    );

                    if (dobDate != null && enteredDate.isBefore(dobDate))
                    {
                      hasError = true;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Sorry! This date is BEFORE your child birth!',
                            style: TextStyle(
                                color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500
                            ),
                          ),
                          backgroundColor: Colors.red,
                          behavior: SnackBarBehavior.floating,
                          margin: EdgeInsets.symmetric(horizontal: 20, vertical: 40),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 6,
                        ),
                      );
                      return;
                    }
                  }
                  catch (e)
                  {
                    hasError = true;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Incorrect date format',
                          style: TextStyle(
                              color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500
                          ),
                        ),
                        backgroundColor: Colors.red,
                        behavior: SnackBarBehavior.floating,
                        margin: EdgeInsets.symmetric(horizontal: 20, vertical: 40),
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

                for (final vaccineName in vaccinesForMonth)
                {
                  final dateText = (selectedDates[vaccineName] ?? '').trim();

                  if (dateText.isEmpty)
                  {
                    continue;
                  }
                  final int dose = selectedDose[vaccineName] ?? 1;
                  final String dateToSave = "$dateText (dose $dose)";

                  final vaccineRef = firestore
                      .collection('baby_profiles')
                      .doc(widget.babyId)
                      .collection('immunisations')
                      .doc(vaccineName);

                  final doc = await vaccineRef.get();

                  if (doc.exists)
                  {
                    final data = doc.data() as Map<String, dynamic>? ?? {};
                    final existingDates = List<String>.from(data['dates'] ?? []);
                    existingDates.add(dateToSave);

                    await vaccineRef.update(
                        {
                          'dates': existingDates,
                          'name': vaccineName,
                        }
                    );
                  }
                  else
                  {
                    await vaccineRef.set(
                        {
                          'name': vaccineName,
                          'dates': [dateToSave],
                        }
                    );
                  }
                }

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Saved',
                      style: TextStyle(
                          color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500
                      ),
                    ),
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                    margin: EdgeInsets.symmetric(horizontal: 20, vertical: 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 6,
                  ),
                );
              },
              child: Text('Save'),
            ),
          ),

          Padding(
            padding: EdgeInsets.only(bottom: 20.0),
            child: ElevatedButton.icon(
              icon: Icon(Icons.picture_as_pdf),
              label: Text("Downlaod as PDF"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              onPressed: () async
              {
                final file = await PDFservice.generateImmunisationPDF(
                  babyId: widget.babyId,
                  babyName: widget.babyName,
                );

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("PDF saved at: ${file.path}"),
                    backgroundColor: Colors.green,
                  ),
                );
              },
            ),
          )
        ],
      ),
    );

  }
}