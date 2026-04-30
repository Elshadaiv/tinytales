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
                child: BarChart(
                  BarChartData(
                    maxY: maxY,
                    gridData: FlGridData(show: true),
                    borderData: FlBorderData(show: false),

                    titlesData: FlTitlesData(
                      topTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      rightTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),

                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta)
                          {
                            if (value.toInt() == 0)
                            {
                              return Text("Initial", style: TextStyle(fontSize: 11));
                            }
                            if (value.toInt() == 1)
                            {
                              return Text("Current", style: TextStyle(fontSize: 11));
                            }
                            return SizedBox();
                          },
                        ),
                      ),
                    ),
                    barGroups: [
                      BarChartGroupData(
                        x: 0,
                        barRods: [
                          BarChartRodData(
                            toY: initialWeight,
                            width: 28, color: Colors.grey,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ],
                      ),

                      BarChartGroupData(
                        x: 1,
                        barRods: [
                          BarChartRodData(
                            toY: currentWeight,
                            width: 28, color: Colors.green,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ],
                      ),
                    ],
                  ),
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