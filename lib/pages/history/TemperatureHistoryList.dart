
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class TemperatureHistoryList extends StatelessWidget
{
  final String babyId;

  TemperatureHistoryList({
    super.key,
    required this.babyId,
  });

  @override
  Widget build(BuildContext context)
  {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final db = FirebaseDatabase.instance.ref();

    return Scaffold(
      appBar: AppBar(
        title: Text("Temperature History"),
      ),
      body: StreamBuilder(
        stream: db
            .child("users/$userId/tracking/$babyId/temperatures")
            .onValue,
        builder: (context, snapshot)
        {
          if (!snapshot.hasData || snapshot.data!.snapshot.value == null)
          {
            return Center(
              child: Text("No temperature records."),
            );
          }

          final data = snapshot.data!.snapshot.value;

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
              .where((e) => e["time"] != null).toList();

          if (entries.isEmpty)
          {
            return Center(
              child: Text("No temperature records."),
            );
          }

          entries.sort((a, b)
          {
            final at = DateTime.tryParse(a["time"]) ?? DateTime(1970);
            final bt = DateTime.tryParse(b["time"]) ?? DateTime(1970);
            return bt.compareTo(at);
          });

          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: entries.length,
            itemBuilder: (context, index)
            {
              final item = entries[index];
              final value = item["value"];
              final time = DateTime.parse(item["time"]);

              final formattedTime = "${time.day}/${time.month}/${time.year} at ${time.hour}:${time.minute.toString().padLeft(2, '0')}";
              return Container(
                margin: EdgeInsets.only(bottom: 12),
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
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
                      "$value °C",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(formattedTime),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
