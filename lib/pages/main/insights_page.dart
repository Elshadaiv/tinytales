import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:tinytales/pages/machinelearning/cry_detection.dart';
import 'package:firebase_database/firebase_database.dart';

class InsightsPage extends StatefulWidget
{
   InsightsPage({super.key});

  @override
  State<InsightsPage> createState() => _InsightsPageState();
}

class _InsightsPageState extends State<InsightsPage>
{
  bool isRunning = false;

  final auth = FirebaseAuth.instance;
  String? selectedBabyId;

  String rawResultText = "";
  String boostedResultText = "";


  @override
  void initState()
  {
    super.initState();
    _loadBabies();
  }
  Future<void> _loadBabies() async
  {
    final user = auth.currentUser;

    if (user == null)
    {
      return;
    }

    final snapshot = await FirebaseFirestore.instance
        .collection("baby_profiles")
        .where("userId", isEqualTo: user.uid)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty)
    {
      selectedBabyId = snapshot.docs.first.id;
    }
    setState(() {});
  }

  String title = "Ready";
  String body = "Tap to test cry detection";
  final String demoAssetPath = "assets/machineLearning/test_spectrogram2.png";

  Future<void> _runTest() async
  {
    if (isRunning)
    {
      return;
    }

    setState(()
    {
      isRunning = true;
      title = "Listening";
      body= "Testing cry detection";
    });

    try
    {
      final pairs = await cry_Detection().predictProbFromAsset(demoAssetPath);

      if (!mounted)
      {
        return;
      }

      if(pairs.isEmpty)
        {
      setState(()
      {
        isRunning = false;
        title = "Result";
        body = "no result";
      });
      return;
    }

      String text = "";

      for(final p in pairs)
        {
          final label = p["label"].toString();
          final percent = p["percent"].toString();
          text = "$text$label: $percent%\n";
        }
      setState(()
      {
        isRunning = false;
        title = " Model Probabilities";
        body = text.trim();
      });
    }
    catch (e)
    {
      if (!mounted)
      {
        return;
      }

      setState(()
      {
        isRunning = false;
        title = "Error";
        body = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context)
  {
    final Color background = Colors.grey.shade200;
    final Color card = Colors.white;
    final Color accent = Colors.grey.shade900;

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: 24),
            Text(
              "Cry Detection",
              style: TextStyle(fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),

            SizedBox(height: 10),
            Expanded(
              child: Center(
                child: GestureDetector(
                  onTap: _runTest,
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 200),
                    width: isRunning ? 180 : 200,
                    height: isRunning ? 180 : 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: card,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 20,
                          offset: Offset(0, 10),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      isRunning ? Icons.graphic_eq : Icons.mic,
                      size: 48,
                      color: accent,
                    ),
                  ),
                ),
              ),
            ),

            Container(
              width: double.infinity,
              margin: EdgeInsets.fromLTRB(18, 0, 18, 18),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: card,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children:[
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    body,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
