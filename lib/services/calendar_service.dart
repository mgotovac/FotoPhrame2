import 'package:http/http.dart' as http;
import '../models/calendar_event.dart';
import '../models/calendar_config.dart';

class CalendarService {
  Future<List<CalendarEvent>> fetchEvents(List<CalendarConfig> configs) async {
    final futures = configs.map(_fetchOne).toList();
    final results = await Future.wait(futures, eagerError: false);
    final seen = <String>{};
    final merged = results
        .expand((r) => r)
        .where((e) => seen.add(e.id))
        .toList()
      ..sort((a, b) => a.start.compareTo(b.start));
    return merged;
  }

  Future<List<CalendarEvent>> _fetchOne(CalendarConfig config) async {
    final response = await http.get(Uri.parse(config.icsUrl));
    if (response.statusCode != 200) {
      throw Exception('Calendar fetch error: ${response.statusCode}');
    }
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final cutoff = today.add(const Duration(days: 5));

    final result = <CalendarEvent>[];
    for (final (base, rrule) in _parseIcs(response.body, config.id)) {
      if (rrule != null) {
        result.addAll(_expandRrule(base, rrule, today, cutoff));
      } else if (!base.start.isBefore(today) && base.start.isBefore(cutoff)) {
        result.add(base);
      }
    }
    return result;
  }

  // Returns (event, rrule?) for every VEVENT in the ICS.
  List<(CalendarEvent, String?)> _parseIcs(String ics, String calendarId) {
    // Unfold continuation lines (RFC 5545 §3.1)
    final unfolded = ics
        .replaceAll('\r\n ', '')
        .replaceAll('\r\n\t', '')
        .replaceAll('\n ', '')
        .replaceAll('\n\t', '');

    final lines = unfolded.contains('\r\n')
        ? unfolded.split('\r\n')
        : unfolded.split('\n');

    final results = <(CalendarEvent, String?)>[];
    Map<String, String>? current;

    for (final line in lines) {
      if (line == 'BEGIN:VEVENT') {
        current = {};
      } else if (line == 'END:VEVENT' && current != null) {
        final pair = _buildEvent(current, calendarId);
        if (pair != null) results.add(pair);
        current = null;
      } else if (current != null) {
        final colonIdx = line.indexOf(':');
        if (colonIdx == -1) continue;
        final rawKey = line.substring(0, colonIdx);
        final value = line.substring(colonIdx + 1);
        final key = rawKey.contains(';')
            ? rawKey.substring(0, rawKey.indexOf(';'))
            : rawKey;
        current[key] = value;
        current['_raw_$key'] = rawKey;
      }
    }

    return results;
  }

  (CalendarEvent, String?)? _buildEvent(Map<String, String> props, String calendarId) {
    final uid = props['UID'] ?? '';
    final title = props['SUMMARY'] ?? '(No title)';
    final dtStart = props['DTSTART'];
    final dtEnd = props['DTEND'];
    if (dtStart == null) return null;

    final rawDtStart = props['_raw_DTSTART'] ?? 'DTSTART';
    // VALUE=DATE (all-day) but NOT VALUE=DATE-TIME (timed)
    final hasValueDate = rawDtStart
        .split(';')
        .any((p) => p.toUpperCase() == 'VALUE=DATE');
    final isAllDay = hasValueDate || _isDateOnly(dtStart);

    final start = _parseDateTime(dtStart, isAllDay);
    final end = _parseDateTime(dtEnd ?? dtStart, isAllDay);
    if (start == null || end == null) return null;

    final event = CalendarEvent(
      id: uid,
      title: title,
      start: start,
      end: end,
      isAllDay: isAllDay,
      calendarId: calendarId,
    );
    return (event, props['RRULE']);
  }

  bool _isDateOnly(String value) =>
      RegExp(r'^\d{8}$').hasMatch(value.trim());

  DateTime? _parseDateTime(String value, bool isAllDay) {
    final v = value.trim();
    try {
      if (isAllDay) {
        return DateTime(
          int.parse(v.substring(0, 4)),
          int.parse(v.substring(4, 6)),
          int.parse(v.substring(6, 8)),
        );
      } else if (v.endsWith('Z')) {
        return DateTime.utc(
          int.parse(v.substring(0, 4)),
          int.parse(v.substring(4, 6)),
          int.parse(v.substring(6, 8)),
          int.parse(v.substring(9, 11)),
          int.parse(v.substring(11, 13)),
          int.parse(v.substring(13, 15)),
        ).toLocal();
      } else {
        return DateTime(
          int.parse(v.substring(0, 4)),
          int.parse(v.substring(4, 6)),
          int.parse(v.substring(6, 8)),
          int.parse(v.substring(9, 11)),
          int.parse(v.substring(11, 13)),
          int.parse(v.substring(13, 15)),
        );
      }
    } catch (_) {
      return null;
    }
  }

