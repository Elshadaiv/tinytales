import 'package:flutter/material.dart';
import 'package:tinytales/services/cry_detection.dart';


class InsightsPage extends StatefulWidget
{
  const InsightsPage({super.key});

  @override
  State<InsightsPage> createState() => _InsightsPageState();
}

class _InsightsPageState extends State<InsightsPage>
{
  bool isRunning = false;

  String title = "Ready";
  String body = "Tap to test cry detection";
  final String demoAssetPath = "assets/machineLearning/test_spectrogram.png";

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
      final result = await cry_Detection().predictCryFromAsset(demoAssetPath);

      if (!mounted)
      {
        return;
      }

      setState(()
      {
        isRunning = false;
        title = "Result";
        body = result.toString();
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
