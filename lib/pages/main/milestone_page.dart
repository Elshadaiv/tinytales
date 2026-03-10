import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:tinytales/pages/milestones/milestone_checklist3m.dart';
import 'package:tinytales/pages/milestones/milestone_checklist6m.dart';
import 'package:tinytales/pages/milestones/milestone_checklist9m.dart';
import '../../services/notification_service.dart';
import '../milestones/milestone_checklist12m.dart';
import 'package:tinytales/pages/milestones/milestones_videos.dart';




class milestone_page extends StatefulWidget {
  milestone_page({super.key});

  @override
  State<milestone_page> createState() => _milestone_pageState();

}

class _milestone_pageState extends State<milestone_page>
{
  final auth = FirebaseAuth.instance;

  final int total3MonthsItems = 15;
  final int total6MonthsItems = 14;
  final int total9MonthsItems = 12;
  final int total12MonthsItems = 11;


  bool showVideos = false;

  String? selectedBabyId;
  List<Map<String, dynamic>> babies = [

  ];

  DateTime? selectedBabyDob;
  int babyAgeMonths = 0;

  bool complete3Months = false;
  bool complete6Months = false;
  bool complete9Months = false;



  final List<Map<String, String>> milestones =
  [
    {
      "title": "3 Months", "image": "assets/milestones/Badge3.png",
    },
    {
      "title": "6 Months", "image": "assets/milestones/Badge6.png",
    },
    {
      "title": "9 Months", "image": "assets/milestones/Badge9.png",
    },
    {
      "title": "12 Months", "image": "assets/milestones/Badge12.png",
    },
  ];

   @override
   void initState()
   {
     super.initState();
     _firstbaby();
   }

  Future<void> _firstbaby() async
  {
    final user = auth.currentUser;

    if (user == null)
    {
      return;
    }
    final snapshot = await FirebaseFirestore.instance
        .collection("baby_profiles")
        .get();

    babies = snapshot.docs.map((doc)
    {
      return
        {
          "id": doc.id,
          "name": doc.get("name").toString(),
          "dob": doc.get("dob").toString(),
        };
    }).toList();
    if (babies.isNotEmpty)
    {
      if (selectedBabyId == null)
      {
        await _setSelectedBaby(babies.first["id"]);
        Future.delayed(Duration(seconds: 2), ()
        {
          NotificationService.showMilestoneNotification();
        });
      }
    }
    else
    {
      if (mounted) {
        setState(() {});
      }
    }
  }

