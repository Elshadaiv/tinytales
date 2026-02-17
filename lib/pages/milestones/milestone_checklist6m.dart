import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';



class MilestoneCheckList6m extends StatefulWidget {
  final String babyId;

  MilestoneCheckList6m({
    super.key,
    required this.babyId,
  });


  @override
  State<MilestoneCheckList6m> createState() => _MilestoneCheckList6mState();

}

class _MilestoneCheckList6mState extends State<MilestoneCheckList6m>
{
  bool _loading = true;
  bool _saving = false;

  Map<String, bool> completed =
  {
  };

  final String docId = "6_months";

  final List<Map<String, dynamic>> sections =
  [
    {
      "title": "Motor skills",
      "items": [
        {"id": "sit_with_support", "text": "Be able to sit with support"},
        {"id": "roll_back_to_front", "text": "Roll their body from back to front"},
        {"id": "move_hand_to_hand", "text": "Be able to move things from 1 hand to the other"},
      ],
    },
    {
      "title": "Communication & hearing",
      "items": [
        {"id": "babble_sounds", "text": "Make babbling sounds such as 'baba' and 'gagaga'"},
        {"id": "turn_to_new_sounds", "text": "Turn and look towards new sounds and noises"},
        {"id": "look_when_people_enter", "text": "Turn and look towards people when they enter the room"},
        {"id": "enjoy_back_and_forth", "text": "Enjoy talking back and forth with you using different cooing and babble noises"},
      ],
    },
    {
      "title": "Social & emotional",
      "items": [
        {"id": "prefer_particular_person", "text": "Show a preference for a particular person"},
        {"id": "upset_caregiver_not_seen", "text": "Get upset when they cannot see their main caregiver"},
        {"id": "recognise_familiar_faces", "text": "Recognise familiar faces"},
        {"id": "react_tone_of_voice", "text": "React to different tones of voice"},
        {"id": "smile_more_often", "text": "Smile more often, especially at their parents or main caregiver"},
        {"id": "hold_bottle", "text": "Try to hold their bottle while drinking"},
      ],
    },
    {
      "title": "Problem solving, learning & understanding",
      "items": [
        {"id": "look_floor_drop_toy", "text": "Look to the floor when they drop a toy"},
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
    catch (e)
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
        title: Text("6 Months Milestones"),
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
