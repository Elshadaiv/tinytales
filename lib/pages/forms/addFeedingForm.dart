import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class AddFeedingForm extends StatefulWidget {
  final BuildContext parentContext;
  final Future<void> Function(int amount, DateTime time) onSubmit;

   AddFeedingForm({
    super.key,
    required this.parentContext,
    required this.onSubmit,
  });

  @override
  State<AddFeedingForm> createState() => _AddFeedingFormState();
}

class _AddFeedingFormState extends State<AddFeedingForm> {
  final amountController = TextEditingController();
  DateTime selectedTime = DateTime.now();

  Future<void> _save() async
  {
    final text = amountController.text.trim();

    if (text.isEmpty)
    {
      ScaffoldMessenger.of(widget.parentContext).showSnackBar(
        const SnackBar(content: Text("Please enter an amount.")),
      );
      return;
    }

    final amount = int.tryParse(text);
    if (amount == null)
    {
      ScaffoldMessenger.of(widget.parentContext).showSnackBar(
        const SnackBar(content: Text("Amount must be a number.")),
      );
      return;
    }

    try {
      await widget.onSubmit(amount, selectedTime);

      ScaffoldMessenger.of(widget.parentContext).showSnackBar(
        const SnackBar(content: Text("Feeding tracked successfully")),
      );

      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(widget.parentContext).showSnackBar(
        const SnackBar(content: Text("Failed to track feeding.")),
      );
    }
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

        TextField(
          controller: amountController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: "Amount (ml)"),
        ),

        const SizedBox(height: 10),

        ElevatedButton(
          onPressed: _save,
          child:  Text("Save"),
        ),

         SizedBox(height: 20),
      ],
    );
  }
}