import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:tinytales/pages/forms/addFeedingForm.dart';
import 'package:tinytales/pages/forms/addNappyForm.dart';
import 'package:tinytales/pages/history/NappyHIstoryList.dart';
import 'package:tinytales/pages/forms/addSleepForm.dart';
import 'package:tinytales/pages/history/SleepHistoryList.dart';

import 'package:tinytales/pages/forms/addTemperatureForm.dart';
import 'package:tinytales/pages/history/TemperatureHistoryList.dart';

import '../baby/fever_guidance_page.dart';
import '../history/feeding_history_page.dart';
import '../../services/selected_baby_service.dart';
import 'package:image_picker/image_picker.dart';


class TrackingPage extends StatefulWidget {
   TrackingPage({super.key});

  @override
  State<TrackingPage> createState() => _TrackingPageState();
}

class _TrackingPageState extends State<TrackingPage> {
  final _db = FirebaseDatabase.instance.ref();
  final _auth = FirebaseAuth.instance;

  String? get selectedBabyId => SelectedBabyService.selectedBabyId.value;
  @override
  void initState()
  {
    super.initState();
    SelectedBabyService.selectedBabyId.addListener(_onSelectedBabyChanged);
  }

  void _onSelectedBabyChanged()
  {
    if (mounted)
    {
      setState(() {
      });
    }
  }
  @override
  void dispose()
  {
    SelectedBabyService.selectedBabyId.removeListener(_onSelectedBabyChanged);
    super.dispose();
  }
  Future<void> addFeeding(
      {
    required String babyId,
    required Map<String, dynamic> entry,
  }) async
  {
    final userId = _auth.currentUser!.uid;

    final ref = _db.child("users/$userId/tracking/$babyId/feedings").push();
    await ref.set(entry);
  }

