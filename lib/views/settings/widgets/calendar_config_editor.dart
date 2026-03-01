import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../../models/calendar_config.dart';

/// Full-screen editor for a single CalendarConfig.
/// Pass [initial] to edit an existing entry; omit (null) to create a new one.
/// Returns a [CalendarConfig] via Navigator.pop on save.
class CalendarConfigEditor extends StatefulWidget {
  final CalendarConfig? initial;

  const CalendarConfigEditor({super.key, this.initial});

  @override
  State<CalendarConfigEditor> createState() => _CalendarConfigEditorState();
}

class _CalendarConfigEditorState extends State<CalendarConfigEditor> {
  late TextEditingController _nameController;
  late TextEditingController _icsUrlController;

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.initial?.name ?? '');
    _icsUrlController =
        TextEditingController(text: widget.initial?.icsUrl ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _icsUrlController.dispose();
    super.dispose();
  }

  void _save() {
    final name = _nameController.text.trim();
    final icsUrl = _icsUrlController.text.trim();
    if (name.isEmpty || icsUrl.isEmpty) return;

    final config = CalendarConfig(
      id: widget.initial?.id ?? const Uuid().v4(),
      name: name,
      icsUrl: icsUrl,
    );
    Navigator.of(context).pop(config);
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.initial == null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isNew ? 'Add Calendar' : 'Edit Calendar'),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('Save'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Calendar name',
              hintText: 'e.g. Work, Personal, Family',
              border: OutlineInputBorder(),
            ),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _icsUrlController,
            decoration: const InputDecoration(
              labelText: 'Calendar ICS URL',
              hintText: 'https://calendar.google.com/calendar/ical/...',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.url,
          ),
          const SizedBox(height: 16),
          Text(
            'How to get your private calendar URL:\n'
            '1. Open Google Calendar → Settings (⚙)\n'
            '2. Click your calendar name in the left sidebar\n'
            '3. Scroll to "Secret address in iCal format"\n'
            '4. Copy the URL and paste it above\n'
            'Works with any calendar — no need to make it public.',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
