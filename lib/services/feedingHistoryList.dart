import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';

class FeedingHistoryList extends StatelessWidget {
  final String babyId;

  const FeedingHistoryList({super.key, required this.babyId});

  @override
  Widget build(BuildContext context) {
    final _db = FirebaseDatabase.instance.ref();
    final _auth = FirebaseAuth.instance;

    return StreamBuilder(
      stream: _db
          .child("users/${_auth.currentUser!.uid}/tracking/$babyId/feedings")
          .onValue,
      builder: (context, snapshot)
      {
        if (!snapshot.hasData || snapshot.data?.snapshot.value == null) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Text("No feeding history "),
          );
        }

        final raw = snapshot.data!.snapshot.value;
        Map<dynamic, dynamic> map = {};

        if (raw is List)
        {
          map = {
            for (int i = 0; i < raw.length; i++)
              if (raw[i] != null) i: raw[i]
          };
        } else if (raw is Map)
        {
          map = raw;
        }

        final entries = map.entries
            .map((e)
        {
          final dt = DateTime.parse(e.value["time"]);
          return {
            "key": e.key,
            "amount": e.value["amount"],
            "time": dt,
            "dateOnly": DateTime(dt.year, dt.month, dt.day),
          };
        })
            .toList();

        if (entries.isEmpty)
        {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Text("No feeding history."),
          );
        }
        entries.sort((a, b) => b["time"].compareTo(a["time"]));

        Map<DateTime, List<Map<String, dynamic>>> grouped = {};

        for (var item in entries)
        {
          final date = item["dateOnly"];
          grouped.putIfAbsent(date, () => []);
          grouped[date]!.add(item);
        }

        final sortedDates = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final day in sortedDates) ...[
              Padding(
                padding: const EdgeInsets.only(top: 20, bottom: 8),
                child: Text(
                  _formatDayText(day),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              for (final item in grouped[day]!) _buildEntryCard(item, context),
            ]
          ],
        );
      },
    );
  }

  String _formatDayText(DateTime day)
  {
    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));

    if (day.year == today.year && day.month == today.month && day.day == today.day)
    {
      return "Today";
    }

    if (day.year == yesterday.year && day.month == yesterday.month && day.day == yesterday.day)
    {
      return "Yesterday";
    }

    return DateFormat("dd MMM yyyy").format(day);
  }

  Widget _buildEntryCard(Map<String, dynamic> item, BuildContext context) {
    final dt = item["time"] as DateTime;
    final formatted = "${dt.hour}:${dt.minute.toString().padLeft(2, '0')}";

    return Dismissible(
      key: Key(item["key"].toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.only(right: 20),
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_)
      {
        final _db = FirebaseDatabase.instance.ref();
        final _auth = FirebaseAuth.instance;
        _db
            .child(
            "users/${_auth.currentUser!.uid}/tracking/$babyId/feedings/${item["key"]}")
            .remove();
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, 2),
            )
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("${item["amount"]} ml",
                style:
                const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            Text(formatted, style: TextStyle(color: Colors.grey.shade700),
            ),
          ],
        ),
      ),
    );
  }
}
