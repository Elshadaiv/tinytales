import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class cry_Detection
{
  static final cry_Detection _instance = cry_Detection._internal();
  factory cry_Detection() => _instance;
  cry_Detection._internal();

  Interpreter? _interpreter;
  List<String> _labels = [];
  final int inputSize = 128;

  Future<void> loadModel() async
  {
    if (_interpreter != null)
    {
      return;
    }

    final ByteData modelData = await rootBundle.load("assets/machineLearning/baby_sound_classifier_v4.tflite");

    final Uint8List modelBytes = modelData.buffer.asUint8List(modelData.offsetInBytes, modelData.lengthInBytes);

    _interpreter = Interpreter.fromBuffer(
      modelBytes,
      options: InterpreterOptions()
        ..threads = 2,
    );

    final rawLabels = await rootBundle.loadString("assets/machineLearning/labels.txt",
    );

    _labels = rawLabels
        .split("\n")
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }
  Future<File> _assetToTempFile(String assetPath) async
  {
    final ByteData data = await rootBundle.load(assetPath);
    final Directory tempDir = await getTemporaryDirectory();

    final String ext = assetPath.toLowerCase().endsWith(".jpg") || assetPath.toLowerCase().endsWith(".jpeg")
        ? ".jpg" : ".png";

    final File file = File("${tempDir.path}/spectrogram_${DateTime.now().millisecondsSinceEpoch}$ext");
    await file.writeAsBytes(data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
    );

    return file;
  }


  Future<String> predictCryFromAsset(String assetPath) async
  {
    final File tempFile = await _assetToTempFile(assetPath);
    return predictCry(tempFile);
  }


  Future<List<Map<String, dynamic>>> predictProbFromAsset(String assetPath) async
  {
    final File tempFile = await _assetToTempFile(assetPath);
    return predictProb(tempFile);
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
                    return [gray, gray, gray];
                  },
                ),
          ),
    );

    final int numClasses = _interpreter!.getOutputTensor(0).shape[1];
    final output = List.generate(1, (_) => List.filled(numClasses, 0.0),
    );
    _interpreter!.run(input, output);

    final prediction = output[0];

    final pairs = List.generate(prediction.length, (i) {
      final label = i < _labels.length ? _labels[i] : "unknown";
      final score = prediction[i] is double
          ? prediction[i]
          : (prediction[i] as num).toDouble();
      return
        {
          "label": label,
          "score": score,
          "percent": (score * 100).round(),
        };
    },
    );

    pairs.sort((a, b) => (b["score"] as double).compareTo(a["score"] as double));
    return pairs;
  }
}