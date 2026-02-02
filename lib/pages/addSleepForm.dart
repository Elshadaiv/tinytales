import 'package:flutter/material.dart';



class AddSleepForm extends StatefulWidget {
  final BuildContext parentContext;
  final Future<void> Function(DateTime startTime, DateTime endTime, String notes) onSubmit;

  AddSleepForm({
    super.key,
    required this.parentContext,
    required this.onSubmit,
  });

  @override
  State<AddSleepForm> createState () => _AddSleepFormState();
}



class _AddSleepFormState extends State<AddSleepForm>
{
  DateTime? _startTime;
  DateTime? _endTime;
  final notesController = TextEditingController();
  bool _isSaving = false;

  Future<DateTime?> _pickDateTime(DateTime initial) async
  {
    final date = await showDatePicker(context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if(date == null)
    {
      return null;
    }

    final time = await showTimePicker(context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );

    if (time == null)
      {
      return null;
      }
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  String _fmt(DateTime dt)
  {
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    return "$day/$month/${dt.year} $hour:$minute";
  }

  String _fmtDuration(int minutes)
  {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (h == 0)
      return "${minutes}m";
    if (m == 0)
      return "${h}h";
    return "${h}h ${m}m";
  }


  Future<void> Save() async
  {
    if (_startTime == null || _endTime == null)
    {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(" Select start and end time")),
      );
      return;
    }

    if (!_endTime!.isAfter(_startTime!))
    {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("End time must be after start time")),
      );
      return;
    }

    setState(() => _isSaving = true);

    await widget.onSubmit(_startTime!, _endTime!, notesController.text.trim());

    if (mounted)
    {
      Navigator.pop(context);
      ScaffoldMessenger.of(widget.parentContext).showSnackBar(
        SnackBar(content: Text("Sleep saved")),
      );
    }
  }

  @override
  void dispose()
  {
    notesController.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context)
  {
    final now = DateTime.now();
    final canShowDuration = _startTime != null && _endTime != null && _endTime!.isAfter(_startTime!);
    final durationMinutes = canShowDuration ? _endTime!.difference(_startTime!).inMinutes : 0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Add Sleep",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 16),

        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text("Start Time"),
          subtitle: Text(_startTime == null ? "Select start time" : _fmt(_startTime!)),
          trailing: Icon(Icons.access_time),
          onTap: () async
          {
            final picked = await _pickDateTime(_startTime ?? now);
            if (picked != null)
              setState(() => _startTime = picked);
          },
        ),

        ListTile(
          contentPadding: EdgeInsets.zero,
          title:  Text("End Time"),
          subtitle: Text(_endTime == null ? "Select end time" : _fmt(_endTime!)),
          trailing:  Icon(Icons.access_time),
          onTap: () async
          {
            final picked = await _pickDateTime(_endTime ?? (_startTime ?? now));

            if (picked != null)
              setState(() => _endTime = picked);
          },
        ),


        if (canShowDuration) ...[
          SizedBox(height: 6),
          Text(
            "Duration: ${_fmtDuration(durationMinutes)}",
            style: TextStyle(color: Colors.grey[800], fontWeight: FontWeight.w600),
          ),
        ],

        SizedBox(height: 12),

        TextField(
          controller: notesController,
          decoration: InputDecoration(
            labelText: "Notes",
            border: OutlineInputBorder(),
          ),
          maxLines: 2,
        ),

        SizedBox(height: 14),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isSaving ? null : Save,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
            child: Text(_isSaving ? "Saving" : "Save Sleep"),
          ),
        ),

        SizedBox(height: 10),

      ],
    );
  }
}
