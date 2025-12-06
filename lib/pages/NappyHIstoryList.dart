import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class NappyHistoryList extends StatelessWidget {
  final String babyId;

   NappyHistoryList({super.key, required this.babyId});

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final db = FirebaseDatabase.instance.ref();

    return Scaffold(
      appBar: AppBar(
        title:  Text("Nappy History"),
      ),
      body: StreamBuilder(
        stream: db
            .child("users/$userId/tracking/$babyId/nappies")
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
          Map<dynamic, dynamic> raw = {};
          if (data is List)
          {
            raw = {
              for (int i = 0; i < data.length; i++)
                if (data[i] != null) i: data[i]
            };
          } else if (data is Map)
          {
            raw = data;
          }

          final entries = raw.values.map((e) =>
          {
            "type": e["type"],
            "time": e["time"],
            "colour": e["colour"] ?? "",
            "notes": e["notes"] ?? "",
          }).toList();

          entries.sort((a, b) => DateTime.parse(b["time"]).compareTo(DateTime.parse(a["time"])));
          return ListView.builder(
            padding:  EdgeInsets.all(16),
            itemCount: entries.length,
            itemBuilder: (context, index)
            {
              final item = entries[index];
              final time = DateTime.parse(item["time"]);
              final formatted = "${time.day}/${time.month}/${time.year} at ${time.hour}:${time.minute.toString().padLeft(2, '0')}";

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
                      "Type: ${item['type']}", style:  TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),

                    Text("Time: $formatted"),
                    if (item["colour"].toString().isNotEmpty)
                      Text("Colour: ${item["colour"]}"),

                    if (item["notes"].toString().isNotEmpty)
                      Text("Notes: ${item["notes"]}"),
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