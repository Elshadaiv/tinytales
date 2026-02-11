import 'package:flutter/material.dart';
import 'package:tinytales/pages/history/feedingHistoryList.dart';

class FeedingHistoryPage extends StatelessWidget {
  final String babyId;

  const FeedingHistoryPage({super.key, required this.babyId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.grey[300],
        title: const Text("Feeding History"),
      ),

      backgroundColor: Colors.grey[300],
      body: SingleChildScrollView(
        padding:  EdgeInsets.all(16),
        child: FeedingHistoryList(babyId: babyId),
      ),
    );
  }
}
