import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:tinytales/pages/addFeedingForm.dart';
import 'package:tinytales/pages/addNappyForm.dart';
import 'package:tinytales/pages/NappyHIstoryList.dart';
import 'package:tinytales/pages/addSleepForm.dart';


import 'feeding_history_page.dart';

class TrackingPage extends StatefulWidget {
   TrackingPage({super.key});

  @override
  State<TrackingPage> createState() => _TrackingPageState();
}

class _TrackingPageState extends State<TrackingPage> {
  final _db = FirebaseDatabase.instance.ref();
  final _auth = FirebaseAuth.instance;

  List<Map<String, dynamic>> babies = [];
  String? selectedBabyId;

  @override
  void initState()
  {
    super.initState();
    loadBabies();
  }

  Future<void> loadBabies()
  async
  {

    final userId = _auth.currentUser!.uid;

    final snapshot = await FirebaseFirestore.instance
        .collection("baby_profiles")
        .where("userId", isEqualTo: userId)
        .get();

    babies = snapshot.docs.map((doc)
    {
      return
        {
        "id": doc.id,
        "name": doc["name"],
      };
    }).toList();

    if (babies.isNotEmpty)
    {
      selectedBabyId ??= babies.first["id"];
    }

    setState(() {});
  }

  Future<void> addFeeding(
      {
    required String babyId,
    required int amount,
    required DateTime time,
  }) async
  {
    final userId = _auth.currentUser!.uid;

    final ref = _db.child("users/$userId/tracking/$babyId/feedings").push();
    await ref.set(
        {
      "amount": amount,
      "time": time.toIso8601String(),
    });
  }

  Future<void> addNappy(
      {
    required String babyId,
    required String type,
    required DateTime time,
    String? color,
    String? notes,
  }) async
  {
    final userId = _auth.currentUser!.uid;
    final ref = _db.child("users/$userId/tracking/$babyId/nappies").push();

    await ref.set({
      "type": type,
      "time": time.toIso8601String(),
      "color": color ?? "",
      "notes": notes ?? "",
    });
  }


  Future<void> addSleep({
    required String babyId,
    required DateTime startTime,
    required DateTime endTime,
    String? notes,
}) async
  {
    final userId = _auth.currentUser!.uid;

    final duration = endTime.difference(startTime);
    final durationMins = duration.inMinutes;

    final ref = _db.child("users/$userId/tracking/$babyId/sleeps").push();


    await ref.set({
      "startTime": startTime.toIso8601String(),
      "endTime": endTime.toIso8601String(),
      "durationMinutes": durationMins,
      "notes": notes ?? "",
    });
  }

  String _formatTime(DateTime time)
  {
    return "${time.hour}:${time.minute.toString().padLeft(2, '0')}";
  }

  String _formatDurationMinutes(int minutes)
  {
    final h = minutes ~/ 60;
    final m = minutes % 60;

    if (h == 0)
      return "${m}m";

    if (m == 0)
      return "${h}h";

    return "${h}h ${m}m";
  }


