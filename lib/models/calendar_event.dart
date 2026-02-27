class CalendarEvent {
  final String id;
  final String title;
  final DateTime start;
  final DateTime end;
  final bool isAllDay;

  const CalendarEvent({
    required this.id,
    required this.title,
    required this.start,
    required this.end,
    required this.isAllDay,
  });

  factory CalendarEvent.fromGoogleJson(Map<String, dynamic> json) {
    final startObj = json['start'] as Map<String, dynamic>;
    final endObj = json['end'] as Map<String, dynamic>;
    final isAllDay = startObj.containsKey('date');

    DateTime parseStart;
    DateTime parseEnd;

    if (isAllDay) {
      parseStart = DateTime.parse(startObj['date'] as String);
      parseEnd = DateTime.parse(endObj['date'] as String);
    } else {
      parseStart = DateTime.parse(startObj['dateTime'] as String);
      parseEnd = DateTime.parse(endObj['dateTime'] as String);
    }

    return CalendarEvent(
      id: json['id'] as String,
      title: json['summary'] as String? ?? '(No title)',
      start: parseStart,
      end: parseEnd,
      isAllDay: isAllDay,
    );
  }
}
