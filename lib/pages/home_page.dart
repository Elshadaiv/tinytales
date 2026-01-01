
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:tinytales/pages/community_page.dart';
import 'package:tinytales/pages/insights_page.dart';
import 'package:tinytales/pages/profile_page.dart';
import 'package:tinytales/pages/tracking_page.dart';
import 'package:google_nav_bar/google_nav_bar.dart';

import '../services/notification_service.dart';

class  HomePage extends StatefulWidget {
  const HomePage({super.key, this.onProfileTap});
  final void Function()? onProfileTap;


   @override
   State<HomePage> createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  final user = FirebaseAuth.instance.currentUser;

  int currentPage = 0;

  List<Widget> pages =  [
    Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Welcome back! ' + (FirebaseAuth.instance.currentUser?.email ?? 'Unknown')),
        ],
      ),
    ),
    InsightsPage(),
    TrackingPage(),
    CommunityPage(),
    ProfilePage(),
  ];

  void signUserOut() {
    FirebaseAuth.instance.signOut();

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      appBar: AppBar(
        backgroundColor: Colors.grey[300],
        actions: [
          IconButton(onPressed: signUserOut, icon: const Icon(Icons.logout)),
        ],
      ),
      body: pages[currentPage],

      bottomNavigationBar: Container(
        color: Colors.black,
        child: SafeArea(
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
                if (index >= 0 && index < pages.length) {
                  setState(() {
                    currentPage = index;
                  });

                }
                }
            ),
          ),
        ),
      ),
    );
  }
}

