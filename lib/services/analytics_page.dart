import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fl_chart/fl_chart.dart';

class AnalyticsPage extends StatefulWidget
{
  AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage>
{
  String selectedMetric = "Feeding";
  String selectedRange = "7 Days";

  final List<String> metrics = [
    "Feeding",
    "Sleep",
    "Nappy",
    "Temperature",
  ];

  final List<String> ranges = [
    "7 Days",
    "30 Days",
    "All",
  ];

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
      onTap: ()
      {
        setState(()
        {
          selectedRange = label;
        });
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


  @override
  Widget build(BuildContext context)
  {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      appBar: AppBar(backgroundColor: Colors.grey[300],
        title: Text(
          "Analytics",
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

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
                    child: Center(
                      child: Text(
                        "$selectedMetric testing this",
                        style: TextStyle(
                          color: Colors.black54,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 16),

            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: metrics.map((metric)
                {
                  return Padding(
                    padding: EdgeInsets.only(right: 10),
                    child: _metricButton(metric),
                  );
                }).toList(),
              ),
            ),
            SizedBox(height: 16),
            SizedBox(height: 16),

            Row(
              children: ranges.map((range)
              {
                return Padding(
                  padding: EdgeInsets.only(right: 10),
                  child: _rangeButton(range),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}