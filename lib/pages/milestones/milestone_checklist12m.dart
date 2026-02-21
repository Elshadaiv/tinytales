import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';



class MilestoneCheckList12m extends StatefulWidget {
  final String babyId;

  MilestoneCheckList12m({
    super.key,
    required this.babyId,
  });


  @override
  State<MilestoneCheckList12m> createState() => _MilestoneCheckList12mState();

}

class _MilestoneCheckList12mState extends State<MilestoneCheckList12m>
{
  bool _loading = true;
  bool _saving = false;

  Map<String, bool> completed =
  {
  };

  final String docId = "12_months";

  final List<Map<String, dynamic>> sections =
  [
    {
      "title": "Motor skills",
      "items": [
        {"id": "first_steps_without_help", "text": "Take their first steps without help"},
        {"id": "pincer_grasp_small_objects", "text": "Use their index finger and thumb to pick up small objects"},
      ],
    },
    {
      "title": "Communication & hearing",
      "items": [
        {"id": "use_mama_dada_correctly", "text": "Use the words 'dada' and 'mama' in the right situations"},
        {"id": "point_at_objects", "text": "Point at objects they want to show you, such as a toy"},
        {"id": "respond_to_name", "text": "Recognise and respond to their name when you call them"},
        {"id": "understand_simple_instructions", "text": "Understand everyday words and respond to simple instructions such as 'come here'"},
        {"id": "enjoy_rhymes_and_songs", "text": "Enjoy rhymes and songs when you do the actions"},
      ],
    },
    {
      "title": "Social & emotional",
      "items": [
        {"id": "solitary_play", "text": "Play by themselves (solitary play)"},
        {"id": "offer_toy_to_mirror", "text": "Offer a toy to their reflection in a mirror"},
      ],
    },
    {
      "title": "Problem solving, learning & understanding",
      "items": [
        {"id": "remove_lid_find_toy", "text": "Remove a lid to find toys"},
        {"id": "throw_toys_follow_with_eyes", "text": "Throw toys onto the floor and follow them with their eyes"},
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
        title: Text("12 Months Milestones"),
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
                      "Contact your GP or public health nurse if you notice your baby has no form of independent mobility (such as crawling, commando crawling or bottom shuffle), is not pulling to stand from a sitting position, or loses skills they had before.",
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
