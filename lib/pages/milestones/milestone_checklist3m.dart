import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';



class MilestoneCheckList2m extends StatefulWidget {
  final String babyId;

  MilestoneCheckList2m({
    super.key,
    required this.babyId,
  });


  @override
  State<MilestoneCheckList2m> createState() => _MilestoneCheckList2mState();

}

class _MilestoneCheckList2mState extends State<MilestoneCheckList2m>
{
  bool _loading = true;
  bool _saving = false;

  Map<String, bool> completed =
  {
  };

  final String docId = "3_months";

  final List<Map<String, dynamic>> sections =
  [
    {
      "title": "Motor skills",
      "items": [
        {"id": "lift_chest_tummy", "text": "Lift their chest up while lying on their tummy"},
        {"id": "head_upright_held", "text": "Keep their head in an upright position if they are being held"},
        {"id": "track_past_middle", "text": "Move their eyes to track an object moved past the middle of their body"},
        {"id": "hold_rattle_brief", "text": "Hold a rattle or toy for a brief period"},
        {"id": "hands_loose_half_time", "text": "Have their hands loose and not in fists for about half of the time"},
      ],
    },
    {
      "title": "Communication & hearing",
      "items": [
        {"id": "look_at_talker", "text": "Look at people who are talking"},
        {"id": "respond_to_voice", "text": "Respond to your voice"},
        {"id": "start_cooing", "text": "Start making cooing noises"},
      ],
    },
    {
      "title": "Social & emotional",
      "items": [
        {"id": "smile_back", "text": "Smile back when you smile at them"},
        {"id": "enjoy_chat_sing", "text": "Enjoy when you chat and sing to them"},
        {"id": "more_alert", "text": "Become more alert"},
        {"id": "awake_longer", "text": "Be awake for longer"},
        {"id": "more_interested_world", "text": "Be more interested in the world around them"},
        {"id": "soothed_picked_up", "text": "Be soothed by being picked up"},
      ],
    },
    {
      "title": "Problem solving, learning & understanding",
      "items": [
        {"id": "follow_up_down", "text": "Follow something moving up or down with their eyes"},
      ],
    },
  ];

  @override
    void initState()
  {
    super.initState();
    _load();
  }
  Future<void> _load() async
  {
    try
    {
      final ref = FirebaseFirestore.instance
          .collection("baby_profiles")
          .doc(widget.babyId)
          .collection("milestones")
          .doc(docId);

      final snap = await ref.get();
      if (snap.exists)
      {
        final data = snap.data() ?? {};
        final raw = data["completed"];

        if (raw is Map)
        {
          completed = raw.map((k, v) => MapEntry(k.toString(), v == true));
        }
      }
    }
    catch(e)
    {
    }

    if (mounted)
    {
      setState(()
      {
        _loading = false;
      });
    }
  }

  Future<void> _save() async
  {
    setState(() => _saving = true);
    try
    {
      final ref = FirebaseFirestore.instance
          .collection("baby_profiles")
          .doc(widget.babyId)
          .collection("milestones")
          .doc(docId);

      await ref.set(
        {
          "completed": completed,
          "updatedAt": FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    }

    catch (e)
    {
    }

    if (mounted)
    {
      setState(() => _saving = false);
    }
  }

  int _totalItems()
  {
    int total = 0;
    for (final s in sections)
    {
      total += (s["items"] as List).length;
    }
    return total;
  }

  int _doneItems()
  {
    int done = 0;
    for (final s in sections)
    {
      final items = s["items"] as List;

      for (final it in items)
      {
        final id = it["id"].toString();
        if (completed[id] == true)
        {
          done++;
        }
      }
    }
    return done;
  }


  @override
  Widget build(BuildContext context)
  {
    final total = _totalItems();
    final done = _doneItems();
    final progress = total == 0 ? 0.0 : done / total;

    return Scaffold(
      backgroundColor: Colors.grey[300],
      appBar: AppBar(
        backgroundColor: Colors.grey[300],
        title: Text("3 Months Milestones"),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: Colors.purple))
          : Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 6,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Progress",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: progress,
                    minHeight: 10,
                    backgroundColor: Colors.grey[200],
                    color: Colors.purple,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  SizedBox(height: 8),
                  Text("$done / $total completed"),
                ],
              ),
            ),

            SizedBox(height: 12),

            Expanded(
              child: ListView(
                children: [
                  for (final section in sections) ...[
                    SizedBox(height: 14),

                    Text(
                      section["title"].toString(),
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),

                    SizedBox(height: 8),

                    ...((section["items"] as List).map((item)
                    {
                      final id = item["id"].toString();
                      final text = item["text"].toString();
                      final isChecked = completed[id] == true;

                      return Container(
                        margin: EdgeInsets.only(bottom: 10),
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Checkbox(
                              value: isChecked,
                              shape: CircleBorder(),
                              onChanged: (val)
                              {
                                setState(()
                                {
                                  completed[id] = val == true;
                                });
                                _save();
                              },
                            ),

                            Expanded(
                              child: Text(
                                text,
                                style: TextStyle(fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList()),
                  ],

                  SizedBox(height: 10),

                  Container(
                    padding: EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      "If you are very concerned about your baby’s development, contact your GP or public health nurse.",
                      style: TextStyle(color: Colors.black54),
                    ),
                  ),

                  SizedBox(height: 20),
                ],
              ),
            ),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
                child: Text(_saving ? "Saving" : "Save"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
