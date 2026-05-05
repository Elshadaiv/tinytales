import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fl_chart/fl_chart.dart';
import 'selected_baby_service.dart';

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
    "24 Hours",
    "7 Days",
    "30 Days",
    "All",
  ];

  final auth = FirebaseAuth.instance;
  final db = FirebaseDatabase.instance.ref();

  String? get selectedBabyId => SelectedBabyService.selectedBabyId.value;

  List<FlSpot> feedingSpots = [
  ];
  List<String> feedingLabels = [
  ];
  List<FlSpot> sleepSpots = [
  ];
  List<String> sleepLabels = [
  ];
  List<FlSpot> nappySpots = [
  ];
  List<String> nappyLabels = [
  ];
  List<FlSpot> temperatureSpots = [
  ];
  List<String> temperatureLabels = [
  ];

  bool isLoading = true;

  String sleepTodayText = "";
  String sleepSuggestedText = "";

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
    SelectedBabyService.selectedBabyId.addListener(_onSelectedBabyChanged);
    _loadSelectedMetric();
  }

  void _onSelectedBabyChanged() async
  {
    if (mounted)
    {
      await _loadSelectedMetric();
      setState(() {});
    }
  }

  @override
  void dispose()
  {
    SelectedBabyService.selectedBabyId.removeListener(_onSelectedBabyChanged);
    super.dispose();
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
        _loadSelectedMetric();
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
        await _loadSelectedMetric();
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

      final now = DateTime.now();

      final entries = raw.values.map((e) =>
      {
        "type": e["type"],
        "amount": e["amount"],
        "time": e["time"],
      })
          .where((e)
      {
        final amount = double.tryParse(e["amount"].toString());
        return e["time"] != null && amount != null;
      })
          .toList();

      entries.sort((a, b)
      {
        final at = DateTime.tryParse(a["time"].toString()) ?? DateTime(1970);
        final bt = DateTime.tryParse(b["time"].toString()) ?? DateTime(1970);
        return at.compareTo(bt);
      });

      List<Map<String, dynamic>> filtered = entries;

      if (selectedRange == "24 Hours")
      {
        filtered = entries.where((e)
        {
          final time = DateTime.tryParse(e["time"].toString());

          if (time == null)
          {
            return false;
          }

          return now.difference(time).inHours <= 24;
        }).toList();
      }
      else if (selectedRange == "7 Days")
      {
        filtered = entries.where((e)
        {
          final time = DateTime.tryParse(e["time"].toString());

          if (time == null)
          {
            return false;
          }

          return now.difference(time).inDays <= 7;
        }).toList();
      }
      else if (selectedRange == "30 Days")
      {
        filtered = entries.where((e)
        {
          final time = DateTime.tryParse(e["time"].toString());

          if (time == null)
          {
            return false;
          }

          return now.difference(time).inDays <= 30;
        }).toList();
      }

      for (int i = 0; i < filtered.length; i++)
      {
        final amount = double.tryParse(filtered[i]["amount"].toString()) ?? 0;
        final time = DateTime.tryParse(filtered[i]["time"].toString());

        feedingSpots.add(FlSpot(i.toDouble(), amount));

        if (time != null)
        {
          final hour = time.hour.toString().padLeft(2, '0');
          final minute = time.minute.toString().padLeft(2, '0');

          if (selectedRange == "24 Hours")
          {
            feedingLabels.add("$hour:$minute");
          }
          else
          {
            feedingLabels.add("${time.day}/${time.month}");
          }
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
  Future<void> _loadSleepData() async
  {
    if (selectedBabyId == null)
    {
      return;
    }
    setState(() {
      isLoading = true;
    });

    final userId = auth.currentUser!.uid;
    final snapshot = await db.child("users/$userId/tracking/$selectedBabyId/sleeps").get();
    sleepSpots = [];
    sleepLabels = [];
    int totalSleepTodayMins = 0;

    if (snapshot.exists)
    {
      final data = snapshot.value;
      Map<dynamic, dynamic> raw = {};

      if (data is List)
      {
        raw = {
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
        "durationMinutes": e["durationMinutes"] ?? 0,
        "endTime": e["endTime"],
      })
          .where((e) => e["endTime"] != null)
          .toList();

      entries.sort((a, b)
      {
        final at = DateTime.tryParse(a["endTime"].toString()) ?? DateTime(1970);
        final bt = DateTime.tryParse(b["endTime"].toString()) ?? DateTime(1970);
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
        final int mins = filtered[i]["durationMinutes"] is int
            ? filtered[i]["durationMinutes"] as int
            : int.tryParse(filtered[i]["durationMinutes"].toString()) ?? 0;
        final hours = mins / 60.0;
        final time = DateTime.tryParse(filtered[i]["endTime"].toString());

        if (time != null)
        {
          final now = DateTime.now();

          if (time.year == now.year &&
              time.month == now.month &&
              time.day == now.day)
          {
            totalSleepTodayMins += mins;
          }
        }

        sleepSpots.add(FlSpot(i.toDouble(), hours));
        if (time != null)
        {
          final hour = time.hour.toString().padLeft(2, '0');
          final minute = time.minute.toString().padLeft(2, '0');

          if (selectedRange == "24 Hours")
          {
            sleepLabels.add("$hour:$minute");
          }
          else
          {
            sleepLabels.add("${time.day}/${time.month}");
          }
        }
        else
        {
          sleepLabels.add("${i + 1}");
        }
      }

      final h = totalSleepTodayMins ~/ 60;
      final m = totalSleepTodayMins % 60;

      sleepTodayText = "Today: ${h}h ${m}m slept";
      if (h < 11)
      {
        sleepSuggestedText = "Below recommended sleep (11–14h)";
      }
      else if (h > 14)
      {
        sleepSuggestedText = "Above typical sleep range";
      }
      else
      {
        sleepSuggestedText = "Within healthy sleep range";
      }    }
    if (mounted) setState(()
    {
      isLoading = false;
    });
  }

  Future<void> _loadNappyData() async
  {
    if (selectedBabyId == null)
    {
      return;
    }

    setState(() {
      isLoading = true;
    });

    final userId = auth.currentUser!.uid;
    final snapshot = await db.child("users/$userId/tracking/$selectedBabyId/nappies").get();

    nappySpots = [];
    nappyLabels = [];
    if (snapshot.exists)
    {
      final data = snapshot.value;
      Map<dynamic, dynamic> raw = {};

      if (data is List)
      {
        raw = {
          for (int i = 0; i < data.length; i++)
            if (data[i] != null) i: data[i]
        };
      }
      else if (data is Map)
      {
        raw = data;
      }
      final Map<String, int> perDay = {};

      for (final v in raw.values)
      {
        if (v == null) continue;
        final timeString = v["time"]?.toString();
        if (timeString == null) continue;

        final dt = DateTime.tryParse(timeString);
        if (dt == null) continue;

        final dayKey = "${dt.year}-${dt.month}-${dt.day}";
        perDay[dayKey] = (perDay[dayKey] ?? 0) + 1;
      }

      final sortedKeys = perDay.keys.toList()..sort();

      List<String> filteredKeys = sortedKeys;
      if (selectedRange == "7 Days" && sortedKeys.length > 7)
      {
        filteredKeys = sortedKeys.sublist(sortedKeys.length - 7);
      }
      else if (selectedRange == "30 Days" && sortedKeys.length > 30)
      {
        filteredKeys = sortedKeys.sublist(sortedKeys.length - 30);
      }

      for (int i = 0; i < filteredKeys.length; i++)
      {
        final key = filteredKeys[i];
        final parts = key.split("-");
        final label = parts.length >= 3 ? "${parts[2]}/${parts[1]}" : key;
        nappySpots.add(FlSpot(i.toDouble(), perDay[key]!.toDouble()));
        nappyLabels.add(label);
      }
    }

    if (mounted) setState(()
    {
      isLoading = false;
    });
  }

  Future<void> _loadTemperatureData() async
  {
    if (selectedBabyId == null)
    {
      return;
    }

    setState(() {
      isLoading = true;
    });

    final userId = auth.currentUser!.uid;
    final snapshot = await db.child("users/$userId/tracking/$selectedBabyId/temperatures").get();

    temperatureSpots = [];
    temperatureLabels = [];

    if (snapshot.exists)
    {
      final data = snapshot.value;
      Map<dynamic, dynamic> raw = {};

      if (data is List)
      {
        raw = {
          for (int i = 0; i < data.length; i++)
            if (data[i] != null) i: data[i]
        };
      }
      else if (data is Map)
      {
        raw = data;
      }

      final entries = raw.values.map((e) => {
        "value": e["value"],
        "time": e["time"],

      })
          .where((e) => e["time"] != null)
          .toList();

      entries.sort((a, b) {
        final at = DateTime.tryParse(a["time"].toString()) ?? DateTime(1970);
        final bt = DateTime.tryParse(b["time"].toString()) ?? DateTime(1970);
        return at.compareTo(bt);
      });

      final now = DateTime.now();

      List<Map<String, dynamic>> filtered = entries;

      if (selectedRange == "24 Hours")
      {
        filtered = entries.where((e)
        {
          final time = DateTime.tryParse(e["time"].toString());

          if (time == null)
          {
            return false;
          }

          return now.difference(time).inHours <= 24;
        }).toList();
      }
      else if (selectedRange == "7 Days")
      {
        filtered = entries.where((e)
        {
          final time = DateTime.tryParse(e["time"].toString());

          if (time == null)
          {
            return false;
          }

          return now.difference(time).inDays <= 7;
        }).toList();
      }
      else if (selectedRange == "30 Days")
      {
        filtered = entries.where((e)
        {
          final time = DateTime.tryParse(e["time"].toString());

          if (time == null)
          {
            return false;
          }

          return now.difference(time).inDays <= 30;
        }).toList();
      }

      for (int i = 0; i < filtered.length; i++)
      {
        final value = double.tryParse(filtered[i]["value"].toString()) ?? 0;
        final time = DateTime.tryParse(filtered[i]["time"].toString());

        temperatureSpots.add(FlSpot(i.toDouble(), value));
        if (time != null)
        {
          final hour = time.hour.toString().padLeft(2, '0');
          final minute = time.minute.toString().padLeft(2, '0');

          if (selectedRange == "24 Hours")
          {
            temperatureLabels.add("$hour:$minute");
          }
          else
          {
            temperatureLabels.add("${time.day}/${time.month}");
          }
        }
        else
        {
          temperatureLabels.add("${i + 1}");
        }      }
    }

    if (mounted) setState(()
    {
      isLoading = false;
    });
  }


  Future<void> _loadSelectedMetric() async
  {
    if (selectedMetric == "Feeding")
    {
      await _loadFeedingData();
    }
    else if (selectedMetric == "Sleep")
    {
      await _loadSleepData();
    }
    else if (selectedMetric == "Nappy")
    {
      await _loadNappyData();
    }
    else if (selectedMetric == "Temperature")
    {
      await _loadTemperatureData();
    }
  }


  @override
  Widget build(BuildContext context)
  {
    return Scaffold(
      backgroundColor:Color(0xFFF7F6FB),
      appBar: AppBar(backgroundColor: Color(0xFFF7F6FB),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _rangeButton("24 Hours"),
                SizedBox(width: 10),
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

                  if (selectedMetric == "Sleep") ...[
                    Text(
                      sleepTodayText,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.deepPurple,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      sleepSuggestedText,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                    SizedBox(height: 14),
                  ],

                  Container(
                    height: 260,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(16),
                    ),
                     child: isLoading
                    ? Center(child: CircularProgressIndicator(color: Colors.purple))
                          : _buildChartForMetric(),
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

  Widget _buildChartForMetric()
  {
    List<FlSpot> spots = [];
    List<String> labels = [];
    String emptyMessage = "";

    if (selectedMetric == "Feeding")
    {
      spots = feedingSpots;
      labels = feedingLabels;
      emptyMessage = "No feeding data yet";
    }
    else if (selectedMetric == "Sleep")
    {
      spots = sleepSpots;
      labels = sleepLabels;
      emptyMessage = "No sleep data yet";
    }
    else if (selectedMetric == "Nappy")
    {
      spots = nappySpots;
      labels = nappyLabels;
      emptyMessage = "No nappy data yet";
    }
    else if (selectedMetric == "Temperature")
    {
      spots = temperatureSpots;
      labels = temperatureLabels;
      emptyMessage = "No temperature data yet";
    }
    double minY = 0;
    double? maxY;

    if (selectedMetric == "Temperature")
    {
      minY = 34;
      maxY = 42;
    }
    if (spots.isEmpty)
    {
      return Center(
        child: Text(
          emptyMessage, style: TextStyle(fontWeight: FontWeight.w600),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.all(12),
      child: LineChart(
        LineChartData(
          minY: minY,
          maxY: maxY,
          gridData: FlGridData(show: true),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta)
                {
                  final index = value.toInt();
                  if (index < 0 || index >= labels.length)
                  {
                    return SizedBox();
                  }
                  return Text(
                    labels[index],
                    style: TextStyle(fontSize: 10),
                  );
                },
              ),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots, isCurved: true, barWidth: 3, dotData: FlDotData(show: true),
            ),
          ],
        ),
      ),
    );
  }
}