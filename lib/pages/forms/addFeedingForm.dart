import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class AddFeedingForm extends StatefulWidget {
  final BuildContext parentContext;
  final Future<void> Function(Map<String, dynamic> entry) onSubmit;

   AddFeedingForm({
    super.key,
    required this.parentContext,
    required this.onSubmit,
  });

  @override
  State<AddFeedingForm> createState() => _AddFeedingFormState();
}

class _AddFeedingFormState extends State<AddFeedingForm> {
  String feedType = "bottle";

  final amountController = TextEditingController();
  String milkType = "formula";

  String side = "left";
  final breastDurationController = TextEditingController();

  final foodController = TextEditingController();

  bool _isSaving = false;

  Future<void> _save() async
  {
    final time = DateTime.now();

    if (feedType == "bottle")
    {
      final text = amountController.text.trim();
      final amount = int.tryParse(text);
      if (amount == null)
      {
        ScaffoldMessenger.of(widget.parentContext).showSnackBar(
          SnackBar(content: Text("Amount must be a number.")),
        );
        return;
      }
      if (amount <= 0)
      {
        ScaffoldMessenger.of(widget.parentContext).showSnackBar(
           SnackBar(content: Text("Amount must be greater than 0 ml.")),
        );
        return;
      }
      if (amount > 500)
      {
        ScaffoldMessenger.of(widget.parentContext).showSnackBar(
          SnackBar(content: Text("Amount looks too high. Please check and try again.")),
        );
        return;
      }
      setState(() => _isSaving = true);

      await widget.onSubmit({
        "type": "bottle",
        "amount": amount,
        "milkType": milkType,
        "time": time.toIso8601String(),
      });
    }

    else if (feedType == "breast")
    {
      final mins = int.tryParse(breastDurationController.text.trim());

      if (mins == null || mins <= 0)
      {
        ScaffoldMessenger.of(widget.parentContext).showSnackBar(
          SnackBar(content: Text("Please enter a valid duration in minutes.")),
        );
        return;
      }
      if (mins > 120)
      {
        ScaffoldMessenger.of(widget.parentContext).showSnackBar(
          SnackBar(content: Text("Duration looks too long. Please check and try again.")),
        );
        return;
      }

      setState(() => _isSaving = true);

      await widget.onSubmit({
        "type": "breast",
        "side": side,
        "durationMinutes": mins,
        "time": time.toIso8601String(),
      });
    }

    else if (feedType == "solids")
    {
      final food = foodController.text.trim();

      if (food.isEmpty)
      {
        ScaffoldMessenger.of(widget.parentContext).showSnackBar(
          SnackBar(content: Text("Please enter what the baby ate.")),
        );
        return;
      }

      setState(() => _isSaving = true);

      await widget.onSubmit({
        "type": "solids",
        "food": food,
        "time": time.toIso8601String(),
      });
    }

    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(widget.parentContext).showSnackBar(
      SnackBar(content: Text("Feeding tracked successfully")),
    );
  }

  Widget _typeSelect(String label, String value)
  {
    final bool selected = feedType == value;
    return GestureDetector(
      onTap: ()
      { setState(()
      {
        feedType = value;
      });
        },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? Colors.purple : Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _sideSelect(String label, String value)
  {
    final bool selected = side == value;
    return GestureDetector(
      onTap: ()
      {
        setState(()
        {
          side = value;
        });
        },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        margin: EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: selected ? Colors.purple : Colors.grey[200],
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _milkTypeSelector(String label, String value)
  {
    final bool selected = milkType == value;
    return GestureDetector(
      onTap: () {
        setState(()
        {
          milkType = value;
        });
        },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        margin: EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: selected ? Colors.purple : Colors.grey[200],
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context)
  {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
         Text(
          "Add Feeding",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),

        SizedBox(height: 14),

        Row(
          children: [
            _typeSelect("Bottle", "bottle"),
            SizedBox(width: 8),
            _typeSelect("Breast", "breast"),
            SizedBox(width: 8),
            _typeSelect("Solids", "solids"),
          ],
        ),

        SizedBox(height: 18),

        if (feedType == "bottle") ...[
          TextField(
            controller: amountController,
            keyboardType: TextInputType.number, decoration: InputDecoration(labelText: "Amount ml"),
          ),
          SizedBox(height: 12),
          Text("Milk type", style: TextStyle(fontWeight: FontWeight.w600)),
          SizedBox(height: 8),
          Row(
            children: [
              _milkTypeSelector("Formula", "formula"),
              _milkTypeSelector("Expressed", "expressed"),
            ],
          ),
          SizedBox(height: 18),
        ],
        if (feedType == "breast") ...[
          Text("Side", style: TextStyle(fontWeight: FontWeight.w600)),
          SizedBox(height: 8),
          Row(
            children: [
              _sideSelect("Left", "left"),
              _sideSelect("Right", "right"),
              _sideSelect("Both", "both"),
            ],
          ),
          SizedBox(height: 12),
          TextField(
            controller: breastDurationController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: "Duration in minutes"),
          ),
          SizedBox(height: 18),
        ],
        if (feedType == "solids") ...[
          TextField(
            controller: foodController,
            decoration: InputDecoration(labelText: "What did baby eat?",
            ),
          ),
          SizedBox(height: 18),
        ],
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(onPressed: _isSaving ? null : _save, child: Text(_isSaving ? "Saving..." : "Save"),
          ),
        ),

         SizedBox(height: 20),
      ],
    );
  }
}