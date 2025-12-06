import 'package:flutter/material.dart';

class AddNappyForm extends StatefulWidget {
  final BuildContext parentContext;
  final Function(String type, DateTime time, String? colour, String? notes) onSubmit;

   AddNappyForm(
      {
    super.key,
    required this.parentContext,
    required this.onSubmit,
  }
  );

  @override
  State<AddNappyForm> createState() => _AddNappyFormState();
}

class _AddNappyFormState extends State<AddNappyForm>
{

  String selectedType = "wet";
  final colorController = TextEditingController();
  final notesController = TextEditingController();
  DateTime selectedTime = DateTime.now();

  void _save()
  {
    widget.onSubmit(
      selectedType,
      selectedTime,
      colorController.text.trim(),
      notesController.text.trim(),
    );

    Navigator.pop(context);

    ScaffoldMessenger.of(widget.parentContext).showSnackBar(
       SnackBar(content: Text("Nappy tracked")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [Text("Add Nappy", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),

         SizedBox(height: 10),
        DropdownButton<String>
          (
          value: selectedType,
          items:
          [
            DropdownMenuItem(value: "wet", child: Text("Wet")),
            DropdownMenuItem(value: "dirty", child: Text("Dirty")),
            DropdownMenuItem(value: "both", child: Text("Both")),
          ],


          onChanged: (v) => setState(() => selectedType = v!),
        ),
        TextField(
          controller: colorController,
          decoration:  InputDecoration(labelText: "Colour (optional)"),
        ),
        TextField(
          controller: notesController,
          decoration:  InputDecoration(labelText: "Note (optional)"),
        ),

         SizedBox(height: 10),
        ElevatedButton(
          onPressed: _save,
          child:  Text("Save"),
        ),

         SizedBox(height: 10),
      ],
    );
  }
}
