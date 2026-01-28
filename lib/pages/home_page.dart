
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:tinytales/pages/community_page.dart';
import 'package:tinytales/pages/insights_page.dart';
import 'package:tinytales/pages/profile_page.dart';
import 'package:tinytales/pages/tracking_page.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:tinytales/pages/milestone_page.dart';




class  HomePage extends StatefulWidget {
   HomePage({super.key});


   @override
   State<HomePage> createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  final user = FirebaseAuth.instance.currentUser;
  final db = FirebaseDatabase.instance.ref();
  final auth = FirebaseAuth.instance;

  int currentPage = 0;

  String lastFeed = "";
  String lastSleep = "";
  String lastNappy = "";

  List<Map<String, String>> babies = [];
  String? selectedBabyId;
  String selectedBabyName = "";


  List<Widget> get pages
  {
    return [
      Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 10),
        Row(
          children: [
            Text(
              "Welcome Back!",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            Spacer(),

            if (babies.isEmpty)
              Text("No babies")
            else
              DropdownButton<String>(
                value: selectedBabyId,
                onChanged: (val)
                {
                  if (val == null) return;

                  final picked = babies.firstWhere(
                        (b) => b["id"] == val, orElse: () => {"id": val, "name": ""},
                  );
                  setState(() {
                    selectedBabyId = val;
                    selectedBabyName = (picked["name"] ?? "").toString();
                  });
                  _homeSummary();
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

            SizedBox(height: 16),

            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                children: [
                  _summary("Last feed", lastFeed, Icons.restaurant),
                  _summary("Last sleep", lastSleep, Icons.bedtime),
                  _summary("Milestones", "//This will show what level there at in the milestone", Icons.flag),
                  _summary("Last Nappy",lastNappy,  Icons.baby_changing_station),
                ],
              ),
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
        };
    }).toList();
    if (babies.isNotEmpty)
    {
      selectedBabyId ??= babies.first["id"];
      selectedBabyName = babies.first["name"].toString();
    }

    setState(() {

    });
    await _homeSummary();
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
        });
        return;
      }

      final userId = auth.currentUser!.uid;
      final feed = await _latestLog(
        path: "users/$userId/tracking/$babyId/feedings",
        labelBuilder: (data)
        {
          final amount = (data["amount"] ?? "").toString();
          final time = _formatIsoTime(data["time"]);

          if (amount.isNotEmpty && time.isNotEmpty)
          {
            return "$amount ml at $time";
          }
          if (amount.isNotEmpty)
          {
            return "$amount ml";
          }
          return time;
        },
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

      final sleep = await _latestLog(
        path: "users/$userId/tracking/$babyId/sleeps",
        labelBuilder: (data)
        {
          final duration = (data["duration"] ?? "").toString();
          final time = _formatIsoTime(data["time"]);

          if (duration.isNotEmpty && time.isNotEmpty)
          {
            return "$duration at $time";
          }
          if (duration.isNotEmpty)
          {
            return duration;
          }
          return time;
        },
      );
      setState(() {
        lastFeed = feed ?? "Not recorded";
        lastSleep = sleep ?? "Not recorded";
        lastNappy = nappy ?? "Not recorded";
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
        .where((e) => e["time"] != null)
        .toList();

    if (entries.isEmpty)
    {
      return null;
    }

    entries.sort((a, b)
    {
      final at = DateTime.tryParse(a["time"].toString()) ?? DateTime(1970);
      final bt = DateTime.tryParse(b["time"].toString()) ?? DateTime(1970);
      return at.compareTo(bt);
    });

    final latest = entries.last;
    return labelBuilder(latest);
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

  Widget _summary(String title, String value, IconData icon) {
    return Container(
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
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
          Icon(icon, size: 24),
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
        ],
      ),
    );
  }




  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      appBar: AppBar(
        backgroundColor: Colors.grey[300],
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
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 17),
            child: GNav(
              backgroundColor: Colors.black,
                color: Colors.white,
                activeColor: Colors.white,
                tabBackgroundColor: Colors.purple,
                gap: 8,
                padding: const EdgeInsets.all(16),
                tabs: const [
                GButton(icon: Icons.home,
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
                onTabChange: (int index) {
                if (index >= 0 && index < pages.length) {
                  setState(() {
                    currentPage = index;
                  });

                }
                }
            ),
          ),
        ),
      ),
    );
  }
}

