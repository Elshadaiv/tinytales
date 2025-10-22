import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';


class immunisationPassportPage extends StatefulWidget {
  const immunisationPassportPage({super.key});

  @override
  State<immunisationPassportPage> createState() => _immunisationPassportPageState();
}

class _immunisationPassportPageState extends State<immunisationPassportPage> {
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.grey[300],
      appBar: AppBar(
        backgroundColor: Colors.grey[300],
      ),
      body: Center(
        child: Text('Immunisation Passport Page ' +
            (FirebaseAuth.instance.currentUser?.email ?? 'Unknown')),
      ),
    );
  }

  //// GP NAME AND ADDRESS
// FOR VACINATIONS IT WILL BE TABLE USER CAN PUT IN TO TRACK
//Vaccine Name
// 6 in 1
// PCV
// MenB
// Rota
// Age Given Manufacturer Batch Number Expiry Date Route/Site Administered by Date
//HAVE THAT TRACKED
}