  Future<void> _setSelectedBaby(String babyId) async
  {
    selectedBabyId = babyId;

    final selectedBaby = babies.firstWhere((b) => b["id"].toString() == babyId,);

    final dobText = selectedBaby["dob"]?.toString() ?? "";
    selectedBabyDob = _parseDob(dobText);

    if (selectedBabyDob != null)
    {
      babyAgeMonths = _calculateAgeInMonths(selectedBabyDob!);
    }
    else
    {
      babyAgeMonths = 0;
    }

    await _loadMilestoneLocks();

    if (mounted)
    {
      setState(()
      {
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

  Future<bool> _isMilestoneComplete(String docId, int totalItems) async
  {
    if (selectedBabyId == null)
    {
      return false;
    }

    final snap = await FirebaseFirestore.instance
        .collection("baby_profiles")
        .doc(selectedBabyId)
        .collection("milestones")
        .doc(docId)
        .get();

    if (!snap.exists)
    {
      return false;
    }

    final data = snap.data() ?? {};
    final raw = data["completed"];

    if (raw is! Map)
    {
      return false;
    }
    final done = raw.values.where((v) => v == true).length;
    return done >= totalItems;
  }

  Future<void> _loadMilestoneLocks() async
  {
    if (selectedBabyId == null)
    {
      return;
    }

    complete3Months = await _isMilestoneComplete("3_months", total3MonthsItems);
    complete6Months = await _isMilestoneComplete("6_months", total6MonthsItems);
    complete9Months = await _isMilestoneComplete("9_months", total9MonthsItems);

    if (mounted)
    {
      setState(() {});
    }
  }

    @override
  Widget build(BuildContext context) {
      final bool videosLocked = babyAgeMonths < 4;
      return Scaffold(
        backgroundColor: Colors.grey[300],
        appBar: AppBar(
          backgroundColor: Colors.grey[300],
          title: Text(
            "Milestones",
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        actions: [
          if (babies.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(right: 12),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedBabyId,
                  onChanged: (val) async
                  {
                    if (val == null)
                    {
                      return;
                    }
                    await _setSelectedBaby(val);
                  },
                  items: babies.map<DropdownMenuItem<String>>((b)
                  {
                    return DropdownMenuItem<String>(
                      value: b["id"] as String,
                      child: Text(b["name"].toString()),
                    );
                  }).toList(),
                ),
              ),
            ),
        ],
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
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 6,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                    child: Text("No baby profile found."),
                ),

                    if (selectedBabyId != null)
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 6,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(child: Text(
                            "Need Help?",
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          ),

                          ElevatedButton(
                            onPressed:()
                            {
                              setState(() {
                                showVideos = !showVideos;
                              });
                            },
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
                            child: Text(showVideos ? "Hide" : "Videos"),
                          ),
                        ],
                      ),

                      if (showVideos) ...[
                        SizedBox(height: 12,),
                          GestureDetector(
                          onTap: ()
                          {
                            if(videosLocked)
                              {
                                return;
                              }
                            Navigator.push(
                            context,
                            MaterialPageRoute(
                            builder: (_) => MilestoneVideoPage
                          (
                          title: "4-6 Months Rolling", youtubeUrl: "https://www.youtube.com/watch?v=Dqsdem54PsA",
                            ),
                          ),
                          );
                          },
                        child: Container(
                          padding: EdgeInsets.all(12),
                          decoration:  BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              Expanded(child: Text(
                            "4-6 Months Rolling",
                                style: TextStyle(color: Colors.black54),
                          ),
                        ),
                        Icon(Icons.play_circle_fill, color: Colors.black54),
                      ],
                          ),
                  ),
                ),

                        SizedBox(height: 10),

                        GestureDetector(
                          onTap: ()
                          {
                            if(videosLocked)
                            {
                              return;
                            }
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => MilestoneVideoPage
                                  (
                                  title: "4-6 Months Sitting", youtubeUrl: "https://www.youtube.com/watch?v=CGG4iXdXEQk",
                                ),
                              ),
                            );
                          },
                          child: Container(
                            padding: EdgeInsets.all(12),
                            decoration:  BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              children: [
                                Expanded(child: Text(
                                  "4-6 Months Sitting",
                                  style: TextStyle(color: Colors.black54),
                                ),
                                ),
                                Icon(Icons.play_circle_fill, color: Colors.black54),
                              ],
                            ),
                          ),
                        ),
                      ],
              ],
                  ),
              ),
              SizedBox(height: 14),

              Expanded(
                child: Center(
                  child: SizedBox(
                    height: 400,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: milestones.length,
                      itemBuilder: (context, index)
                      {
                        final item = milestones[index];
                        final bool ThreeMonths = index == 0;
                        final bool SixMonths = index == 1;
                        final bool NineMonths = index == 2;
                        final bool TwelveMonths = index == 3;


                        final bool lock3 = babyAgeMonths < 3;
                        final bool lock6 = babyAgeMonths < 6;
                        final bool lock9 = babyAgeMonths < 9;
                        final bool lock12 = babyAgeMonths < 12;

                        final bool isLocked =
                            (ThreeMonths && lock3) ||
                                (SixMonths && lock6) ||
                                (NineMonths && lock9) ||
                                (TwelveMonths && lock12);

                        return GestureDetector(

                          onTap: ()
                          {
                            if (selectedBabyId == null)
                            {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("no baby profile found.")),
                              );
                              return;
                            }

                            if(isLocked)
                              return;

                            if (index == 0)
                            {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => MilestoneCheckList3m(babyId: selectedBabyId!),
                                ),
                              );
                            }
                            else if (index == 1)
                            {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => MilestoneCheckList6m(babyId: selectedBabyId!),
                                ),
                              );
                            }

                            else if (index == 2)
                            {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => MilestoneCheckList9m(babyId: selectedBabyId!),
                                ),
                              );
                            }


                            else if (index == 3)
                            {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => MilestoneCheckList12m(babyId: selectedBabyId!),
                                ),
                              );
                            }
                          },

                          child: Stack(
                            children: [
                              Container(
                            width: 240,
                            margin: EdgeInsets.only(right: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 8, offset: Offset(0, 4),
                                ),
                              ],
                            ),
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                  if (ThreeMonths)
                              Padding(
                              padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
                          child: StreamBuilder<DocumentSnapshot>(

                            stream: FirebaseFirestore.instance
                                .collection("baby_profiles")
                                .doc(selectedBabyId)
                                .collection("milestones")
                                .doc("3_months")
                                .snapshots(),
                            builder: (context, snapshot)
                            {
                              int done = 0;
                              final int totalItems = total3MonthsItems;

                              if (snapshot.hasData && snapshot.data != null && snapshot.data!.exists)
                              {
                                final data = snapshot.data!.data() as Map<String, dynamic>? ??
                                    {

                                };
                                final raw = data["completed"];

                                if (raw is Map)
                                {
                                  done = raw.values.where((v) => v == true).length;
                                }
                              }

                              final progress = totalItems == 0 ? 0.0 : done / totalItems;

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "$done / $totalItems",
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.black54,
                                    ),
                                  ),
                                  SizedBox(height: 6),
                                  LinearProgressIndicator(
                                    value: progress,
                                    minHeight: 8,
                                    backgroundColor: Colors.grey[200],
                                    color: Colors.purple,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                                    if (SixMonths)
                                      Padding(
                                        padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
                                        child: StreamBuilder<DocumentSnapshot>
                                          (
                                          stream: FirebaseFirestore.instance
                                              .collection("baby_profiles")
                                              .doc(selectedBabyId)
                                              .collection("milestones")
                                              .doc("6_months")
                                              .snapshots(),
                                          builder: (context, snapshot)
                                          {
                                            int done = 0;
                                            final int totalItems = total6MonthsItems;

                                            if (snapshot.hasData && snapshot.data != null && snapshot.data!.exists)
                                            {
                                              final data = snapshot.data!.data() as Map<String, dynamic>? ?? {

                                              };
                                              final raw = data["completed"];
                                              if (raw is Map)
                                              {
                                                done = raw.values.where((v) => v == true).length;
                                              }
                                            }

                                            final progress = totalItems == 0 ? 0.0 : done / totalItems;

                                            return Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  "$done / $totalItems",
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w700,
                                                    color: Colors.black54,
                                                  ),
                                                ),
                                                SizedBox(height: 6),
                                                LinearProgressIndicator(
                                                  value: progress,
                                                  minHeight: 8,
                                                  backgroundColor: Colors.grey[200],
                                                  color: Colors.purple,
                                                  borderRadius: BorderRadius.circular(10),
                                                ),
                                              ],
                                            );
                                          },
                                        ),
                                      ),
                                    if (NineMonths)
                                      Padding(
                                        padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
                                        child: StreamBuilder<DocumentSnapshot>(
                                          stream: FirebaseFirestore.instance
                                              .collection("baby_profiles")
                                              .doc(selectedBabyId)
                                              .collection("milestones")
                                              .doc("9_months")
                                              .snapshots(),
                                          builder: (context, snapshot)
                                          {
                                            int done = 0;
                                            final int totalItems = total9MonthsItems;

                                            if (snapshot.hasData && snapshot.data != null && snapshot.data!.exists)
                                            {
                                              final data = snapshot.data!.data() as Map<String, dynamic>? ?? {

                                              };
                                              final raw = data["completed"];

                                              if (raw is Map)
                                              {
                                                done = raw.values.where((v) => v == true).length;
                                              }
                                            }

                                            final progress = totalItems == 0 ? 0.0 : done / totalItems;

                                            return Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  "$done / $totalItems",
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w700,
                                                    color: Colors.black54,
                                                  ),
                                                ),
                                                SizedBox(height: 6),
                                                LinearProgressIndicator(
                                                  value: progress,
                                                  minHeight: 8,
                                                  backgroundColor: Colors.grey[200],
                                                  color: Colors.purple,
                                                  borderRadius: BorderRadius.circular(10),
                                                ),
                                              ],
                                            );
                                          },
                                        ),
                                      ),
                                    if (TwelveMonths)
                                      Padding(
                                        padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
                                        child: StreamBuilder<DocumentSnapshot>(
                                          stream: FirebaseFirestore.instance
                                              .collection("baby_profiles")
                                              .doc(selectedBabyId)
                                              .collection("milestones")
                                              .doc("12_months")
                                              .snapshots(),
                                          builder: (context, snapshot)
                                          {
                                            int done = 0;
                                            final int totalItems = total12MonthsItems;

                                            if (snapshot.hasData && snapshot.data != null && snapshot.data!.exists)
                                            {
                                              final data = snapshot.data!.data() as Map<String, dynamic>? ?? {

                                              };
                                              final raw = data["completed"];

                                              if (raw is Map)
                                              {
                                                done = raw.values.where((v) => v == true).length;
                                              }
                                            }

                                            final progress = totalItems == 0 ? 0.0 : done / totalItems;

                                            return Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  "$done / $totalItems",
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w700,
                                                    color: Colors.black54,
                                                  ),
                                                ),
                                                SizedBox(height: 6),
                                                LinearProgressIndicator(
                                                  value: progress,
                                                  minHeight: 8,
                                                  backgroundColor: Colors.grey[200],
                                                  color: Colors.purple,
                                                  borderRadius: BorderRadius.circular(10),
                                                ),
                                              ],
                                            );
                                          },
                                        ),
                                      ),
                                    Expanded(
                                  child: Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(16),
                                    child: Image.asset(
                                      item["image"]!,
                                      width: 160,
                                      height: 160,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                                ),
                                Padding(
                                  padding: EdgeInsets.only(bottom: 16),
                                  child: Text(
                                    item["title"]!,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                              if (isLocked)
                                Positioned.fill(
                                  child: Container(
                                    margin: EdgeInsets.only(right: 16),
                                    decoration: BoxDecoration(
                                      color: Colors.black12,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Center(
                                      child: Icon(
                                        Icons.lock,
                                        size: 150,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
}