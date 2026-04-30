
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:tinytales/pages/main/community_page.dart';
import 'package:tinytales/pages/main/insights_page.dart';
import 'package:tinytales/pages/main/profile_page.dart';
import 'package:tinytales/pages/main/tracking_page.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:tinytales/pages/main/milestone_page.dart';
import 'dart:convert';


import '../../data/growthchart_page.dart';
import '../../services/analytics_page.dart';
import '../../services/community_event.dart';
import '../../services/community_service.dart';
import '../../services/selected_baby_service.dart';



class  HomePage extends StatefulWidget {
   HomePage({super.key});


   @override
   State<HomePage> createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  final user = FirebaseAuth.instance.currentUser;
  final db = FirebaseDatabase.instance.ref();
  final auth = FirebaseAuth.instance;

  CommunityEvent? nearbyEvent;
  CommunityService communityService = CommunityService();

  int currentPage = 0;

  String lastFeed = "";
  String lastSleep = "";
  String lastNappy = "";
  String lastTemp = "";
  String smartAlertTitle = "";
  String smartAlertMessage = "";

  String currentWeight = "";
  String currentHeight = "";

  String latestMedication = "";
  String latestMedicationTime = "";
  String homeTempStatus = "";
  Color homeTempColor = Colors.green;
  List<Map<String, dynamic>> homeAlerts = [];

  List<Map<String, dynamic>> babies = [];
  String? get selectedBabyId => SelectedBabyService.selectedBabyId.value;
  String get selectedBabyName => SelectedBabyService.selectedBabyName.value;

  DateTime? lastFeedTime;
  DateTime? lastNappyTime;
  DateTime? lastSleepEndTime;
  bool alertShown = false;


  double? firstWeight;
  double? currentWeightVal;
  String growthInsight = "";



