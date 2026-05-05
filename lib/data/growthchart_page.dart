import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class GrowthChartPage extends StatelessWidget {
  final double initialWeight;
  final double currentWeight;
  final String babyId;

  const GrowthChartPage({
    super.key,
    required this.initialWeight,
    required this.currentWeight,
    required this.babyId,
  });

  @override
  Widget build(BuildContext context) {
    final maxY =
        (initialWeight > currentWeight ? initialWeight : currentWeight) + 1;

    return Scaffold(
      backgroundColor: Color(0xFFF7F6FB),
      appBar: AppBar(
        backgroundColor: Color(0xFFF7F6FB),
        elevation: 0,
        title: Text(
          "Growth Chart",
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: EdgeInsets.all(18),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
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
              Text(
                "Weight Progress",
                style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w800,),
              ),

              SizedBox(height: 8),

              Text(
                "Tracking your baby’s weight progress over time.",
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.black54,
                ),
              ),

              SizedBox(height: 24),

              SizedBox(
                height: 260,
                child: StreamBuilder(
                  stream: FirebaseDatabase.instance
                      .ref()
                      .child("users/${FirebaseAuth.instance.currentUser!.uid}/tracking/$babyId/growth")
                      .onValue,
                  builder: (context, snapshot)
                  {
                    if (!snapshot.hasData || snapshot.data!.snapshot.value == null)
                    {
                      return Center(child: Text("No growth data yet"));
                    }

                    final data = snapshot.data!.snapshot.value;
                    Map<dynamic, dynamic> raw = {};
                    if (data is Map) raw = data;

                    final entries = raw.values
                        .where((e) => e != null && e["time"] != null && e["weight"] != null)
                        .map((e) => Map<String, dynamic>.from(e))
                        .toList();

                    entries.sort((a, b)
                    {
                      final at = DateTime.tryParse(a["time"].toString()) ?? DateTime(1970);
                      final bt = DateTime.tryParse(b["time"].toString()) ?? DateTime(1970);
                      return at.compareTo(bt);
                    });

                    final List<FlSpot> spots = [];
                    final List<String> labels = [];

                    for (int i = 0; i < entries.length; i++)
                    {
                      final w = double.tryParse(entries[i]["weight"].toString()) ?? 0;
                      final t = DateTime.tryParse(entries[i]["time"].toString());
                      spots.add(FlSpot(i.toDouble(), w));
                      labels.add(t != null ? "${t.day}/${t.month}" : "");
                    }
                    if (spots.isEmpty)
                    {
                      return Center(child: Text("No growth data yet"));
                    }
                    return LineChart(
                      LineChartData(
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
                                final i = value.toInt();
                                if (i < 0 || i >= labels.length) return SizedBox();
                                return Text(labels[i], style: TextStyle(fontSize: 10));
                              },
                            ),
                          ),
                        ),
                        lineBarsData: [
                          LineChartBarData(
                            spots: spots,
                            isCurved: true,
                            barWidth: 3,
                            color: Colors.green,
                            dotData: FlDotData(show: true),
                            belowBarData: BarAreaData(
                              show: true,
                              color: Colors.green.withOpacity(0.15),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              SizedBox(height: 18),

              Text(
                "Initial: ${initialWeight.toStringAsFixed(1)} kg",
                style: TextStyle(fontWeight: FontWeight.w600),),

              Text(
                "Current: ${currentWeight.toStringAsFixed(1)} kg",
                style: TextStyle(fontWeight: FontWeight.w600),),

              SizedBox(height: 6),

              Text(
                _getInsight(),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.green,
                ),
              ),
              SizedBox(height: 20),

              Text(
                "Growth History",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),

              SizedBox(height: 10),

              SizedBox(
                height: 200,
                child: StreamBuilder(
                  stream: FirebaseDatabase.instance
                      .ref()
                      .child("users/${FirebaseAuth.instance.currentUser!.uid}/tracking/$babyId/growth")
                      .onValue,
                  builder: (context, snapshot)
                  {
                    if (!snapshot.hasData || snapshot.data!.snapshot.value == null)
                    {
                      return Text("No growth history yet.");
                    }

                    final data = snapshot.data!.snapshot.value;

                    Map<dynamic, dynamic> raw = {};

                    if (data is Map)
                    {
                      raw = data;
                    }

                    final entries = raw.values.toList();

                    entries.sort((a, b)
                    {
                      final at = DateTime.tryParse(a["time"]) ?? DateTime(1970);
                      final bt = DateTime.tryParse(b["time"]) ?? DateTime(1970);
                      return bt.compareTo(at);
                    });

                    return ListView.builder(
                      itemCount: entries.length,
                      itemBuilder: (context, index)
                      {
                        final item = entries[index];
                        final time = DateTime.tryParse(item["time"]);

                        String timeText = "";

                        if (time != null)
                        {
                          timeText =
                          "${time.day}/${time.month}/${time.year} ${time.hour}:${time.minute.toString().padLeft(2, '0')}";
                        }

                        return Container(
                          margin: EdgeInsets.only(bottom: 10),
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Color(0xFFF7F6FB),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(timeText, style: TextStyle(fontWeight: FontWeight.w700)),
                              SizedBox(height: 4),
                              Text("Weight: ${item["weight"]} kg"),
                              Text("Height: ${item["height"]} cm"),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getInsight()
  {
    final diff = currentWeight - initialWeight;

    if (diff > 0)
    {
      return "Increase of +${diff.toStringAsFixed(1)} kg";
    }
    else if (diff < 0)
    {
      return "Decrease of ${diff.toStringAsFixed(1)} kg";
    }
    else
    {
      return "No weight change";
    }
  }
}