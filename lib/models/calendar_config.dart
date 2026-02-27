class CalendarConfig {
  final String apiKey;
  final String calendarId;

  const CalendarConfig({
    required this.apiKey,
    required this.calendarId,
  });

  Map<String, dynamic> toJson() => {
        'apiKey': apiKey,
        'calendarId': calendarId,
      };

  factory CalendarConfig.fromJson(Map<String, dynamic> json) => CalendarConfig(
        apiKey: json['apiKey'] as String,
        calendarId: json['calendarId'] as String,
      );
}
