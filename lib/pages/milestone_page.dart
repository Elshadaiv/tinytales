import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class milestone_page extends StatelessWidget {
   milestone_page({super.key});

  final List<Map<String, String>> milestones =
  [
    {
      "title": "3 Months", "image": "assets/milestones/Badge3.png",
    },
    {
      "title": "6 Months", "image": "assets/milestones/Badge6.png",
    },
    {
      "title": "9 Months", "image": "assets/milestones/Badge9.png",
    },
    {
      "title": "12 Months", "image": "assets/milestones/Badge12.png",
    },
  ];

  @override
  Widget build(BuildContext context)
  {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      appBar: AppBar(
        backgroundColor: Colors.grey[300],
        title: Text(
          "Milestones",
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.only(top: 20),
        child: SizedBox(
          height: 320,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 16),
            itemCount: milestones.length,
            itemBuilder: (context, index)
            {
              final item = milestones[index];
              return Container(
                width: 240,
                margin: EdgeInsets.only(right: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Image.asset(
                          item["image"]!,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),

                    Padding(
                      padding: EdgeInsets.only(bottom: 16),
                      child: Text(
                        item["title"]!,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}