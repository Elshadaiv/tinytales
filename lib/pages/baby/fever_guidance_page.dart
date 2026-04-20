import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:tinytales/data/medication_guidance.dart';

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

  final db = FirebaseDatabase.instance.ref();
  double? latestTemperature;
  String latestTemperatureTime = "";
  bool loadingTemperature = false;
  DateTime? selectedBabyDob;
  int selectedBabyAgeMonths = 0;
  String selectedBabyAgeText = "";

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
      _updateSelectedBabyAge();
      await _loadLatestTemperature();

    }

    if (mounted)
    {
      setState(() {
      });
    }
  }

  Future<void> _loadLatestTemperature() async
  {
    if (selectedBabyId == null)
    {
      return;
    }
    setState(()
    {
      loadingTemperature = true;
    });

    final userId = auth.currentUser!.uid;

    final snapshot = await db
        .child("users/$userId/tracking/$selectedBabyId/temperatures")
        .get();

    latestTemperature = null;
    latestTemperatureTime = "";

    if (snapshot.exists)
    {
      final data = snapshot.value;
      Map<dynamic, dynamic> raw = {};

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
        "time": e["time"],
      })
          .where((e) => e["time"] != null)
          .toList();

      if (entries.isNotEmpty)
      {
        entries.sort((a, b)
        {
          final at = DateTime.tryParse(a["time"].toString()) ?? DateTime(1970);
          final bt = DateTime.tryParse(b["time"].toString()) ?? DateTime(1970);
          return at.compareTo(bt);
        });

        final latest = entries.last;

        latestTemperature = double.tryParse(latest["value"].toString());
        final time = DateTime.tryParse(latest["time"].toString());
        if (time != null)
        {
          latestTemperatureTime =
          "${time.day}/${time.month}/${time.year} at ${time.hour}:${time.minute.toString().padLeft(2, '0')}";
        }
      }
    }

    if (mounted)
    {
      setState(()
      {
        loadingTemperature = false;
      });
    }
  }

  DateTime? _parseDob(String? dob)
  {
    if (dob == null || dob.isEmpty)
    {
      return null;
    }

    final iso = DateTime.tryParse(dob);
    if (iso != null)
    {
      return iso;
    }

    final parts = dob.split("/");
    if (parts.length == 3)
    {
      final day = int.tryParse(parts[0]);
      final month = int.tryParse(parts[1]);
      final year = int.tryParse(parts[2]);

      if (day != null && month != null && year != null)
      {
        return DateTime(year, month, day);
      }
    }

    return null;
  }

  int _calculateAgeInMonths(DateTime dob)
  {
    final now = DateTime.now();

    int months = (now.year - dob.year) * 12 + (now.month - dob.month);

    if (now.day < dob.day)
    {
      months--;
    }
    return months < 0 ? 0 : months;
  }

  void _updateSelectedBabyAge()
  {
    if (selectedBabyId == null)
    {
      selectedBabyDob = null;
      selectedBabyAgeMonths = 0;
      selectedBabyAgeText = "";
      return;
    }
    final baby = babies.firstWhere((b) => b["id"] == selectedBabyId);
    selectedBabyDob = _parseDob(baby["dob"]?.toString());

    if (selectedBabyDob != null)
    {
      selectedBabyAgeMonths = _calculateAgeInMonths(selectedBabyDob!);
      selectedBabyAgeText = _formatBabyAge(selectedBabyDob!);
    }
    else
    {
      selectedBabyAgeMonths = 0;
    }
  }

  String _formatBabyAge(DateTime dob)
  {
    final now = DateTime.now();

    int years = now.year - dob.year;
    int months = now.month - dob.month;
    int days = now.day - dob.day;

    if (days < 0)
    {
      months--;
    }
    if (months < 0)
    {
      years--;
      months += 12;
    }
    final totalDays = now.difference(dob).inDays;

    if (totalDays < 7)
    {
      return "$totalDays day${totalDays == 1 ? "" : "s"} old";
    }

    if (totalDays < 60)
    {
      final weeks = (totalDays / 7).floor();
      return "$weeks week${weeks == 1 ? "" : "s"} old";
    }

    if (years <= 0)
    {
      return "$months month${months == 1 ? "" : "s"} old";
    }
    if (months == 0)
    {
      return "$years year${years == 1 ? "" : "s"} old";
    }
    return "$years year${years == 1 ? "" : "s"} $months month${months == 1 ? "" : "s"} old";
  }

  Map<String, dynamic> _checkFever(double temp, int ageMonths)
  {
    if (ageMonths <= 3)
    {
      if (temp > 37.4)
      {
        return
          {
          "status": "HIGH FEVER", "color": Colors.red,
          "message": "Baby under 3 months with fever. Seek medical advice immediately."
        };
      }
      return
        {
        "status": "NORMAL", "color": Colors.green,
        "message": "Temperature is within normal range."
      };
    }

    if (ageMonths <= 36)
    {
      if (temp >= 38.5)
      {
        return
          {
          "status": "HIGH FEVER", "color": Colors.red,
          "message": "High fever detected."
        };
      }

      if (temp >= 37.6)
      {
        return
          {
          "status": "MODERATE FEVER", "color": Colors.orange,
          "message": "Moderate fever. Monitor closely."
        };
      }
      return
        {
        "status": "NORMAL", "color": Colors.green,
        "message": "Temperature is within normal range."
      };
    }

    if (temp >= 39.4)
    {
      return
        {
        "status": "HIGH FEVER", "color": Colors.red,
        "message": "High fever detected."
      };
    }

    if (temp >= 37.7)
    {
      return
        {
        "status": "MODERATE FEVER", "color": Colors.orange,
        "message": "Moderate fever. Monitor closely."
      };
    }
    return
      {
      "status": "NORMAL", "color": Colors.green,
      "message": "Temperature is within normal range."
    };
  }

  Future<Map<String, dynamic>> _checkMedicationSafety(String type) async
  {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final snapshot = await FirebaseDatabase.instance
        .ref()
        .child("users/$userId/tracking/$selectedBabyId/medications")
        .get();
    if (!snapshot.exists)
    {
      return
        {
        "canGive": true,
        "message": "$type can be given now.",
      };
    }
    final data = Map<dynamic, dynamic>.from(snapshot.value as Map);
    final now = DateTime.now();

    final doseTimes = data.values
        .where((e) => e["type"]?.toString().toLowerCase() == type.toLowerCase())
        .map((e) => DateTime.tryParse(e["time"].toString()))
        .whereType<DateTime>()
        .toList();

    doseTimes.sort((a, b) => b.compareTo(a));
    final minGapHours = type == "Calpol" ? 4 : 6;
    final maxDoses24h = type == "Calpol" ? 4 : 3;

    final dosesLast24h = doseTimes.where((time) => now.difference(time).inHours < 24).length;
    if (dosesLast24h >= maxDoses24h)
    {
      return {
        "canGive": false,
        "message": "Maximum $type doses reached in the last 24 hours.",
      };
    }
    if (doseTimes.isNotEmpty)
    {
      final hoursSinceLastDose = now.difference(doseTimes.first).inHours;

      if (hoursSinceLastDose < minGapHours)
      {
        final hoursLeft = minGapHours - hoursSinceLastDose;

        return {
          "canGive": false,
          "message": "Wait $hoursLeft more hour${hoursLeft == 1 ? "" : "s"} before giving $type again.",
        };
      }
    }
    return {
      "canGive": true,
      "message": "$type can be given now.",
    };
  }

  Future<void> _logMedication (String type, String dose) async
  {
    if(selectedBabyAgeMonths < 3)
      {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(
            "Babies under 3 months with fever should be assessed by a doctor.",
          ),
          ),
        );
        return;
      }
    final safety = await _checkMedicationSafety(type);

    if (safety["canGive"] == false)
    {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Cannot give $type right now. ${safety["message"]}"),        ),
      );
      return;
    }
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final ref = FirebaseDatabase.instance
    .ref()
      .child("users/$userId/tracking/$selectedBabyId/medications").push();

    await ref.set({
      "type": type,
      "dose": dose,
      "time": DateTime.now().toIso8601String(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("$type dose logged")),
    );
  }

  Widget _buildMedicationGuidance(double temp)
  {
    final result = _checkFever(temp, selectedBabyAgeMonths);
    final status = result["status"];

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),

      child:  Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Text(
            "Medication Guide",
            style: TextStyle(
              fontSize: 18, fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 10,),

          if(status == "NORMAL")
            Text(
              "Medication not required at this time",
              style: TextStyle(color: Colors.black54),
            ),
          if(status != "NORMAL") ...[
          if(selectedBabyAgeMonths <= 3)
             Text(
                  "Emergency, Babies under 3 months with fever should seek attention with a doctor.",
                  style: TextStyle(color: Colors.redAccent,
              fontWeight: FontWeight.w600
  ),
  ),
    SizedBox(height: 6,),

            Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Text(MedicationGuidance.calpol(selectedBabyAgeMonths),
                style: TextStyle(fontWeight: FontWeight.w600),
                ),

                SizedBox(height: 6,),

                ElevatedButton(
                  onPressed: ()
                  {
                    _logMedication(
                      "Calpol", MedicationGuidance.calpol(selectedBabyAgeMonths),
                    );
                  },
                  child: Text("Log Calpol Dose"),
                ),

                SizedBox(height:12),

                Text(
                  MedicationGuidance.nurofen(selectedBabyAgeMonths),
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                SizedBox(height:6),

                ElevatedButton(
                  onPressed: ()
                  {
                    _logMedication(
                      "Nurofen", MedicationGuidance.nurofen(selectedBabyAgeMonths),
                    );
                  },
                  child: Text("Log Nurofen Dose"),
                ),
              ],
            )
        ]
    ],
      ),
    );
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
                      onChanged: (val) async
                      {

                        if (val == null)
                        {
                          return;
                        }


                        setState(()
                        {
                          selectedBabyId = val;
                          _updateSelectedBabyAge();
                        });
                        await _loadLatestTemperature();
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
              child: loadingTemperature ? Center
                (
                child: CircularProgressIndicator(color: Colors.purpleAccent,),
              )
                  : latestTemperature == null
                ? Text("No Temperature recorded yet.")
                  :Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Latest Temperature",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Age : $selectedBabyAgeText",
                    style: TextStyle(fontWeight: FontWeight.w600,
                    color: Colors.black87),
                  ),

                  SizedBox(
                    height:10
                  ),
                  Text(
                    "${latestTemperature!.toStringAsFixed(1)} °C",

                        style: TextStyle( fontSize: 26, fontWeight: FontWeight.bold),
                  ),
            SizedBox(height: 16,),

            Builder(
              builder: (context)
                  {
                    final result = _checkFever( latestTemperature!,
                        selectedBabyAgeMonths,);

                    return Container(
                      width: double.infinity,padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: result["color"],
                          borderRadius: BorderRadius.circular(14),
                        ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                          Text(
                            result["status"],
                            style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 6,),

                          Text(
                            result["message"],
                            style: TextStyle(
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
            ),
            SizedBox(height: 6),
                  Text(
                    latestTemperatureTime,
                    style: TextStyle(color: Colors.black54),
                  ),
                ],
              )
            ),

            SizedBox(height: 14),

            if (latestTemperature != null)
              _buildMedicationGuidance(latestTemperature!)
          ],
        ),
      ),
    );
  }
}