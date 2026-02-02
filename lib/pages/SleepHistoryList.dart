import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class SleepHistoryList extends StatelessWidget
{
  final String babyId;

  SleepHistoryList({super.key, required this.babyId});

  @override
  Widget build(BuildContext context)
  {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final db = FirebaseDatabase.instance.ref();

    return Scaffold(
      appBar: AppBar(
        title:  Text("Sleep History"),
      ),
      body: StreamBuilder(
        stream: db
            .child("users/$userId/tracking/$babyId/sleeps")
            .onValue,
        builder: (context, snapshot)
        {
          if (!snapshot.hasData || snapshot.data!.snapshot.value == null)
          {
            return const Center(
              child: Text("No record. Get tracking."),
            );
          }

          final data = snapshot.data!.snapshot.value;

          Map<dynamic, dynamic> raw =
          {
          };

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
            "startTime": e["startTime"],
            "endTime": e["endTime"],
            "durationMinutes": e["durationMinutes"] ?? 0,
            "notes": e["notes"] ?? "",
          })
              .where((e) => e["endTime"] != null)
              .toList();

          if (entries.isEmpty)
          {
            return const Center(
              child: Text("No record. Get tracking."),
            );
          }

          entries.sort((a, b) => DateTime.parse(b["endTime"]).compareTo(DateTime.parse(a["endTime"])));

          return ListView.builder(
            padding:  EdgeInsets.all(16),
            itemCount: entries.length,
            itemBuilder: (context, index)
            {
              final item = entries[index];

              final start = DateTime.parse(item["startTime"]);
              final end = DateTime.parse(item["endTime"]);

              final startFormatted = "${start.day}/${start.month}/${start.year} at ${start.hour}:${start.minute.toString().padLeft(2, '0')}";
              final endFormatted = "${end.day}/${end.month}/${end.year} at ${end.hour}:${end.minute.toString().padLeft(2, '0')}";

              final mins = item["durationMinutes"] is int ? item["durationMinutes"]
                  : int.tryParse(item["durationMinutes"].toString()) ?? 0;

              final durationText = _formatDuration(mins);
              return Container(
                margin:  EdgeInsets.only(bottom: 12),
                padding:  EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow:  [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 5,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Duration: $durationText",
                      style:  TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),

                    SizedBox(height: 6),

                    Text("Start: $startFormatted"),
                    Text("End: $endFormatted"),

                    if (item["notes"].toString().isNotEmpty)
                      Padding(
                        padding:  EdgeInsets.only(top: 6),
                        child: Text("Notes: ${item["notes"]}"),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _formatDuration(int minutes)
  {
    final h = minutes ~/ 60;
    final m = minutes % 60;

    if (h == 0)
      return "${m}m";

    if (m == 0)
      return "${h}h";

    return "${h}h ${m}m";
  }
}
