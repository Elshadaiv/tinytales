import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class FeverGuidancePage extends StatefulWidget
{
  FeverGuidancePage({super.key});

  @override
  State<FeverGuidancePage> createState() => _FeverGuidancePageState();
}

class _FeverGuidancePageState extends State<FeverGuidancePage>
{
  final auth = FirebaseAuth.instance;

  List<Map<String, dynamic>> babies = [

  ];
  String? selectedBabyId;

  @override
  void initState()
  {
    super.initState();
    _loadBabies();
  }

  Future<void> _loadBabies() async
  {
    final userId = auth.currentUser!.uid;

    final snapshot = await FirebaseFirestore.instance
        .collection("baby_profiles")
        .where("userId", isEqualTo: userId)
        .get();

    babies = snapshot.docs.map((doc)
    {
      return
        {
          "id": doc.id,
          "name": doc.get("name").toString(),
          "dob": (doc.data()["dob"] ?? "").toString(),
        };
    }).toList();

    if (babies.isNotEmpty)
    {
      selectedBabyId ??= babies.first["id"];
    }

    if (mounted)
    {
      setState(() {

      });
    }
  }

  @override
  Widget build(BuildContext context)
  {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      appBar: AppBar(
        backgroundColor: Colors.grey[300],
        title: Text(
          "Fever Guide",
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            if (babies.isEmpty)
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow:[
                    BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Text("No baby profile found."),
              ),


            if (babies.isNotEmpty)
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Select Baby",
                      style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 12),
                    DropdownButton<String>(
                      value: selectedBabyId,
                      isExpanded: true,
                      onChanged: (val)
                      {

                        if (val == null)
                        {
                          return;
                        }


                        setState(()
                        {
                          selectedBabyId = val;
                        });
                      },
                      items: babies.map<DropdownMenuItem<String>>((baby)
                      {
                        return DropdownMenuItem<String>(
                          value: baby["id"] as String,
                          child: Text(baby["name"].toString()),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),

            SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black12,
                    blurRadius: 6,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Text("this shows"),
            ),
          ],
        ),
      ),
    );
  }
}