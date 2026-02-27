import 'package:flutter/material.dart';
import '../../../models/calendar_config.dart';

class CalendarConfigEditor extends StatefulWidget {
  final CalendarConfig? config;
  final ValueChanged<CalendarConfig?> onChanged;

  const CalendarConfigEditor({
    super.key,
    this.config,
    required this.onChanged,
  });

  @override
  State<CalendarConfigEditor> createState() => _CalendarConfigEditorState();
}

class _CalendarConfigEditorState extends State<CalendarConfigEditor> {
  late TextEditingController _apiKeyController;
  late TextEditingController _calendarIdController;

  @override
  void initState() {
    super.initState();
    _apiKeyController =
        TextEditingController(text: widget.config?.apiKey ?? '');
    _calendarIdController =
        TextEditingController(text: widget.config?.calendarId ?? '');
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _calendarIdController.dispose();
    super.dispose();
  }

  void _onChanged() {
    final apiKey = _apiKeyController.text.trim();
    final calendarId = _calendarIdController.text.trim();

    if (apiKey.isEmpty || calendarId.isEmpty) {
      widget.onChanged(null);
    } else {
      widget.onChanged(CalendarConfig(
        apiKey: apiKey,
        calendarId: calendarId,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _apiKeyController,
          decoration: const InputDecoration(
            labelText: 'Google Calendar API Key',
            hintText: 'AIza...',
            border: OutlineInputBorder(),
          ),
          obscureText: true,
          onChanged: (_) => _onChanged(),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _calendarIdController,
          decoration: const InputDecoration(
            labelText: 'Calendar ID',
            hintText: 'your-email@gmail.com or calendar ID',
            border: OutlineInputBorder(),
          ),
          onChanged: (_) => _onChanged(),
        ),
        const SizedBox(height: 8),
        Text(
          'Note: The calendar must be set to public for API key access.',
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