  List<Widget> get pages
  {
    return[
    RefreshIndicator(
      onRefresh: () async
      {
        await _loadBabies();
        await _homeSummary();
        await _checkSmartCareAlert();
        await _loadHomeAlerts();
      },
      color: Colors.purple,
      child: ListView(
        padding: EdgeInsets.all(16),
        children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 18),
            Row(
          children: [
            if (babies.isNotEmpty) _babyAvatar(),
            if (babies.isNotEmpty) SizedBox(width: 14),
        Expanded(
             child: Text(
              babies.isEmpty
              ? "Welcome!"
              : " $selectedBabyName",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.black87),
            ),
        ),
            Spacer(),

            if (babies.isEmpty)
              Text("No babies")
            else
              DropdownButton<String>(
                value: selectedBabyId,
                onChanged: (val) async
                {
                  if (val == null) return;

                  final picked = babies.firstWhere(
                        (b) => b["id"] == val, orElse: () => <String, dynamic>{"id": val, "name": ""},
                  );

                  SelectedBabyService.selectedBabyId.value = val;
                  SelectedBabyService.selectedBabyName.value = (picked["name"] ?? "").toString();
                  setState(() {

                    lastFeedTime = null;
                    lastNappyTime = null;
                    lastSleepEndTime = null;

                    smartAlertTitle = "";
                    smartAlertMessage = "";
                    alertShown = false;
                  });
                 await _homeSummary();
                 await  _checkSmartCareAlert();
                },
                items: babies.map<DropdownMenuItem<String>>((baby)
                {
                  return DropdownMenuItem<String>(
                    value: baby["id"] as String,
                    child: Text(baby["name"] as String),
                  );
                }).toList(),
              ),
          ],
        ),
            _smartSummaryCard(),
            SizedBox(height: 18),

            GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                childAspectRatio: 1.1,
                children: [
                  _summary("Last feed", lastFeed, Icons.restaurant, "feed"),
                  _summary("Last sleep", lastSleep, Icons.bedtime, "sleep"),
                  _summary("Temperature", lastTemp, Icons.thermostat, "temperature"),
                  _summary("Last Nappy", lastNappy, Icons.baby_changing_station, "nappy"),
                ],
            ),
            SizedBox(height: 12),
            Center(
              child: _growthSummary(),
            ),
          ],
        ),
        ],
      ),
    ),
      InsightsPage(),
      TrackingPage(),
      CommunityPage(),
      milestone_page(),
    ];
  }

  void signUserOut() {
    FirebaseAuth.instance.signOut();
  }

  void toProfile()
  {
    Navigator.push(
      context, MaterialPageRoute(
      builder: (context) => ProfilePage(),
    ),
    );
  }

  @override
  void initState()
  {
    super.initState();
    SelectedBabyService.selectedBabyId.addListener(_onSelectedBabyChanged);
    _loadBabies();
    _loadNearbyEvent();
    _loadHomeAlerts();
  }

  void _onSelectedBabyChanged()
  {
    if (mounted)
    {
      _homeSummary();
      _checkSmartCareAlert();
      _loadHomeAlerts();
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

  Future<void> _loadNearbyEvent() async
  {
    try
    {
      final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high,);

      final events = await communityService.fetchLiveEvents(
        position.latitude,
        position.longitude,
      );
      if (events.isNotEmpty)
      {
        setState(()
        {
          nearbyEvent = events.first;
        });
        _showNearbyEventPopup(events.first);
      }
    }
    catch(e)
    {
      print("Nearby event error: $e");
    }
  }


  Future<void> _loadBabies() async
  {
    final userId = auth.currentUser!.uid;

    final snapshot = await FirebaseFirestore.instance
        .collection("baby_profiles")
        .where("userId", isEqualTo: userId)
        .get();

    babies = snapshot.docs.map<Map<String, dynamic>>((doc)
    {
      final data = doc.data();
      return
        {
          "id": doc.id,
          "name": doc.get("name").toString(),
          "dob": (data["dob"] ?? "").toString(),
          "imageBase64": (data["imageBase64"] ?? "").toString(),
          "weight": (data["weight"] ?? "").toString(),
          "height": (data["height"] ?? "").toString(),
          "initialWeight": (data["initialWeight"] ?? "").toString(),
        };
    }).toList();
    if (babies.isNotEmpty)
    {
      final currentId = SelectedBabyService.selectedBabyId.value;

      final picked = babies.firstWhere((b) => b["id"] == currentId,
        orElse: () => babies.first,
      );

      SelectedBabyService.selectedBabyId.value = picked["id"];
      SelectedBabyService.selectedBabyName.value = picked["name"];
    }
    else
    {
      SelectedBabyService.selectedBabyId.value = null;
      SelectedBabyService.selectedBabyName.value = "";
    }

    setState(() {

    });
    await _homeSummary();
    await _checkSmartCareAlert();
    await _loadHomeAlerts();
  }

  Future<void> _homeSummary() async
  {
    try
    {
      final babyId = selectedBabyId;

      if (babyId == null)
      {
        setState(() {
          lastFeed = "No Profile made";
          lastSleep = "No Profile made";
          lastNappy = "No Profile made";
          lastTemp = "No Profile made";
        });
        return;
      }

      final userId = auth.currentUser!.uid;
      final feed = await _latestLog(
        path: "users/$userId/tracking/$babyId/feedings",
        labelBuilder: (data)
        {
          final time = _formatIsoTime(data["time"]);
          final type = (data["type"] ?? "bottle").toString();
          String summary = "";

          if (type == "breast")
          {
            final side = (data["side"] ?? "").toString();
            final mins = data["durationMinutes"] ?? 0;
            summary = "Breast ($side) ${mins}m";
          }
          else if (type == "solids")
          {
            final food = (data["food"] ?? "").toString();
            summary = "Solids: $food";
          }
          else
          {
            final amount = (data["amount"] ?? "").toString();
            summary = "$amount ml";
          }

          if ( time.isNotEmpty)
          {
            return "$summary at $time";
          }
          return time;
        },
      );
      lastFeedTime = await _latestLogTime(
        "users/$userId/tracking/$babyId/feedings",
      );

      final nappy = await _latestLog(
        path: "users/$userId/tracking/$babyId/nappies",
        labelBuilder: (data)
        {
          final type = (data["type"] ?? "").toString();
          final time = _formatIsoTime(data["time"]);

          if (type.isNotEmpty && time.isNotEmpty)
          {
            return "$type • $time";
          }
          if (type.isNotEmpty)
          {
            return type;
          }
          return time;
        },
      );
      lastNappyTime = await _latestLogTime(
        "users/$userId/tracking/$babyId/nappies",
      );

      final sleep = await _latestLog(
        path: "users/$userId/tracking/$babyId/sleeps",
        timekey: "endTime",
        labelBuilder: (data)
        {
          final mins = data["durationMinutes"] is int
              ? data["durationMinutes"]
              : int.tryParse(data["durationMinutes"].toString()) ?? 0;

          final h = mins ~/ 60;
          final m = mins % 60;

          if (h == 0)
            return "${m}m";

          if (m == 0)
            return "${h}h";

          return "${h}h ${m}m";
        },
      );

      lastSleepEndTime = await _latestLogTime(
        "users/$userId/tracking/$babyId/sleeps",
        timeKey: "endTime",
      );

      final temp = await _latestLog(
        path: "users/$userId/tracking/$babyId/temperatures",
        labelBuilder: (data)
        {
          final value = (data["value"] ?? "").toString();
          final time = _formatIsoTime(data["time"]);

          if (value.isNotEmpty && time.isNotEmpty)
          {
            return "$value °C • $time";
          }
          if (value.isNotEmpty)
          {
            return "$value °C";
          }
          return time;
        },
      );

      setState(() {
        lastFeed = feed ?? "Not recorded";
        lastSleep = sleep ?? "Not recorded";
        lastNappy = nappy ?? "Not recorded";
        lastTemp = temp ?? "Not recorded";

        final baby = babies.firstWhere((b) => b["id"] == babyId, orElse: () => <String, dynamic>{},
        );

        currentWeight = baby["weight"] != null && baby["weight"].toString().isNotEmpty
            ? "${baby["weight"]} kg"
            : "Not recorded";

        final weightStr = baby["weight"]?.toString();
        currentWeightVal = double.tryParse(weightStr ?? "");

        final createdWeightStr = baby["initialWeight"]?.toString();
        firstWeight = double.tryParse(createdWeightStr ?? "");

        currentHeight = baby["height"] != null && baby["height"].toString().isNotEmpty
            ? "${baby["height"]} cm"
            : "Not recorded";

        if (currentWeightVal != null && firstWeight != null)
        {
          final diff = currentWeightVal! - firstWeight!;
          if (diff > 0)
          {
            growthInsight = "Gaining weight (+${diff.toStringAsFixed(1)} kg)";
          }
          else if (diff < 0)
          {
            growthInsight = "Weight decrease (${diff.toStringAsFixed(1)} kg)";
          }
          else
          {
            growthInsight = "No weight change";
          }
        }
      });
    }
    catch (e)
    {
      setState(() {
        lastFeed = "Error";
        lastSleep = "Error";
      });
    }
  }

  Future<String?> _latestLog(
      {
        required String path,
        required String Function(Map<String, dynamic> data) labelBuilder,
        String timekey = "time",
      }) async
  {
    final snapshot = await db.child(path).get();

    if (!snapshot.exists)
    {
      return null;
    }

    final value = snapshot.value;

    Map<dynamic, dynamic> raw =
    {

    };

    if (value is List)
    {
      raw = {
        for (int i = 0; i < value.length; i++)
          if (value[i] != null) i: value[i]
      };
    }
    else if (value is Map)
    {
      raw = value;
    }

    final entries = raw.values
        .where((e) => e != null)
        .map((e) => Map<String, dynamic>.from(e))
        .where((e) => e[timekey] != null)
        .toList();

    if (entries.isEmpty)
    {
      return null;
    }

    entries.sort((a, b)
    {
      final at = DateTime.tryParse(a[timekey].toString()) ?? DateTime(1970);
      final bt = DateTime.tryParse(b[timekey].toString()) ?? DateTime(1970);
      return at.compareTo(bt);
    });

    final latest = entries.last;
    return labelBuilder(latest);
  }
  Future<void> _loadHomeAlerts() async
  {
    final babyId = selectedBabyId;
    if (babyId == null) return;

    final userId = auth.currentUser!.uid;
    final medSnap = await db
        .child("users/$userId/tracking/$babyId/medications")
        .get();

    if (medSnap.exists)
    {
      final data = Map<dynamic, dynamic>.from(medSnap.value as Map);

      final entries = data.values.toList();

      entries.sort((a, b)
      {
        final at = DateTime.tryParse(a["time"]) ?? DateTime(1970);
        final bt = DateTime.tryParse(b["time"]) ?? DateTime(1970);
        return at.compareTo(bt);
      });

      final latest = entries.last;

      latestMedication = "${latest["type"]} • ${latest["dose"]}";
      latestMedicationTime = _formatIsoTime(latest["time"]);
    }
    else
    {
      latestMedication = "Not recorded";
      latestMedicationTime = "";
    }
    final tempSnap = await db
        .child("users/$userId/tracking/$babyId/temperatures")
        .get();

    if (tempSnap.exists)
    {
      final data = Map<dynamic, dynamic>.from(tempSnap.value as Map);

      final entries = data.values.toList();

      entries.sort((a, b)
      {
        final at = DateTime.tryParse(a["time"]) ?? DateTime(1970);
        final bt = DateTime.tryParse(b["time"]) ?? DateTime(1970);
        return at.compareTo(bt);
      });

      final latest = entries.last;
      final temp = double.tryParse(latest["value"].toString());

      if (temp != null)
      {
        final result = _getHomeTemperatureStatus(temp);
        homeTempStatus = result["status"];
        homeTempColor = result["color"];
      }
    }
    else
    {
      homeTempStatus = "No temperature";
      homeTempColor = Colors.grey;
    }

    if (mounted)
    {
      setState(() {
      });
    }
  }

  String _formatIsoTime(dynamic iso)
  {
    if (iso == null)
    {
      return "";
    }

    final dt = DateTime.tryParse(iso.toString());

    if (dt == null)
    {
      return "";
    }

    final h = dt.hour.toString().padLeft(2, "0");
    final m = dt.minute.toString().padLeft(2, "0");
    return "$h:$m";
  }

  Future<DateTime?> _latestLogTime(
      String path,
      {
        String timeKey = "time",
      }) async
  {
    final snapshot = await db.child(path).get();
    if (!snapshot.exists) return null;
    final value = snapshot.value;

    Map<dynamic, dynamic> raw = {};

    if (value is List)
    {
      raw =
      {
        for (int i = 0; i < value.length; i++)
          if (value[i] != null) i: value[i]
      };
    } else if (value is Map)
    {
      raw = value;
    }

    final entries = raw.values
        .where((e) => e != null)
        .map((e) => Map<String, dynamic>.from(e))
        .where((e) => e[timeKey] != null)
        .toList();

    if (entries.isEmpty) return null;

    entries.sort((a, b)
    {
      final at = DateTime.tryParse(a[timeKey].toString()) ?? DateTime(1970);
      final bt = DateTime.tryParse(b[timeKey].toString()) ?? DateTime(1970);
      return at.compareTo(bt);
    });
    return DateTime.tryParse(entries.last[timeKey].toString());
  }

  Map<String, dynamic> _getHomeTemperatureStatus(double temp)
  {
    if (temp < 35.0)
    {
      return
        {
        "status": "Low Temperature",
        "color": Colors.blue,
      };
    }

    if (temp >= 38.0)
    {
      return
        {
        "status": "High Temperature",
        "color": Colors.red,
      };
    }

    if (temp >= 37.5)
    {
      return
        {
        "status": "Moderate Temperature",
        "color": Colors.orange,
      };
    }

    return
      {
      "status": "Normal Temperature",
      "color": Colors.green,
    };
  }

  Future<void> _checkSmartCareAlert() async
  {
    final now = DateTime.now();

    List<Map<String, dynamic>> alerts = [];
    String title = "";
    String message = "";

    if (lastFeedTime != null)
    {
      final hoursSinceFeed = now.difference(lastFeedTime!).inHours;

      if (hoursSinceFeed >= 4 && hoursSinceFeed < 200)
      {
        alerts.add({
          "icon": Icons.restaurant,
          "color": Colors.orange,
          "text": "Baby may be hungry. Last feed was ${hoursSinceFeed}h ago.",
        });
      }
    }

    if (lastNappyTime != null)
    {
      final hoursSinceNappy = now.difference(lastNappyTime!).inHours;

      if (hoursSinceNappy >= 3 && hoursSinceNappy < 200)
      {
        alerts.add({
          "icon": Icons.baby_changing_station,
          "color": Colors.blue,
          "text": "Baby may need a nappy change. Last change was ${hoursSinceNappy}h ago.",
        });
      }
    }

    if (lastSleepEndTime != null)
    {
      final hoursAwake = now.difference(lastSleepEndTime!).inHours;

      if (hoursAwake >= 2 && hoursAwake < 200)
      {
        alerts.add({
          "icon": Icons.nightlight_round,
          "color": Colors.deepPurple,
          "text": "Baby may be tired. Awake for ${hoursAwake}h.",
        });
      }
    }

    if (alerts.isNotEmpty)
    {
      title = "TinyTales";
      message = alerts.first["text"];
    }

    if (mounted)
    {
      final bool alertChanged = message != smartAlertMessage;
      setState(()
      {
        homeAlerts = alerts;
        smartAlertTitle = title;
        smartAlertMessage = message;
        if (title.isEmpty)
        {
          alertShown = false;
        }
        else if (alertChanged)
        {
          alertShown = false;
        }
      });

      if (title.isNotEmpty && message.isNotEmpty && !alertShown)
      {
        alertShown = true;
        _showWarning();
      }
    }
  }

  void _showWarning()
  {
    if (!mounted) return;
    showDialog(
      context: context, barrierDismissible: false, builder: (context)
      {

        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(smartAlertTitle, style: TextStyle(fontWeight: FontWeight.w800),),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.warning_amber_rounded, size: 40, color: Colors.orange),
              SizedBox(height: 10),
              Text(
                smartAlertMessage,
                style: TextStyle(fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: ()
              {
                Navigator.of(context).pop();
                setState(()
                {
                  currentPage = 2;
                });
              },
              child: Text("Tracking"),
            ),
          ],
        );
      },
    );
  }



  Widget _summary(String title, String value, IconData icon, String type)
  {

    Color accent;
    Color iconColor;

    if (type == "feed")
    {
      accent = Colors.orange.shade100;
      iconColor = Colors.orange.shade700;
    } else if (type == "sleep")
    {
      accent = Colors.deepPurple.shade100;
    } else if (type == "temperature")
    {
      accent = Colors.red.shade100;
    } else if (type == "nappy")
    {
      accent = Colors.blue.shade100;
    } else
    {
      accent = Colors.grey.shade200;
    }
    return GestureDetector(
      onTap: ()
      {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AnalyticsPage(type: type),
          ),
        );
      },
      child: Container(
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 24, color: accent),
          SizedBox(height: 10),
          Text(
            title,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(fontSize: 13, color: Colors.black54),
          ),

          SizedBox(height: 8),
          Text(
            "Tap for more info",
            style: TextStyle(
              fontSize: 12,
              color: Colors.black,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      ),
    );
  }
  Widget _growthSummary()
  {
    return GestureDetector(
      onTap: _openGrowthUpdate,
      onLongPress: _openGrowthChart,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.6,
        padding: EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.green.shade100, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black12, blurRadius: 8, offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.monitor_weight, size: 24, color: Colors.green),
            SizedBox(height: 10),
            Text(
              "Growth", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 6),
            Text(
              "Weight: $currentWeight", style: TextStyle(fontSize: 13, color: Colors.black54),
            ),
            Text(
              "Height: $currentHeight", style: TextStyle(fontSize: 13, color: Colors.black54),
            ),
            Text(
              growthInsight,
              style: TextStyle(
                fontSize: 12,
                color: Colors.green,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8),
            Text(
              "Tap to track ~ Press to view",
              style: TextStyle(
                fontSize: 12,
                color: Colors.black,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openGrowthUpdate()
  {
    if (selectedBabyId == null)
    {
      return;
    }

    final weightController = TextEditingController(
      text: currentWeight.replaceAll(" kg", ""),
    );

    final heightController = TextEditingController(
      text: currentHeight.replaceAll(" cm", ""),
    );
    showDialog(
      context: context,
      builder: (context)
      {
        return AlertDialog(
          title: Text("Update Growth"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: weightController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(labelText: "Weight kg"),
              ),
              TextField(
                controller: heightController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(labelText: "Height cm"),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: ()
              {
                Navigator.pop(context);
              },
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () async
              {
                final weight = weightController.text.trim();
                final height = heightController.text.trim();

                if (double.tryParse(weight) == null || double.tryParse(height) == null)
                {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Weight and height must be numbers")),
                  );
                  return;
                }
                final docRef = FirebaseFirestore.instance
                    .collection("baby_profiles")
                    .doc(selectedBabyId);
                final doc = await docRef.get();
                Map<String, dynamic> updateData = {
                  "weight": weight,
                  "height": height,
                };
                final existingData = doc.data() as Map<String, dynamic>;
                final oldWeight = (existingData["weight"] ?? "").toString();

                if (!existingData.containsKey("initialWeight"))
                {
                  updateData["initialWeight"] = oldWeight.isNotEmpty ? oldWeight : weight;
                }

                await docRef.update(updateData);
                Navigator.pop(context);
                final userId = auth.currentUser!.uid;

                await FirebaseDatabase.instance
                    .ref()
                    .child("users/$userId/tracking/$selectedBabyId/growth")
                    .push()
                    .set({
                  "weight": weight,
                  "height": height,
                  "time": DateTime.now().toIso8601String(),
                });
                await _loadBabies();
                await _homeSummary();

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Growth updated")),
                );
              },
              child: Text("Save"),
            ),
          ],
        );
      },
    );
  }

  void _openGrowthChart()
  {
    if (selectedBabyId == null || firstWeight == null || currentWeightVal == null)
    {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("No growth chart available yet. Update growth first."),
        ),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GrowthChartPage(
          babyId: selectedBabyId!,
          initialWeight: firstWeight!,
          currentWeight: currentWeightVal!,
        ),
      ),
    );
  }


  void _showNearbyEventPopup(CommunityEvent event)
  {
    WidgetsBinding.instance.addPostFrameCallback((_)
    {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.blueAccent,
          duration: Duration(seconds: 9),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.fromLTRB(16, 0, 16, 90),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          content: Row(
            children: [
              Icon(Icons.event, color: Colors.white),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  "Nearby Event: ${event.title}",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          action: SnackBarAction(
            label: "VIEW",
            textColor: Colors.white,
            onPressed: ()
            {
              setState(()
              {
                currentPage = 3;
              });
            },
          ),
        ),
      );
    });
  }
  Widget _smartSummaryCard()
  {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Color(0xFFFFFBFF),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.purple.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.notifications_active,
                  color: Colors.purple,
                  size: 20,
                ),
              ),
              SizedBox(width: 10),

              Text(
                "Alerts",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                ),
              ),
            ],
          ),

          SizedBox(height: 18),

          if (homeAlerts.isEmpty)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 20,
                ),
                SizedBox(width: 8),

                Expanded(
                  child: Text(
                "Everything looks good right now.",
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.black87,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: homeAlerts.map<Widget>((alert)
              {
                return Padding(
                  padding: EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        alert["icon"],
                        color: alert["color"],
                        size: 20,
                      ),

                      SizedBox(width: 8),

                      Expanded(
                        child: Text(
                          alert["text"],
                          style: TextStyle(
                            fontSize: 13, color: Colors.black87, fontWeight: FontWeight.w500,),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),

          SizedBox(height: 12),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.thermostat,
                color: homeTempColor,
                size: 20,
              ),

              SizedBox(width: 8),

              Expanded(
                child: Text(
                  homeTempStatus,
                  style: TextStyle(
                    fontSize: 13,
                    color: homeTempColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 12),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.medication,
                color: Colors.teal,
                size: 20,
              ),

              SizedBox(width: 8),

              Expanded(
                child: Text(
                  latestMedicationTime.isNotEmpty
                      ? "$latestMedication at $latestMedicationTime"
                      : latestMedication,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _babyAvatar()
  {
    final baby = babies.firstWhere((b) => b["id"] == selectedBabyId, orElse: () => <String, dynamic>{},);

    final imageBase64 = (baby["imageBase64"] ?? "").toString();

    return CircleAvatar(
      radius: 24,
      backgroundColor: Colors.purple.shade100,
      backgroundImage: imageBase64.isNotEmpty
          ? MemoryImage(base64Decode(imageBase64))
          : null,
      child: imageBase64.isEmpty
          ? Icon(Icons.child_care, color: Colors.purple, size: 24)
          : null,
    );
  }




  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF7F6FB),
      appBar: AppBar(
        backgroundColor: Color(0xFFF7F6FB),
        leading:  IconButton(
          icon: Icon(Icons.person),
          onPressed: toProfile,
        ),
        actions: [
          IconButton(onPressed: signUserOut, icon: const Icon(Icons.logout)),
        ],
      ),
      body: pages[currentPage],

      bottomNavigationBar: Container(
        color: Colors.black,
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            child: GNav(
              backgroundColor: Colors.black,
              color: Colors.white,
              activeColor: Colors.white,
              tabBackgroundColor: Colors.purple,
              gap: 4,
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              textSize: 12,
              tabs: [
                GButton(
                  icon: Icons.home,
                  text: 'Home',
                ),
                GButton(icon: Icons.info,
                  text: 'Insights',
                ),
                GButton(icon: Icons.track_changes,
                  text: 'Tracking',
                ),
                GButton(icon: Icons.people,
                  text: 'Community',
                ),
                  GButton(icon: Icons.flag,
                    text: 'Milestones',
                  ),
              ],
              onTabChange: (int index)
              {
                if (index >= 0 && index < pages.length)
                {
                  if (index == 0)
                  {
                    _homeSummary();
                    _checkSmartCareAlert();
                    _loadHomeAlerts();
                  }

                  setState(() {
                    currentPage = index;
                  });
                }
              },
            ),
          ),
        ),
      ),
    );
  }
}

