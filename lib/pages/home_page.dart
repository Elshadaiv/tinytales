
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:tinytales/pages/insights_page.dart';
import 'package:tinytales/pages/profile_page.dart';
import 'package:tinytales/pages/tracking_page.dart';
import 'package:google_nav_bar/google_nav_bar.dart';

class  HomePage extends StatefulWidget {
   HomePage({super.key});


   @override
   State<HomePage> createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  final user = FirebaseAuth.instance.currentUser;

  int currentPage = 0;

  List<Widget> pages = const [
    ProfilePage(),
    InsightsPage(),
    TrackingPage(),
  ];

  void signUserOut() {
    FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(onPressed: signUserOut, icon: const Icon(Icons.logout)),
        ],
      ),
      body: Center(
        child: Text('Logged in as ' + (user?.email ?? 'Unknown')),
      ),

      bottomNavigationBar: Container(
        color: Colors.black,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 17),
          child: GNav(
            backgroundColor: Colors.black,
              color: Colors.white,
              activeColor: Colors.white,
              tabBackgroundColor: Colors.purple,
              gap: 8,
              padding: const EdgeInsets.all(16),
              tabs: const [
              GButton(icon: Icons.home,
                text: 'Home',
              ),
              GButton(icon: Icons.info,
                text: 'Insights',
              ),
              GButton(icon: Icons.track_changes,
                text: 'Tracking',
              ),
              GButton(icon: Icons.people,
                text: 'Community',
              ),
            GButton(icon: Icons.person,
              text: 'Profile',
            ),
            ],
              onTabChange: (int index) {
                setState(() {
                print(index);
                });
              }
          ),
        ),
      ),
    );
  }
}

