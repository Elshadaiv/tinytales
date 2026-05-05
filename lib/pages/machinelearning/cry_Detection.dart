import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class cry_Detection
{
  static final cry_Detection _instance = cry_Detection._internal();
  factory cry_Detection() => _instance;
  cry_Detection._internal();

  Interpreter? _interpreter;
  final int inputSize = 128;

  Future<void> loadModel() async
  {
    if (_interpreter != null)
    {
      return;
    }

    final ByteData modelData = await rootBundle.load("assets/machineLearning/baby_sound_classifier_v7.tflite");

    final Uint8List modelBytes = modelData.buffer.asUint8List(modelData.offsetInBytes, modelData.lengthInBytes);

    _interpreter = Interpreter.fromBuffer(
      modelBytes,
      options: InterpreterOptions()
        ..threads = 2,
    );
  }
  Future<List<Map<String, dynamic>>> predictProbFromFile(String imagePath) async
  {
    final File spectrogramFile = File(imagePath);
    return predictProb(spectrogramFile);
  }

  Future<String> predictCry(File spectrogramImage) async
  {
    final pairs = await predictProb(spectrogramImage);

    if (pairs.isEmpty) {
      return ("Error");
    }

    final top2 = pairs.take(2).toList();

    final String l0 = top2[0]["label"].toString();
    final int p0 = top2[0]["percent"] as int;

    String out = "$l0 ($p0%)";

    if (top2.length > 1) {
      final String l1 = top2[1]["label"].toString();
      final int p1 = top2[1]["percent"] as int;
      out = "$out, $l1 ($p1%)";
    }

    return out;
  }

  Future<List<Map<String, dynamic>>> predictProb(File spectrogramImage) async
  {
    if (_interpreter == null)
    {
      await loadModel();
    }

    final Uint8List bytes = await spectrogramImage.readAsBytes();
    final img.Image? image = img.decodeImage(bytes);

    if (image == null)
    {
      throw Exception("Error");
    }

    final resized = img.copyResize(
      image,
      width: inputSize,
      height: inputSize,
      interpolation: img.Interpolation.average,
    );

    final input = List.generate(
      1,
          (_) => List.generate(
            inputSize,
                (y) => List.generate(
                  inputSize,
                      (x)
                  {
                    final pixel = resized.getPixel(x, y);
                    final r = pixel.r / 255.0;
                    final g = pixel.g / 255.0;
                    final b = pixel.b / 255.0;
                    final gray = (0.299 * r + 0.587 * g + 0.114 * b);
                    return [gray];
                  },
                ),
          ),
    );

    final output = List.generate(1, (_) => List.filled(1, 0.0));_interpreter!.run(input, output);
    final double probability = (output[0][0] as num).toDouble();
    final double painScore = probability;
    final double nonPainScore = 1 - probability;

    final bool painWins = painScore >= 0.60;
    final double winningScore = painWins ? painScore : nonPainScore;

    String wording;

    if (winningScore < 0.55)
    {
      wording = "Uncertain — recommend monitoring";
    }
    else if (winningScore >= 0.85)
    {
      wording = painWins ? "This is a pain cry" : "This is a non-pain cry";
    }
    else if (winningScore >= 0.75)
    {
      wording = painWins ? "Likely pain cry" : "Likely non-pain cry";
    }
    else
    {
      wording = painWins ? "Possible pain cry" : "Possible non-pain cry";
    }

    final List<Map<String, dynamic>> pairs = [
      {
        "label": painWins ? "pain" : "non_pain",
        "wording": wording,
        "score": winningScore,
        "percent": (winningScore * 100).round(),
      },
    ];
    return pairs;
  }
}