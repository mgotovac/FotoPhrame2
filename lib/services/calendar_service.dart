import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/calendar_event.dart';
import '../models/calendar_config.dart';
import '../utils/constants.dart';

class CalendarService {
  Future<List<CalendarEvent>> fetchEvents(CalendarConfig config) async {
    final now = DateTime.now().toUtc().toIso8601String();
    final calendarId = Uri.encodeComponent(config.calendarId);

    final uri = Uri.parse(
        '$kGoogleCalendarBaseUrl/$calendarId/events'
        '?key=${config.apiKey}'
        '&timeMin=$now'
        '&maxResults=15'
        '&singleEvents=true'
        '&orderBy=startTime');

    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception(
          'Calendar API error: ${response.statusCode} ${response.body}');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final items = json['items'] as List? ?? [];

    return items
        .map((item) =>
            CalendarEvent.fromGoogleJson(item as Map<String, dynamic>))
        .toList();
  }
}
