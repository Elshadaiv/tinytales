import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fl_chart/fl_chart.dart';

class AnalyticsPage extends StatefulWidget
{
  final String type;
  AnalyticsPage({super.key,
  required this.type
  });

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage>
{
  String selectedMetric = "Feeding";
  String selectedRange = "7 Days";


  final List<String> ranges = [
    "7 Days",
    "30 Days",
    "All",
  ];

  final auth = FirebaseAuth.instance;
  final db = FirebaseDatabase.instance.ref();

  List<Map<String, dynamic>> babies = [

  ];
  String? selectedBabyId;

  List<FlSpot> feedingSpots = [
  ];
  List<String> feedingLabels = [
  ];

  bool isLoading = true;


  @override
  void initState()
  {
    super.initState();

    if (widget.type == "feed")
    {
      selectedMetric = "Feeding";
    }
    else if (widget.type == "sleep")
    {
      selectedMetric = "Sleep";
    }
    else if (widget.type == "nappy")
    {
      selectedMetric = "Nappy";
    }
    else if (widget.type == "temperature")
    {
      selectedMetric = "Temperature";
    }
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
      await _loadFeedingData();
    }

    if (mounted)
    {
      setState(() {

      });
    }
  }

  Widget _metricButton(String label)
  {
    final bool isSelected = selectedMetric == label;
    return GestureDetector(
      onTap: ()
      {
        setState(()
        {
          selectedMetric = label;
        });
        if (label == "Feeding")
        {
          _loadFeedingData();
        }
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.purple : Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black12, blurRadius: 4, offset: Offset(0, 2),),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87, fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _rangeButton(String label)
  {
    final bool isSelected = selectedRange == label;
    return GestureDetector(
      onTap: () async
      {
        setState(()
        {
          selectedRange = label;
        });
        await _loadFeedingData();
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.purple : Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(color: isSelected ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }


  Future<void> _loadFeedingData() async
  {
    if (selectedBabyId == null)
    {
      return;
    }

    setState(()
    {
      isLoading = true;
    });

    final userId = auth.currentUser!.uid;

    final snapshot = await db
        .child("users/$userId/tracking/$selectedBabyId/feedings")
        .get();

    feedingSpots = [];
    feedingLabels = [];

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
        "amount": e["amount"],
        "time": e["time"],
      })
          .where((e) => e["time"] != null)
          .toList();

      entries.sort((a, b)
      {
        final at = DateTime.tryParse(a["time"].toString()) ?? DateTime(1970);
        final bt = DateTime.tryParse(b["time"].toString()) ?? DateTime(1970);
        return at.compareTo(bt);
      });

      List<Map<String, dynamic>> filtered = entries;

      if (selectedRange == "7 Days" && entries.length > 7)
      {
        filtered = entries.sublist(entries.length - 7);
      }
    else if (selectedRange == "30 Days" && entries.length > 30)
    {
      filtered = entries.sublist(entries.length - 30);
    }

      for (int i = 0; i < filtered.length; i++)
      {
        final amount = double.tryParse(filtered[i]["amount"].toString()) ?? 0;
        final time = DateTime.tryParse(filtered[i]["time"].toString());

        feedingSpots.add(FlSpot(i.toDouble(), amount));

        if (time != null)
        {
          feedingLabels.add("${time.day}/${time.month}");
        }
        else
        {
          feedingLabels.add("${i + 1}");
        }
      }
    }

    if (mounted)
    {
      setState(()
      {
        isLoading = false;
      });
    }
  }


  @override
  Widget build(BuildContext context)
  {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      appBar: AppBar(backgroundColor: Colors.grey[300],
        title: Text(
          "$selectedMetric Analytics",
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            DropdownButton<String>(
              value: selectedBabyId,
              hint: Text("Select Baby"),
              onChanged: (val) async
              {
                if (val == null)
                {
                  return;
                }
                setState(()
                {
                  selectedBabyId = val;
                });
                await _loadFeedingData();
              },
              items: babies.map<DropdownMenuItem<String>>((baby)
              {
                return DropdownMenuItem<String>(
                  value: baby["id"],
                  child: Text(baby["name"]),
                );
              }).toList(),
            ),

            SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _rangeButton("7 Days"),
                SizedBox(width: 10),
                _rangeButton("30 Days"),
                SizedBox(width: 10),
                _rangeButton("All"),
              ],
            ),

            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12, blurRadius: 6, offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    selectedMetric,
                    style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text("Range: ""$selectedRange",
                    style: TextStyle(color: Colors.black54,),
                  ),
                  SizedBox(height: 16),

                  Container(
                    height: 260,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(16),
                    ),
                      child: selectedMetric != "Feeding"
                          ? Center(
                        child: Text("No Graph yet", style:
                        TextStyle(
                            color: Colors.black54,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    : isLoading
                        ? Center(child: CircularProgressIndicator(color: Colors.purple),
                    )
                        : feedingSpots.isEmpty
                        ? Center(
                      child: Text("No feeding data yet", style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    )
                        : Padding(
                      padding: EdgeInsets.all(12),
                      child: LineChart(
                        LineChartData(
                          gridData: FlGridData(show: true),
                          borderData: FlBorderData(show: false),
                          titlesData: FlTitlesData(
                            topTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),),
                            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false),),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true, getTitlesWidget: (value, meta)
                                {
                                  final index = value.toInt();
                                  if (index < 0 || index >= feedingLabels.length)
                                  {
                                    return SizedBox();
                                  }
                                  return Text(
                                    feedingLabels[index], style: TextStyle(fontSize: 10),
                                  );
                                },
                              ),
                            ),
                          ),
                          lineBarsData: [
                            LineChartBarData(
                              spots: feedingSpots,
                              isCurved: true, barWidth: 3, dotData: FlDotData(show: true),),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 16),

          ],
        ),
      ),
    );
  }
}