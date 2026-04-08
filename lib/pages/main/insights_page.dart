import 'dart:io';
import 'package:record/record.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:tinytales/pages/machinelearning/cry_detection.dart';
import 'package:tinytales/pages/machinelearning/cry_context.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';

import 'package:wav/wav.dart';
import 'package:image/image.dart' as img;
import 'package:fftea/fftea.dart';
import 'dart:math' as math;


import 'package:path_provider/path_provider.dart';
class InsightsPage extends StatefulWidget
{
   InsightsPage({super.key});

  @override
  State<InsightsPage> createState() => _InsightsPageState();
}

class _InsightsPageState extends State<InsightsPage>
{

  final auth = FirebaseAuth.instance;
  String? selectedBabyId;
  List<QueryDocumentSnapshot<Map<String, dynamic>>> babies = [
  ];
  final cry_context engine = cry_context();

  bool get hasResultCard => title.isNotEmpty || body.isNotEmpty;
  String? uploadingBabyId;
  final ImagePicker picker = ImagePicker();




  final AudioRecorder recorder = AudioRecorder();

  String? recordedAudioPath;
  bool isRecording = false;

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


  Future<void> _UploadBabyImage(String babyId) async
  {
    try
    {
      if (uploadingBabyId == babyId)
      {
        return;
      }

      setState(()
      {
        uploadingBabyId = babyId;
      });

      final XFile? pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 25,
        maxWidth: 300,
        maxHeight: 300,
      );

      if (pickedFile == null)
      {
        setState(()
        {
          uploadingBabyId = null;
        });
        return;
      }

      final file = File(pickedFile.path);
      final bytes = await file.readAsBytes();
      final base64String = base64Encode(bytes);

      await FirebaseFirestore.instance
          .collection("baby_profiles")
          .doc(babyId)
          .update({
        "imageBase64": base64String,
      });

      await _loadBabies();
      setState(()
      {
        uploadingBabyId = null;
      });

      if (!mounted)
      {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Baby image saved"),
        ),
      );
    }
    catch (e)
    {
      setState(()
      {
        uploadingBabyId = null;
      });

      if (!mounted)
      {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to save image"),
        ),
      );
    }
  }

  Future<String> _getRecordingPath() async
  {
    final dir = await getTemporaryDirectory();
    final fileName = "cry_recording_${DateTime.now().millisecondsSinceEpoch}.wav";
    return "${dir.path}/$fileName";
  }

  Future<String> _getSpectrogramPath() async
  {
    final dir = await getTemporaryDirectory();
    final fileName = "spectrogram_${DateTime.now().millisecondsSinceEpoch}.png";
    return "${dir.path}/$fileName";
  }


  Future<void> _startRecording() async
  {
    try
    {
      if (selectedBabyId == null)
      {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Select a baby first"),
          ),
        );
        return;
      }
      final hasPermission = await recorder.hasPermission();
      if (!hasPermission)
      {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Microphone access is needed to record audio."),
          ),
        );
        return;
      }

      setState(()
      {
        isRecording = true;
        title = "Recording";
        body = "We're currently listening...";
      });
      final recordingPath = await _getRecordingPath();

      await recorder.start(
         RecordConfig(
        encoder: AudioEncoder.wav,
           sampleRate: 16000,
           numChannels: 1,
         ),
        path: recordingPath,
      );

      await Future.delayed(Duration(seconds: 10));
      final path = await recorder.stop();

      setState(()
      {
        isRecording = false;
        recordedAudioPath = path;
        title = "Recording complete";
        body = path != null
            ? "Audio saved, We're looking into this!"
            : "There's been a problem";
      });

      if (path != null)
      {
        await _generateSpectrogramFromRecording();
      }
    }
    catch (e)
    {
      setState(()
      {
        isRecording = false;
        title = "Error";
        body = e.toString();
      });
    }
  }
  List<double> _extractLoudestThreeSecond(List<double> samples, int sampleRate)
  {
    final int windowSize = sampleRate * 3;

    if (samples.length <= windowSize)
    {
      return samples;
    }
    int bestStart = 0;
    double bestScore = -1;

    final int step = (sampleRate / 4).round();

    for (int start = 0; start <= samples.length - windowSize; start += step)
    {
      double score = 0;

      for (int i = start; i < start + windowSize; i++)
      {
        score += samples[i].abs();
      }
      if (score > bestScore)
      {
        bestScore = score;
        bestStart = start;
      }
    }
    return samples.sublist(bestStart, bestStart + windowSize);
  }

  Future<void> _generateSpectrogramFromRecording() async
  {
    try {
      if (recordedAudioPath == null)
      {
        setState(() {
          title = "Error";
          body = "No recorded audio found";
        });
        return;
      }

      setState(()
      {
        title = "Analysing";
        body = "We're analysing the cry now....";
      });

      final wav = await Wav.readFile(recordedAudioPath!);
      final fullSamples = wav.channels.first;
      final sampleRate = wav.samplesPerSecond;
      final samples = _extractLoudestThreeSecond(fullSamples, sampleRate);
      int fftSize = 512;

      int hopLength = 256;
      final spectrogram = <List<double>>[

      ];

      for (int start = 0; start + fftSize <= samples.length; start += hopLength) {
        final chunk = samples.sublist(start, start + fftSize);
        final stft = STFT(fftSize, Window.hanning(fftSize));
        stft.run(chunk, (freq)
            {
          final mags = freq.discardConjugates().magnitudes().toList();
          spectrogram.add(mags);
        });
      }
      if (spectrogram.isEmpty)
      {
        setState(()
        {
          title = "Error";
          body = "We weren't able to listen properly. Try again.";
        });
        return;
      }
      final int width = spectrogram.length;
      final int height = spectrogram.first.length;

      double minVal = double.infinity;
      double maxVal = double.negativeInfinity;

      for (final frame in spectrogram)
      {
        for (final v in frame)
        {
          final logV = v <= 0 ? 0.0 : math.log(v + 1);
          if (logV < minVal) minVal = logV;
          if (logV > maxVal) maxVal = logV;
        }
      }
      final image = img.Image(width: width, height: height);
      for (int x = 0; x < width; x++)
      {
        final frame = spectrogram[x];

        for (int y = 0; y < height; y++)
        {
          final flippedY = height - 1 - y;
          final raw = frame[y] <= 0 ? 0.0 : math.log(frame[y] + 1);
          final norm = maxVal > minVal
              ? ((raw - minVal) / (maxVal - minVal)) : 0.0;
          final value = (norm * 255).clamp(0, 255).toInt();
          image.setPixelRgb(x, flippedY, value, value, value);
        }
      }

      final resized = img.copyResize(image, width: 128, height: 128);
      final spectrogramPath = await _getSpectrogramPath();
      final pngBytes = img.encodePng(resized);

      final file = File(spectrogramPath);
      await file.writeAsBytes(pngBytes);

      setState(()
      {
        title = "We're further analysing";
      });

      final pairs = await cry_Detection().predictProbFromFile(spectrogramPath);

      final top = pairs.first;
      final String topLabel = top["label"].toString();
      final int topPercent = top["percent"] as int;

      String headline = "";

      if (topLabel == "pain")
      {
        headline = "Possible Pain Cry Detected — $topPercent%";
      }
      else
      {
        headline = "Non Pain Cry Likelihood — $topPercent%";
      }
      String rawText = "";

      for (final p in pairs.take(2))
      {
        rawText = "$rawText${p["label"]}: ${p["percent"]}%\n";
      }

      final user = FirebaseAuth.instance.currentUser;

      if (user == null || selectedBabyId == null)
      {
        setState(()
        {
          title = "Results";
          body = rawText.trim();
        });
        return;
      }

      final trackedText = await engine.run(
        userId: user.uid,
        babyId: selectedBabyId!,
        assetPath: spectrogramPath,
        modelPairs: pairs,
      );

      setState(()
      {
        title = "Results";
        body =
        "$headline\n\n"
            "The sound pattern of this cry matches characteristics often associated with ${topLabel == "pain" ? "pain or strong discomfort" : "a lower likelihood of pain"}.\n\n"
            "From recent tracking:\n$trackedText\n\n"
            "If the baby continues crying, consider checking:\n"
            "• Temperature\n"
            "• Nappy Condition\n"
            "• Signs of Illness or Discomfort";
      });

      return;
    }

    catch (e)
    {
      setState(()
      {
        title = "Error";
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
          final babyId = baby.id;
          final babyName = data["name"] ?? "Baby";
          final imageBase64 = data["imageBase64"] ?? "";          final isSelected = selectedBabyId == babyId;
          final isUploadingImage = uploadingBabyId == babyId;

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
                      GestureDetector(
                        onTap: ()
                        {
                          _UploadBabyImage(babyId);
                        },
                      child: CircleAvatar(
                        radius: 28,
                        backgroundColor: isSelected
                            ? Colors.purple.shade100
                            : Colors.grey.shade300,
                        backgroundImage: imageBase64.toString().isNotEmpty
                            ? MemoryImage(base64Decode(imageBase64.toString()))
                            : null,
                        child: isUploadingImage
                          ? SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: isSelected ? Colors.purpleAccent : Colors.grey.shade700,
                          ),
                        )
                       : imageBase64.toString().isEmpty
                        ? Icon(
                          Icons.add,
                          color: isSelected ? Colors.purple : Colors.grey.shade700,
                        )
                            : null,
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
                  onTap: hasSelectedBaby && !isRecording ? _startRecording : null,
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 200),
                    width: isRecording ? 180 : 200,
                    height: isRecording ? 180 : 200,
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
                      isRecording ? Icons.graphic_eq : Icons.mic,
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
                isRecording
                ? "Recording in progress...."
                : hasSelectedBaby
                    ? "Ready to analyse your baby's cry?"
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