import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';



class MilestoneCheckList9m extends StatefulWidget {
  final String babyId;

  MilestoneCheckList9m({
    super.key,
    required this.babyId,
  });


  @override
  State<MilestoneCheckList9m> createState() => _MilestoneCheckList9mState();

}

class _MilestoneCheckList9mState extends State<MilestoneCheckList9m>
{
  bool _loading = true;
  bool _saving = false;

  Map<String, bool> completed =
  {
  };

  final String docId = "9_months";

  final List<Map<String, dynamic>> sections =
  [
    {
      "title": "Motor skills",
      "items": [
        {"id": "pull_to_stand", "text": "Pull themselves to a standing position"},
        {"id": "crawl_hands_knees", "text": "Crawl on their hands and knees"},
        {"id": "grasp_cube_thumb_fingertips", "text": "Grasp a cube-shaped object using their thumb and fingertips"},
        {"id": "pick_small_object_thumb_second_finger", "text": "Pick up a small object using their thumb and the second finger on their hand"},
      ],
    },
    {
      "title": "Communication & hearing",
      "items": [
        {"id": "understand_simple_words", "text": "Begin to show that they understand some simple words, such as 'bye bye'"},
        {"id": "copy_actions_wave", "text": "Copy actions such as a wave and use it at different times of the day"},
      ],
    },
    {
      "title": "Social & emotional",
      "items": [
        {"id": "separation_anxiety", "text": "Get upset or distressed when separated from a parent or another carer"},
        {"id": "need_attention_cry", "text": "Need your attention and cry to get it"},
        {"id": "shy_around_strangers", "text": "Be shy around strangers and less familiar people"},
        {"id": "express_feelings", "text": "Express their feelings by laughing, screaming and crying"},
        {"id": "recognise_feelings_in_others", "text": "Start to recognise feelings in others (for example, get upset if another child is crying)"},
      ],
    },
    {
      "title": "Problem solving, learning & understanding",
      "items": [
        {"id": "look_for_hidden_object", "text": "Look for a toy when it is hidden (for example, lift a blanket to find it)"},
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
        title: Text("9 Months Milestones"),
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
                      "Contact your GP or public health nurse if you notice your baby is not holding objects, cannot move a toy from one hand to another, is not rolling, is not sitting independently, has not started to move around (for example bottom shuffling or crawling), cannot take weight on their legs when they're held in a supported standing position, or loses skills they had before.",
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
