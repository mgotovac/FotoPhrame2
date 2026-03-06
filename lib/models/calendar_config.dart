// Predefined palette — vibrant/light colours visible on a black background.
const kCalendarColorPalette = <int>[
  0xFF4FC3F7, // Sky blue
  0xFF81C784, // Green
  0xFFFFB74D, // Amber
  0xFFCE93D8, // Purple
  0xFFF48FB1, // Pink
  0xFFFFF176, // Yellow
  0xFFEF9A9A, // Rose
  0xFF80DEEA, // Cyan
];

class CalendarConfig {
  final String id;
  final String name;
  final String icsUrl;
  final int color;

  const CalendarConfig({
    required this.id,
    required this.name,
    required this.icsUrl,
    this.color = 0xFF4FC3F7, // Sky blue — first palette entry
  });

  CalendarConfig copyWith({String? name, String? icsUrl, int? color}) =>
      CalendarConfig(
        id: id,
        name: name ?? this.name,
        icsUrl: icsUrl ?? this.icsUrl,
        color: color ?? this.color,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'icsUrl': icsUrl,
        'color': color,
      };

  factory CalendarConfig.fromJson(Map<String, dynamic> json) => CalendarConfig(
        id: json['id'] as String,
        name: json['name'] as String,
        icsUrl: json['icsUrl'] as String,
        color: (json['color'] as int?) ?? 0xFF4FC3F7,
      );
}
