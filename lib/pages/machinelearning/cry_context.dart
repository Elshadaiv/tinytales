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
    final sleep = await _latestEntry(path: "users/$userId/tracking/$babyId/sleep", timeKey: "endTime",);
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

  List<Map<String, dynamic>> _boostWithContext({
    required List<Map<String, dynamic>> modelPairs,
    required Map<String, dynamic> ctx,
    required String boostMode,
  })
  {
    if (modelPairs.isEmpty)
    {
      return modelPairs;
    }

    final int feedMins = ctx["minsSinceFeed"] is int
        ? ctx["minsSinceFeed"] : -1;
    final int sleepMins = ctx["minsSinceSleep"] is int
        ? ctx["minsSinceSleep"] : -1;
    final int nappyMins = ctx["minsSinceNappy"] is int
        ? ctx["minsSinceNappy"] : -1;
    final String nappyType = (ctx["nappyType"] ?? "").toString();

    double hungryW = 1.0;
    double tiredW = 1.0;
    double discomfortW = 1.0;

    if (feedMins >= 900)
      hungryW *= 4.20;
    else if (feedMins >= 720)
      hungryW *= 2.70;
    else if (feedMins >= 600)
      hungryW *= 2.40;
    else if (feedMins >= 480)
      hungryW *= 2.10;
    else if (feedMins >= 360)
      hungryW *= 1.85;
    else if (feedMins >= 240)
      hungryW *= 1.65;
    else if (feedMins >= 180)
      hungryW *= 1.45;
    else if (feedMins >= 120)
      hungryW *= 1.20;

    if (sleepMins >= 210)
      tiredW *= 3.50;
    else if (sleepMins >= 150)
      tiredW *= 2.35;
    else if (sleepMins >= 90)
      tiredW *= 2.00;

    if (nappyMins >= 900)
      discomfortW *= 4.20;
    else if (nappyMins >= 720)
      discomfortW *= 2.70;
    else if (nappyMins >= 600)
      discomfortW *= 2.40;
    else if (nappyMins >= 480)
      discomfortW *= 2.10;
    else if (nappyMins >= 360)
      discomfortW *= 1.85;
    else if (nappyMins >= 240)
      discomfortW *= 1.65;
    else if (nappyMins >= 180)
      discomfortW *= 1.45;
    else if (nappyMins >= 120)
      discomfortW *= 1.20;

    if (nappyType.contains("dirty"))
      discomfortW *= 1.15;

    if (boostMode == "hungry")
    {
      tiredW = 1.0;
      discomfortW = 1.0;
    }
    else if (boostMode == "tired")
    {
      hungryW = 1.0;
      discomfortW = 1.0;
    }
    else if (boostMode == "discomfort")
    {
      hungryW = 1.0;
      tiredW = 1.0;
    }
    else
    {
      hungryW = 1.0;
      tiredW = 1.0;
      discomfortW = 1.0;
    }

    final boosted = modelPairs.map((p)
    {
      final label = p["label"].toString().toLowerCase();
      final score = p["score"] is double ? p["score"] : (p["score"] as num).toDouble();

      double w = 1.0;
      if (label.contains("hungry"))
        w = hungryW;
      else if (label.contains("tired"))
        w = tiredW;
      else if (label.contains("discomfort"))
        w = discomfortW;

      final newScore = score * w;
      return
        {
          "label": p["label"],
          "score": newScore,
        };
    }).toList();
    double sum = 0.0;
    for (final p in boosted)
    {
      sum += (p["score"] as double);
    }
    if (sum <= 0)
    {
      return modelPairs;
    }

    final out = boosted.map((p)
    {
      final s = (p["score"] as double) / sum;
      return
        {
          "label": p["label"],
          "score": s,
          "percent": (s * 100).round(),
        };
    }).toList();
    out.sort((a, b) => (b["score"] as double).compareTo(a["score"] as double));
    return out;
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
    else if (feedMins >= 180)
      hungryScore = 1;

    int tiredScore = 0;
    if (sleepMins >= 210)
      tiredScore = 3;
    else if (sleepMins >= 150)
      tiredScore = 2;
    else if (sleepMins >= 90)
      tiredScore = 1;

    int discomfortScore = 0;
    if (nappyType.contains("dirty") && nappyMins >= 30)
      discomfortScore = 4;
    else if (nappyMins >= 210)
      discomfortScore = 3;
    else if (nappyMins >= 150)
      discomfortScore = 2;
    else if (nappyMins >= 90)
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
  })
  {
    String timeLine = "";
    int toHours(int mins)
    {
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
        timeLine = "since the baby hasn’t been fed in ${feedH} hours";
        return "$timeLine, we’re $percent% confident this is a hungry cry.";
      }
      return "Everything up-to-date!";
    }
    if (lower.contains("tired"))
    {
      if (sleepMins >= 60)
      {
        final sleepH = (sleepMins / 60).floor();
        timeLine = "since the baby hasn’t slept in ${sleepH} hours";
        return "$timeLine, we’re $percent% confident this is a tired cry.";
      }
      return "Everything up-to-date!";
    }

    if (lower.contains("discomfort"))
    {
      if (nappyH >= 0)
      {
        if (nappyType.contains("dirty"))
        {
          timeLine = "since the last nappy was dirty and changed ${nappyH} hours ago";
        }
        else
        {
          timeLine = "since the last nappy change was ${nappyH} hours ago";
        }
      }
      else
      {
        timeLine = "based on nappy history";
      }
      return "$timeLine, we’re $percent% confident this is a discomfort/ pain cry";
    }
    return "we’re $percent% confident this is $label.";
  }

  Future<String> run({
    required String userId,
    required String babyId,
    required String assetPath,
    required List<Map<String, dynamic>> modelPairs,
  }) async
  {
    final contextData = await _getTrackingContext(
      userId: userId,
      babyId: babyId,
    );

    final int feedMins = contextData["minsSinceFeed"] is int ? contextData["minsSinceFeed"] : -1;
    final int sleepMins = contextData["minsSinceSleep"] is int ? contextData["minsSinceSleep"] : -1;
    final int nappyMins = contextData["minsSinceNappy"] is int ? contextData["minsSinceNappy"] : -1;
    final String nappyType = (contextData["nappyType"] ?? "").toString().toLowerCase();

    final String contextPick = _pickContextLabel(
      feedMins: feedMins,
      sleepMins: sleepMins,
      nappyMins: nappyMins,
      nappyType: nappyType,
    );

    final bool allowBoost = contextPick.isNotEmpty;

    String rawText = "";
    for (final p in modelPairs.take(2))
    {
      rawText = "$rawText${p["label"]}: ${p["percent"]}%\n";
    }

    String smartLine = "Everything up-to-date!";

    if (allowBoost)
    {
      final boosted = _boostWithContext(
        modelPairs: modelPairs,
        ctx: contextData,
        boostMode: contextPick,
      );

      final top = boosted.isNotEmpty ? boosted.first : null;
      if (top != null)
      {
        final String finalLabel = (contextPick.isNotEmpty && top["label"].toString().toLowerCase() != contextPick)
            ? contextPick.substring(0, 1).toUpperCase() + contextPick.substring(1)
            : top["label"].toString();

        final int finalPercent = top["percent"] is int
            ? top["percent"] as int
            : int.tryParse(top["percent"].toString()) ?? 0;

        smartLine = _smartExplanation(
          label: finalLabel,
          percent: finalPercent,
          feedMins: feedMins,
          sleepMins: sleepMins,
          nappyMins: nappyMins,
          nappyType: nappyType,
        );
      }
    }
    else
    {
      smartLine = "Everything up-to-date!";
    }
    return smartLine;
  }
}