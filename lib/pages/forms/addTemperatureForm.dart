

import 'package:flutter/material.dart';

class AddTemperatureForm extends StatefulWidget
{
  final BuildContext parentContext;
  final Future<void> Function(double value, DateTime time) onSubmit;

  AddTemperatureForm({
    super.key,
    required this.parentContext,
    required this.onSubmit
});

  @override
  State<AddTemperatureForm> createState() => _AddTemperatureFormState();
}

class _AddTemperatureFormState extends State<AddTemperatureForm>
{
  final valueController = TextEditingController();
  bool _isSaving = false;

  Future<void> _Save() async
  {
    final raw = valueController.text.trim().replaceAll(",", ".");

    final value = double.tryParse(raw);

    final time = DateTime.now();

    if (value == null)
    {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Enter a valid temperature.")),
      );
      return;
    }

    if (value < 30 || value > 50)
    {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Temperature looks incorrect.")),
      );
      return;
    }

    setState(() => _isSaving = true);

    await widget.onSubmit(value, time);

    if (mounted)
    {
      Navigator.pop(context);
      ScaffoldMessenger.of(widget.parentContext).showSnackBar(
        SnackBar(content: Text("Temperature saved.")),
      );
    }
  }


  @override
  void dispose()
  {
    valueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context)
  {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Add Temperature",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),

        SizedBox(height: 16),

        TextField(
          controller: valueController,
          keyboardType: TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: "Temperature (C)",
            border: OutlineInputBorder(),
          ),
        ),

        SizedBox(height: 14),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isSaving ? null : _Save,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
            child: Text(_isSaving ? "Saving" : "Save Temperature"),
          ),
        ),

        SizedBox(height: 10),
      ],
    );
  }
  }
