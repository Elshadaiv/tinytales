import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:tinytales/pages/machinelearning/cry_detection.dart';
import 'package:tinytales/pages/machinelearning/cry_context.dart';

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
  List<QueryDocumentSnapshot<Map<String, dynamic>>> babies = [
  ];
  final cry_context engine = cry_context();

  String rawResultText = "";
  String boostedResultText = "";
  bool get hasResultCard => title.isNotEmpty || body.isNotEmpty;


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
        .get();

    babies = snapshot.docs;
    setState(() {});
  }

  String title = "";
  String body = "";
  final String demoAssetPath = "assets/machineLearning/test_spectrogram.png";

  Future<void> _runTest() async
  {
    if (isRunning) return;
    setState(()
    {
      isRunning = true;
      title = "Listening";
      body= "Testing cry detection";
    });

    try
    {
      final pairs = await cry_Detection().predictProbFromAsset(demoAssetPath);

      final user = FirebaseAuth.instance.currentUser;
      if (user == null)
      {
        return;
      }
      if (selectedBabyId == null)
      {
        setState(()
        {
          isRunning = false;
          title = "Error";
          body = "no result";
        });
        return;
      }

      String rawText = "";
      for (final p in pairs.take(2))
      {
        rawText = "$rawText${p["label"]}: ${p["percent"]}%\n";
      }

      final trackedText = await engine.run(
        userId: user.uid,
        babyId: selectedBabyId!,
        assetPath: demoAssetPath,
        modelPairs: pairs,
      );

      setState(()
      {
        isRunning = false;
        title = "Results";
        body = "From analysing this cry, we think:\n${rawText.trim()}\n\nFrom what we tracked:\n$trackedText";
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

  Widget _buildBabyCards()
  {
    if (babies.isEmpty)
    {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: 18),
        child: Container(
          width: double.infinity, padding: EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18),
          ),
          child: Text(
            "No babies found. Please add a baby in the profile section.",
            style: TextStyle(
              fontSize: 14,
              color: Colors.black54,
            ),
          ),
        ),
      );
    }
    return SizedBox(
      height: 170,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 18),
        itemCount: babies.length,
        itemBuilder: (context, index)
        {
          final baby = babies[index];
          final data = baby.data();
          final babyName = data["name"] ?? "Baby";
          final isSelected = selectedBabyId == baby.id;
          return GestureDetector(
            onTap: ()
            {
              setState(()
              {
                if (isSelected)
                {
                  selectedBabyId = null;
                }
                else
                {
                  selectedBabyId = baby.id;
                }
              });
            },
            child: AnimatedContainer(
              duration: Duration(milliseconds: 220),
              width: 240,
              margin: EdgeInsets.only(right: 14),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected ? Colors.purple.shade50 : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isSelected ? Colors.purple : Colors.grey.shade300,
                  width: isSelected ? 2 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isSelected ? Colors.purple.withOpacity(0.10) : Colors.black12,
                    blurRadius: isSelected ? 14 : 8,
                    offset: Offset(0, isSelected ? 6 : 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: isSelected
                            ? Colors.purple.shade100
                            : Colors.grey.shade300,
                        child: Icon(
                          Icons.child_care,
                          color: isSelected ? Colors.purple : Colors.grey.shade700,
                        ),
                      ),

                      if (isSelected)
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.purple,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            "Selected",
                            style: TextStyle(fontSize: 11, color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 18),
                  Text(
                    babyName,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 8),
                  Text(
                    isSelected ? "Baby crying?" : "Tap to select",
                    style: TextStyle(
                      fontSize: 13,
                      color: isSelected ? Colors.purple : Colors.black54,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context)
  {
    final Color background = Colors.grey.shade200;
    final Color card = Colors.white;
    final Color accent = Colors.grey.shade900;
    final bool hasSelectedBaby = selectedBabyId != null;

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
            SizedBox(height: 18),
            _buildBabyCards(),
            SizedBox(height: 18),

            SizedBox(height: 10),
            Expanded(
              child: Center(
                child: GestureDetector(
                  onTap: hasSelectedBaby? _runTest : null,
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 200),
                    width: isRunning ? 180 : 200,
                    height: isRunning ? 180 : 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: hasSelectedBaby ? card : Colors.grey.shade300,
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
                      color: hasSelectedBaby ? accent: Colors.grey.shade500,
                    ),
                  ),
                ),
              ),
            ),

            Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Text(
                hasSelectedBaby
                    ? "Ready to analyse your babies cry?"
                    : "Select which baby to start analysing",
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.black54,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            if (hasResultCard)
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