  // Expands a recurring event within [today, cutoff).
  // Handles FREQ=DAILY, WEEKLY, MONTHLY, YEARLY.
  List<CalendarEvent> _expandRrule(
    CalendarEvent base,
    String rrule,
    DateTime today,
    DateTime cutoff,
  ) {
    // Parse key=value pairs from RRULE string
    final params = <String, String>{};
    for (final part in rrule.split(';')) {
      final eq = part.indexOf('=');
      if (eq > 0) params[part.substring(0, eq)] = part.substring(eq + 1);
    }

    final freq = params['FREQ'] ?? '';
    final interval = int.tryParse(params['INTERVAL'] ?? '') ?? 1;
    final until = params['UNTIL'] != null
        ? _parseDateTime(params['UNTIL']!, false)
        : null;

    const dayMap = {
      'MO': 1, 'TU': 2, 'WE': 3, 'TH': 4, 'FR': 5, 'SA': 6, 'SU': 7,
    };
    // BYDAY values — strip any ordinal prefix (e.g. "2MO" → "MO")
    final byDay = (params['BYDAY'] ?? '')
        .split(',')
        .where((s) => s.isNotEmpty)
        .map((s) => s.replaceAll(RegExp(r'^-?\d*'), '').toUpperCase())
        .toList();

    final duration = base.end.difference(base.start);
    final timeOfDay = Duration(
      hours: base.start.hour,
      minutes: base.start.minute,
      seconds: base.start.second,
    );

    bool inWindow(DateTime d) =>
        !d.isBefore(today) &&
        d.isBefore(cutoff) &&
        (until == null || !d.isAfter(until));

    CalendarEvent makeOccurrence(DateTime date) {
      final s = DateTime(date.year, date.month, date.day).add(timeOfDay);
      return CalendarEvent(
        id: '${base.id}_${s.millisecondsSinceEpoch}',
        title: base.title,
        start: s,
        end: s.add(duration),
        isAllDay: base.isAllDay,
        calendarId: base.calendarId,
      );
    }

    final results = <CalendarEvent>[];
    final baseDay =
        DateTime(base.start.year, base.start.month, base.start.day);

    switch (freq) {
      case 'DAILY':
        // Jump from baseDay forward to today in multiples of interval
        final daysFromBase = today.difference(baseDay).inDays;
        final stepsToToday =
            daysFromBase > 0 ? (daysFromBase / interval).ceil() : 0;
        var step = baseDay.add(Duration(days: stepsToToday * interval));
        while (step.isBefore(cutoff)) {
          if (inWindow(step)) results.add(makeOccurrence(step));
          step = step.add(Duration(days: interval));
        }

      case 'WEEKLY':
        for (var i = 0; i < 5; i++) {
          final day = today.add(Duration(days: i));
          if (!inWindow(day)) continue;
          // Does this weekday match the BYDAY list (or base weekday if no BYDAY)?
          final wd = day.weekday;
          final dayMatches = byDay.isEmpty
              ? wd == base.start.weekday
              : byDay.any((d) => dayMap[d] == wd);
          if (!dayMatches) continue;
          // Check interval in weeks from baseDay
          final weeksDiff = day.difference(baseDay).inDays ~/ 7;
          if (weeksDiff % interval == 0) results.add(makeOccurrence(day));
        }

      case 'MONTHLY':
        for (var i = 0; i < 5; i++) {
          final day = today.add(Duration(days: i));
          if (!inWindow(day)) continue;
          if (day.day == base.start.day) results.add(makeOccurrence(day));
        }

      case 'YEARLY':
        for (var i = 0; i < 5; i++) {
          final day = today.add(Duration(days: i));
          if (!inWindow(day)) continue;
          if (day.month == base.start.month && day.day == base.start.day) {
            results.add(makeOccurrence(day));
          }
        }
    }

    return results;
  }
}
