import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:tinytales/insights_page.dart';
import 'package:tinytales/profile_page.dart';
import 'package:tinytales/tracking_page.dart';

class  HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => HomePageState();
}

class HomePageState extends State<HomePage> {

  int currentPage = 0;
  List<Widget> pages= const [
    ProfilePage(),
InsightsPage(),
TrackingPage(),
  ];
  void signUserOut()
  {
    FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(actions: [IconButton(onPressed: signUserOut, icon: Icon(Icons.logout))],),
      body: pages[0],
      floatingActionButton: FloatingActionButton(onPressed: () {
        debugPrint('Button pressed');

      },

        child: Icon(Icons.add),
      ),
      bottomNavigationBar: NavigationBar(
        destinations: const[
          NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.info), label: 'Insights'),
          NavigationDestination(icon: Icon(Icons.track_changes), label: 'Tracking'),
          NavigationDestination(icon: Icon(Icons.people), label: 'Community'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
        ],

        onDestinationSelected: (int index) {
          setState(() {
            currentPage = index;
          });
        },
        selectedIndex: currentPage,
      ),

    );

  }
} 
