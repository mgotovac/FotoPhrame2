class CalendarConfig {
  final String id;
  final String name;
  final String icsUrl;

  const CalendarConfig({
    required this.id,
    required this.name,
    required this.icsUrl,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'icsUrl': icsUrl,
      };

  factory CalendarConfig.fromJson(Map<String, dynamic> json) => CalendarConfig(
        id: json['id'] as String,
        name: json['name'] as String,
        icsUrl: json['icsUrl'] as String,
      );
}