  Future<void> addNappy(
      {
    required String babyId,
    required String type,
    required DateTime time,
    String? color,
    String? notes,
        String? imageBase64,
  }) async
  {
    final userId = _auth.currentUser!.uid;
    final ref = _db.child("users/$userId/tracking/$babyId/nappies").push();

    await ref.set({
      "type": type,
      "time": time.toIso8601String(),
      "color": color ?? "",
      "notes": notes ?? "",
      "imageBase64": imageBase64 ?? "",
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

  Future<void> addTemperature({
    required String babyId,
    required double value,
    required DateTime time,
    String unit = "C",
  }) async
  {
    final userId = _auth.currentUser!.uid;
    final ref = _db.child("users/$userId/tracking/$babyId/temperatures").push();


    await ref.set(
        {
          "value": value,
          "unit": unit,
          "time": time.toIso8601String(),
        });

  }
  
  Future<void> addMedication({
    required String babyId,
    required String type,
    required String dose,
    required DateTime time,
  }) async

  {
    final userId = _auth.currentUser!.uid;
    
    final ref = _db.child("users/$userId/tracking/$babyId/medications").push();

    await ref.set({
      "type": type,
      "dose": dose,
      "time": time.toIso8601String(),
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
            onSubmit: (entry)
            async
            {
              await addFeeding(
                babyId: selectedBabyId!,
                entry: entry
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
            onSubmit: (type, time, color, notes, imageBase64)
            async
                {
              await addNappy(
                babyId: selectedBabyId!,
                type: type,
                time: time,
                color: color,
                notes: notes,
                imageBase64: imageBase64,
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



  void _openAddTemperature(BuildContext context)
  {
    if (selectedBabyId == null)
    {
      return;
    }

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
            left: 20, right: 20, top: 20,
          ),
          child: AddTemperatureForm(
            parentContext: context,
            onSubmit: (value, time)
            async
            {
              await addTemperature(
                babyId: selectedBabyId!, value: value,
                time: time,
              );
            },
          ),
        );
      },
    );
  }


  Widget _sectionTitle(String title, IconData icon, Color color)
  {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  BoxDecoration _trackingCardDecoration(Color color)
  {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: color.withOpacity(0.25), width: 1.4,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black12,
          blurRadius: 8,
          offset: Offset(0, 4),
        ),
      ],
    );
  }



  @override
  Widget build(BuildContext context)
  {
    if (selectedBabyId == null)
    {
      return  Scaffold(
        backgroundColor: Color(0xFFF7F6FB),
        body: Center(
          child: CircularProgressIndicator(color: Colors.purple),
        ),
      );
    }
    return Scaffold(
      backgroundColor: Color(0xFFF7F6FB),
      appBar: AppBar(backgroundColor: Color(0xFFF7F6FB),),
        body: RefreshIndicator(
          onRefresh: () async
          {
        setState(() {
      });            },
          color: Colors.purple,
      child: Padding(
        padding:  EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             _sectionTitle("Feeding", Icons.restaurant, Colors.orange),
             SizedBox(height: 10),
            Container(
              padding:  EdgeInsets.all(16),
              decoration: _trackingCardDecoration(Colors.orange),
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
                            "type": e["type"],
                            "amount": e["amount"],
                            "time": e["time"],
                            "durationMinutes": e["durationMinutes"],
                            "food": e["food"],
                            "side": e["side"],
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
                          final timeString = latest["time"]!;
                          final time = DateTime.tryParse(timeString);

                          final formatted = time != null ? "${time.hour}:${time.minute.toString().padLeft(2, '0')}" : "Unknown";
                          final type = (latest["type"] ?? "bottle").toString();
                          String summary = "";

                          if (type == "breast")
                          {
                            final side = (latest["side"] ?? "").toString();
                            final mins = latest["durationMinutes"] ?? 0;
                            summary = "Breast ($side) ${mins}m";
                          }
                          else if (type == "solids")
                          {
                            final food = (latest["food"] ?? "").toString();
                            summary = "Solids: $food";
                          }
                          else
                          {
                            final amount = latest["amount"] ?? "";
                            summary = "$amount ml";
                          }
                          return Text(
                            "$summary at $formatted",
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
                        backgroundColor: Colors.orange.shade50,
                        foregroundColor: Colors.orange.shade900,
                        elevation: 0,
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
                decoration: _trackingCardDecoration(Colors.orange),
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

            _sectionTitle("Nappies", Icons.baby_changing_station, Colors.blue),

         SizedBox(height: 10),

        Container(
          padding:  EdgeInsets.all(16),
          decoration: _trackingCardDecoration(Colors.blue),
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
                backgroundColor: Colors.blue.shade50,
                foregroundColor: Colors.blue.shade900,
                elevation: 0,
              ),
              child:  Text("Add Nappy"),
            ),
              ),
            ],
          ),
        ),

             SizedBox(height: 20),

            GestureDetector(
              onTap: () async
              {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => NappyHistoryList(babyId: selectedBabyId!),
                  ),
                );
                setState(() {

                });
              },
              child: Container(
                padding:  EdgeInsets.all(16),
               decoration: _trackingCardDecoration(Colors.blue),
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

            _sectionTitle("Sleep", Icons.bedtime, Colors.deepPurple),

            SizedBox(height: 10),

            Container(
              padding:  EdgeInsets.all(16),
              decoration: _trackingCardDecoration(Colors.deepPurple),
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
                        backgroundColor: Colors.deepPurple.shade50,
                        foregroundColor: Colors.deepPurple,
                        elevation: 0,
                      ),
                      child: Text("Add Sleep"),
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
                    builder: (_) => SleepHistoryList(babyId: selectedBabyId!),
                  ),
                );
              },
              child: Container(
                padding:  EdgeInsets.all(16),
                decoration: _trackingCardDecoration(Colors.deepPurple),

                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "View Sleep History",
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey[700]),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),

            _sectionTitle("Temperature", Icons.thermostat, Colors.redAccent),

            SizedBox(height: 10),

            Container(
              padding:  EdgeInsets.all(16),
              decoration: _trackingCardDecoration(Colors.redAccent),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Last Temperature:",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      StreamBuilder(
                        stream: _db
                            .child(
                            "users/${_auth.currentUser!.uid}/tracking/$selectedBabyId/temperatures")
                            .onValue,
                        builder: (context, snapshot)
                        {
                          if (!snapshot.hasData || snapshot.data?.snapshot.value == null)
                          {
                            return Text("no entries", style: TextStyle(color: Colors.grey[700]));
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
                            "value": e["value"],
                            "unit": e["unit"] ?? "C",
                            "time": e["time"],
                          })
                              .where((e) => e["time"] != null)
                              .toList();

                          if (entries.isEmpty)
                          {
                            return Text("no entries", style: TextStyle(color: Colors.grey[700]));
                          }

                          entries.sort((a, b) => DateTime.parse(a["time"]!)
                              .compareTo(DateTime.parse(b["time"]!)));

                          final latest = entries.last;

                          final value = latest["value"];
                          final unit = latest["unit"] ?? "C";

                          final timeString = latest["time"]!;
                          final time = DateTime.tryParse(timeString);

                          final formatted = time != null ? "${time.hour}:${time.minute.toString().padLeft(2, '0')}" : "";

                          if (formatted.isNotEmpty)
                          {
                            return Text(
                              "$value °$unit at $formatted",
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            );
                          }
                          return Text(
                            "$value °$unit",
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
                      onPressed: () => _openAddTemperature(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade50,
                        foregroundColor: Colors.redAccent,
                        elevation: 0,
                      ),
                      child: Text("Add Temperature"),
                    ),
                  ),

                  SizedBox(height: 10),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade50,
                        foregroundColor: Colors.redAccent,
                        elevation: 0,
                      ),
                      onPressed: ()
                      {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => FeverGuidancePage(),
                          ),
                        );
                      },
                      child: Text("View Fever Guidance"),
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
                    builder: (_) => TemperatureHistoryList(babyId: selectedBabyId!),
                  ),
                );
              },
              child: Container(
                padding:  EdgeInsets.all(16),
                decoration: _trackingCardDecoration(Colors.redAccent),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "View Temperature History",
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey[700]),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
    ),
    );
  }
}
