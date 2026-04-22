import 'package:firebase_database/firebase_database.dart';

class cry_context
{
  Future<Map<String, dynamic>?> _latestEntry(
      {
        required String path,
        String timeKey = "time",
      }) async
  {
    final snap = await FirebaseDatabase.instance.ref().child(path).get();
    if (!snap.exists)
    {
      return null;
    }
    final value = snap.value;
    Map<dynamic, dynamic> raw =
    {
    };
    if (value is List)
    {
      raw =
      {
        for (int i = 0; i < value.length; i++)
          if (value[i] != null) i: value[i]
      };
    }
    else if (value is Map)
    {
      raw = value;
    }
    else
    {
      return null;
    }

    final entries = raw.values
        .where((e) => e != null)
        .map((e) => Map<String, dynamic>.from(e))
        .where((e) => e[timeKey] != null)
        .toList();

    if (entries.isEmpty)
    {
      return null;
    }

    entries.sort((a, b)
    {
      final at = DateTime.tryParse(a[timeKey].toString()) ?? DateTime(1970);
      final bt = DateTime.tryParse(b[timeKey].toString()) ?? DateTime(1970);
      return at.compareTo(bt);
    });
    return entries.last;
  }

  int _minsSinceIso(String? iso)
  {
    if (iso == null || iso.isEmpty) return -1;

    final dt = DateTime.tryParse(iso);
    if (dt == null) return -1;

    return DateTime.now().difference(dt).inMinutes;
  }

  Future<Map<String, dynamic>> _getTrackingContext({
    required String userId,
    required String babyId,
  }) async
  {
    final feed = await _latestEntry(path: "users/$userId/tracking/$babyId/feedings", timeKey: "time",);
    final sleep = await _latestEntry(path: "users/$userId/tracking/$babyId/sleeps", timeKey: "endTime",);
    final nappy = await _latestEntry(path: "users/$userId/tracking/$babyId/nappies", timeKey: "time",);

    final feedMins = _minsSinceIso(feed?["time"]?.toString());
    final sleepMins = _minsSinceIso(sleep?["endTime"]?.toString());
    final nappyMins = _minsSinceIso(nappy?["time"]?.toString());
    final nappyType = (nappy?["type"] ?? "").toString().toLowerCase();

    return
      {
        "minsSinceFeed": feedMins,
        "minsSinceSleep": sleepMins,
        "minsSinceNappy": nappyMins,
        "nappyType": nappyType,
      };
  }

  String _pickContextLabel({
    required int feedMins,
    required int sleepMins,
    required int nappyMins,
    required String nappyType,
  })
  {
    int bestScore = 0;
    String best = "";

    int hungryScore = 0;
    if (feedMins >= 900)
      hungryScore = 4;
    else if (feedMins >= 720)
      hungryScore = 3;
    else if (feedMins >= 360)
      hungryScore = 2;
    else if (feedMins >= 120)
      hungryScore = 1;

    int tiredScore = 0;
    if (sleepMins >= 210)
      tiredScore = 3;
    else if (sleepMins >= 150)
      tiredScore = 2;
    else if (sleepMins >= 60)
      tiredScore = 1;

    int discomfortScore = 0;
    if (nappyType.contains("dirty") && nappyMins >= 30)
      discomfortScore = 4;
    else if (nappyMins >= 210)
      discomfortScore = 3;
    else if (nappyMins >= 150)
      discomfortScore = 2;
    else if (nappyMins >= 60)
      discomfortScore = 1;

    if (discomfortScore > bestScore)
    {
      bestScore = discomfortScore;
      best = "discomfort";
    }

    if (hungryScore > bestScore)
    {
      bestScore = hungryScore;
      best = "hungry";
    }

    if (tiredScore > bestScore)
    {
      bestScore = tiredScore;
      best = "tired";
    }

    return best;
  }

  String _smartExplanation({
    required String label,
    required int percent,
    required int feedMins,
    required int sleepMins,
    required int nappyMins,
    required String nappyType,
  }) {
    int toHours(int mins) {
      if (mins < 0) return -1;
      return (mins / 60).floor();
    }

    final nappyH = toHours(nappyMins);
    final lower = label.toLowerCase();

    if (lower.contains("hungry"))
    {
      if (feedMins >= 60)
      {
        final feedH = (feedMins / 60).floor();
        return "Recent feeding history suggests hunger may be contributing to the crying. The last feeding was recorded ${feedH} hours ago.";      }
      return "Recent tracking does not currently suggest a strong hunger-related pattern.";
    }
    if (lower.contains("tired"))
    {
      if (sleepMins >= 60)
      {
        final sleepH = (sleepMins / 60).floor();
        return "Recent sleep history suggests tiredness may also be contributing to the crying. The baby has been awake for approximately ${sleepH} hours.";
      }
      return "Recent tracking does not currently suggest a strong tiredness-related pattern.";
    }

    if (lower.contains("discomfort"))
    {
      if (nappyType.contains("dirty") && nappyMins >= 30)
      {
        return "Recent nappy history suggests discomfort may also be contributing to the crying. The last recorded nappy was dirty and was changed ${nappyH} hours ago.";
      }
      if (nappyMins >= 180)
      {
        return "Recent nappy history suggests discomfort may also be contributing to the crying. The last recorded nappy change was ${nappyH} hours ago.";
      }
      return "Recent tracking does not currently suggest a strong discomfort-related pattern.";
    }
    return "Recent tracking may provide additional context for this cry.";
  }

  Future<Map<String, dynamic>> analyseNonPainContext({
    required String userId,
    required String babyId,
  }) async
  {
    final contextData = await _getTrackingContext(
      userId: userId,
      babyId: babyId,
    );

    final int feedMins = contextData["minsSinceFeed"] is int
        ? contextData["minsSinceFeed"]
        : -1;

    final int sleepMins = contextData["minsSinceSleep"] is int
        ? contextData["minsSinceSleep"]
        : -1;

    final int nappyMins = contextData["minsSinceNappy"] is int
        ? contextData["minsSinceNappy"]
        : -1;

    final String nappyType =
    (contextData["nappyType"] ?? "").toString().toLowerCase();

    final String cause = _pickContextLabel(
      feedMins: feedMins,
      sleepMins: sleepMins,
      nappyMins: nappyMins,
      nappyType: nappyType,
    );

    if (cause.isEmpty)
    {
      return {
        "hasContext": false,
        "cause": "",
        "message": "",
      };
    }

    final String message = _smartExplanation(
      label: cause,
      percent: 0,
      feedMins: feedMins,
      sleepMins: sleepMins,
      nappyMins: nappyMins,
      nappyType: nappyType,
    );

    return {
      "hasContext": true,
      "cause": cause,
      "message": message,
    };
  }

  Future<String> run({
    required String userId,
    required String babyId,
    required String assetPath,
    required List<Map<String, dynamic>> modelPairs,
  }) async
  {
    if (modelPairs.isNotEmpty &&
        modelPairs.first["label"].toString().toLowerCase() == "pain")
    {
      return "";
    }

    final result = await analyseNonPainContext(
      userId: userId,
      babyId: babyId,
    );

    if (result["hasContext"] == true)
    {
      return result["message"].toString();
    }

    return "Everything up-to-date!";
  }}