  void _openAddFeeding(BuildContext context)
  {
    if (selectedBabyId == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext)
      {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: AddFeedingForm(
            parentContext: context,
            onSubmit: (amount, time)
            async
            {
              await addFeeding(
                babyId: selectedBabyId!,
                amount: amount,
                time: time,
              );
            },
          ),
        );
      },
    );
  }

  void _openAddNappy(BuildContext context)
  {
    if (selectedBabyId == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape:  RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext)
      {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: AddNappyForm(
            parentContext: context,
            onSubmit: (type, time, color, notes)
            async
                {
              await addNappy(
                babyId: selectedBabyId!,
                type: type,
                time: time,
                color: color,
                notes: notes,
              );
            },
          ),
        );
      },
    );
  }


  void _openAddSleep(BuildContext context)
  {
    if(selectedBabyId == null)
      return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),

      builder: (sheetContext)
      {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: AddSleepForm(
            parentContext: context,
            onSubmit: (startTime, endTime, notes)
            async
            {
              await addSleep(
                babyId: selectedBabyId!,
                startTime: startTime,
                endTime: endTime,
                notes: notes,
              );
            },
          ),
        );
      },
    );
  }



  @override
  Widget build(BuildContext context)
  {
    if (selectedBabyId == null)
    {
      return  Scaffold(
        backgroundColor: Colors.grey,
        body: Center(
          child: CircularProgressIndicator(color: Colors.purple),
        ),
      );
    }
    return Scaffold(
      backgroundColor: Colors.grey[300],
      appBar: AppBar(backgroundColor: Colors.grey[300]),
      body: Padding(
        padding:  EdgeInsets.all(16.0),
        child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButton<String>(
              value: selectedBabyId,
              onChanged: (newValue)
              {
                setState(() {
                  selectedBabyId = newValue;
                });
              },

              items: babies.map<DropdownMenuItem<String>>((baby)
              {
                return DropdownMenuItem<String>
                  (
                  value: baby["id"] as String,
                  child: Text(baby["name"] as String),
                );
              }).toList(),
            ),
             Text(
              " Feeding", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
             SizedBox(height: 10),
            Container(
              padding:  EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow:
                [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 6,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                       Text("Last Feeding:", style:
                      TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      StreamBuilder(
                        stream: _db
                            .child(
                            "users/${_auth.currentUser!.uid}/tracking/$selectedBabyId/feedings")
                            .onValue,

                        builder: (context, snapshot)
                        {
                          if (!snapshot.hasData || snapshot.data?.snapshot.value == null)
                          {
                            return Text("NO ENTRIES", style: TextStyle(color: Colors.grey[700]));
                          }

                          final data = snapshot.data!.snapshot.value;

                          Map<dynamic, dynamic> raw =
                          {
                          };
                          if (data is List)
                          {
                            raw =
                            {
                              for (int i = 0; i < data.length; i++)
                                if (data[i] != null) i: data[i]
                            };
                          } else if (data is Map)
                          {
                            raw = data;
                          }

                          final entries = raw.values.map((e) =>
                          {
                            "amount": e["amount"],
                            "time": e["time"],
                          })
                              .where((e) => e["time"] != null)
                              .toList();

                          if (entries.isEmpty)
                          {
                            return Text("NO ENTRIES",
                                style:
                                TextStyle(color: Colors.grey[700]));
                          }

                          entries.sort((a, b) => DateTime.parse(a["time"]!)
                              .compareTo(DateTime.parse(b["time"]!)));

                          final latest = entries.last;
                          final amount = latest["amount"];
                          final timeString = latest["time"]!;
                          final time = DateTime.tryParse(timeString);

                          final formatted = time != null ? "${time.hour}:${time.minute.toString().padLeft(2, '0')}" : "Unknown";

                          return Text(
                            "$amount ml at $formatted",
                            style:  TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  SizedBox(height: 12),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _openAddFeeding(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                      ),
                      child:  Text("Add Feeding"),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 20),

            GestureDetector(
              onTap: ()
              {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FeedingHistoryPage(babyId: selectedBabyId!),
                  ),
                );
              },
              child: Container(
                padding:  EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow:  [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 6,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                     Text(
                      "View Feeding History",
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey[700]),
                  ],
                ),
              ),
            ),
             SizedBox(height: 20),

         Text(
          "Nappies",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),

         SizedBox(height: 10),

        Container(
          padding:  EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow:  [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 6,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   Text(
                    "Last Nappy:",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  StreamBuilder(
                    stream: _db
                        .child(
                        "users/${_auth.currentUser!.uid}/tracking/$selectedBabyId/nappies")
                        .onValue,

                    builder: (context, snapshot)
                    {
                      if (!snapshot.hasData || snapshot.data!.snapshot.value == null)
                      {
                        return Text("NO ENTRIES", style: TextStyle(color: Colors.grey[700]));
                      }

                      final data = snapshot.data!.snapshot.value as Map;
                      final last = data.values.last;
                      final type = last["type"];
                      final time = DateTime.parse(last["time"]);

                      final formatted = "${time.hour}:${time.minute.toString().padLeft(2, '0')}";

                      return Text("$type at $formatted");
                    },
                  ),
                ],
              ),

               SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _openAddNappy(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
              ),
              child:  Text("Add Nappy"),
            ),
              ),
            ],
          ),
        ),

             SizedBox(height: 20),

            GestureDetector(
              onTap: ()
              {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => NappyHistoryList(babyId: selectedBabyId!),
                  ),
                );
              },
              child: Container(
                padding:  EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow:  [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 6,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                     Text(
                      "View Nappy History",
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey[700]),
                  ],
                ),
              ),
            ),
             SizedBox(height: 20),

            Text(
              "Sleep",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),

            SizedBox(height: 10),

            Container(
              padding:  EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow:  [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 6,
                    offset: Offset(0, 3),
                  ),
                ],
              ),

              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Last Sleep:",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      StreamBuilder(
                        stream: _db
                            .child(
                            "users/${_auth.currentUser!.uid}/tracking/$selectedBabyId/sleeps")
                            .onValue,

                        builder: (context, snapshot)
                        {
                          if (!snapshot.hasData || snapshot.data?.snapshot.value == null)
                          {
                            return Text("NO ENTRIES", style: TextStyle(color: Colors.grey[700]));
                          }
                          final data = snapshot.data!.snapshot.value;

                          Map<dynamic, dynamic> raw =
                          {
                          };
                          if (data is List)
                          {
                            raw =
                            {
                              for (int i = 0; i < data.length; i++)
                                if (data[i] != null) i: data[i]
                            };
                          }
                          else if (data is Map)
                          {
                            raw = data;
                          }

                          final entries = raw.values.map((e) =>
                          {
                            "startTime": e["startTime"],
                            "endTime": e["endTime"],
                            "durationMinutes": e["durationMinutes"] ?? 0,
                          })
                              .where((e) => e["endTime"] != null)
                              .toList();

                          if (entries.isEmpty)
                          {
                            return Text("NO ENTRIES", style: TextStyle(color: Colors.grey[700]));
                          }

                          entries.sort((a, b) => DateTime.parse(a["endTime"]!)
                              .compareTo(DateTime.parse(b["endTime"]!)));

                          final latest = entries.last;
                          final endString = latest["endTime"]!;
                          final endTime = DateTime.tryParse(endString);

                          final durationMinutes = latest["durationMinutes"] is int
                              ? latest["durationMinutes"]
                              : int.tryParse(latest["durationMinutes"].toString()) ?? 0;

                          if (endTime == null)
                          {
                            return Text("Unknown", style: TextStyle(color: Colors.grey[700]));
                          }

                          final formattedEnd = _formatTime(endTime);
                          final formattedDuration = _formatDurationMinutes(durationMinutes);

                          return Text(
                            "$formattedDuration (end $formattedEnd)",
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          );
                        },
                      ),
                    ],
                  ),

                  SizedBox(height: 12),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _openAddSleep(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                      ),
                      child: Text("Add Sleep"),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }
}
