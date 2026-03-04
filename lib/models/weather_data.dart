class WeatherPeriod {
  final String label; // 'Night' | 'Morn.' | 'Aft.' | 'Eve.'
  final double low;
  final double high;
  final String iconCode;
  final double pop;        // max probability of precipitation across entries (0–1)
  final double precipMm;   // total rain+snow mm summed across entries
  final double windSpeed;  // average wind speed across entries (m/s)

  const WeatherPeriod({
    required this.label,
    required this.low,
    required this.high,
    required this.iconCode,
    required this.pop,
    required this.precipMm,
    required this.windSpeed,
  });
}

class WeatherData {
  final double temperature;
  final double feelsLike;
  final int humidity;
  final String description;
  final String iconCode;
  final double windSpeed;
  final double pop;       // probability of precipitation from first list entry (0–1)
  final double precipMm;  // rain+snow mm from first list entry (0 if absent)
  final String cityName;
  final DateTime fetchedAt;
  final List<WeatherPeriod> periods;

  const WeatherData({
    required this.temperature,
    required this.feelsLike,
    required this.humidity,
    required this.description,
    required this.iconCode,
    required this.windSpeed,
    required this.pop,
    required this.precipMm,
    required this.cityName,
    required this.fetchedAt,
    required this.periods,
  });

  String get iconUrl =>
      'https://openweathermap.org/img/wn/$iconCode@4x.png';

  factory WeatherData.fromForecastJson(Map<String, dynamic> json) {
    final current =
        (json['list'] as List).first as Map<String, dynamic>;
    final main = current['main'] as Map<String, dynamic>;
    final wind = current['wind'] as Map<String, dynamic>;
    final weather =
        (current['weather'] as List).first as Map<String, dynamic>;
    final city = json['city'] as Map<String, dynamic>;
    return WeatherData(
      temperature: (main['temp'] as num).toDouble(),
      feelsLike: (main['feels_like'] as num).toDouble(),
      humidity: main['humidity'] as int,
      description: weather['description'] as String,
      iconCode: weather['icon'] as String,
      windSpeed: (wind['speed'] as num).toDouble(),
      pop: (current['pop'] as num? ?? 0).toDouble(),
      precipMm: ((current['rain'] as Map?)?['3h'] as num? ?? 0).toDouble() +
                ((current['snow'] as Map?)?['3h'] as num? ?? 0).toDouble(),
      cityName: city['name'] as String,
      fetchedAt: DateTime.now(),
      periods: _parsePeriods(json['list'] as List),
    );
  }

  static List<WeatherPeriod> _parsePeriods(List<dynamic> list) {
    const partDefs = [
      ('Night', 0),
      ('Morn.', 1),
      ('Aft.', 2),
      ('Eve.', 3),
    ];

    final now = DateTime.now();
    final todayMidnight = DateTime(now.year, now.month, now.day);
    final currentPartIdx = now.hour ~/ 6;

    // bucket key: '$dayOffset-$partIdx'
    final Map<String, List<Map<String, dynamic>>> buckets = {};
    for (final raw in list) {
      final item = raw as Map<String, dynamic>;
      final dt =
          DateTime.fromMillisecondsSinceEpoch((item['dt'] as int) * 1000);
      final dayOffset = dt.difference(todayMidnight).inDays;
      if (dayOffset < 0 || dayOffset > 2) continue;
      final partIdx = dt.hour ~/ 6;
      buckets.putIfAbsent('$dayOffset-$partIdx', () => []).add(item);
    }

    final result = <WeatherPeriod>[];
    outer:
    for (var dayOffset = 0; dayOffset <= 2; dayOffset++) {
      final startPart = dayOffset == 0 ? currentPartIdx : 0;
      for (var p = startPart; p < 4; p++) {
        final entries = buckets['$dayOffset-$p'];
        if (entries == null || entries.isEmpty) continue;

        final temps = entries
            .map((e) => (e['main']['temp'] as num).toDouble())
            .toList();
        final low =
            temps.fold(double.infinity, (a, b) => a < b ? a : b);
        final high =
            temps.fold(double.negativeInfinity, (a, b) => a > b ? a : b);

        // icon from the warmest entry (most representative)
        final hottest = entries.reduce((a, b) =>
            (a['main']['temp'] as num) >= (b['main']['temp'] as num) ? a : b);
        final icon = ((hottest['weather'] as List).first
            as Map<String, dynamic>)['icon'] as String;

        final maxPop = entries
            .map((e) => (e['pop'] as num? ?? 0).toDouble())
            .fold(0.0, (a, b) => a > b ? a : b);

        final totalPrecipMm = entries.fold(0.0, (sum, e) =>
            sum +
            ((e['rain'] as Map?)?['3h'] as num? ?? 0).toDouble() +
            ((e['snow'] as Map?)?['3h'] as num? ?? 0).toDouble());

        final avgWindSpeed = entries
            .map((e) => ((e['wind'] as Map)['speed'] as num).toDouble())
            .fold(0.0, (a, b) => a + b) / entries.length;

        result.add(WeatherPeriod(
          label: partDefs[p].$1,
          low: low,
          high: high,
          iconCode: icon,
          pop: maxPop,
          precipMm: totalPrecipMm,
          windSpeed: avgWindSpeed,
        ));
        if (result.length == 4) break outer;
      }
    }

    return result;
  }
}
