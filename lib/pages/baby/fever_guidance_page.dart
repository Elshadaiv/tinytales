import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
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

  final db = FirebaseDatabase.instance.ref();
  double? latestTemperature;
  String latestTemperatureTime = "";
  bool loadingTemperature = false;
  DateTime? selectedBabyDob;
  int selectedBabyAgeMonths = 0;

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
      return;
    }
    final baby = babies.firstWhere((b) => b["id"] == selectedBabyId,);
    selectedBabyDob = _parseDob(baby["dob"]?.toString());

    if (selectedBabyDob != null)
    {
      selectedBabyAgeMonths = _calculateAgeInMonths(selectedBabyDob!);
    }
    else
    {
      selectedBabyAgeMonths = 0;
    }
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
                    "Age : $selectedBabyAgeMonths months",
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
          ],
        ),
      ),
    );
  }
}