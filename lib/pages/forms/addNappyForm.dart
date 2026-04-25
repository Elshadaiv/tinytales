import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';

class AddNappyForm extends StatefulWidget {
  final BuildContext parentContext;
  final Function(String type, DateTime time, String? colour, String? notes, String? imageBase64) onSubmit;
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

  String? imageBase64;
  final ImagePicker picker = ImagePicker();

  void _save()
  {
    widget.onSubmit(
      selectedType,
      selectedTime,
      colorController.text.trim(),
      notesController.text.trim(),
      imageBase64,
    );

    Navigator.pop(context);

    ScaffoldMessenger.of(widget.parentContext).showSnackBar(
       SnackBar(content: Text("Nappy tracked")),
    );
  }


  Future<void> _pickImage() async
  {
    final XFile? image = await picker.pickImage(source: ImageSource.camera);

    if (image == null) return;
    final bytes = await image.readAsBytes();

    setState(()
    {
      imageBase64 = base64Encode(bytes);
    });
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
            DropdownMenuItem(value: "Wet + Dirty", child: Text("Wet + Dirty")),
            DropdownMenuItem(value: "dry", child: Text("Dry")),
            DropdownMenuItem(value: "unusual", child: Text("Unusual")),


          ],


          onChanged: (v) => setState(() => selectedType = v!),
        ),
        TextField(
          controller: colorController,
          decoration:  InputDecoration(labelText: "Colour "),
        ),
        TextField(
          controller: notesController,
          decoration:  InputDecoration(labelText: "Note "),
        ),

         SizedBox(height: 10),
        ElevatedButton(
          onPressed: _save,
          child:  Text("Save"),
        ),

        SizedBox(height: 12),

        Row(
          children: [
            ElevatedButton(
              onPressed: _pickImage,
              child: Text("Add Photo of Poo"),
            ),
            SizedBox(width: 10),
            if (imageBase64 != null)
              Icon(Icons.check_circle, color: Colors.green),
          ],
        ),
      ],
    );
  }
}
