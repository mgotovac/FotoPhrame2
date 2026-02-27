class WeatherData {
  final double temperature;
  final double feelsLike;
  final int humidity;
  final String description;
  final String iconCode;
  final double windSpeed;
  final String cityName;
  final DateTime fetchedAt;

  const WeatherData({
    required this.temperature,
    required this.feelsLike,
    required this.humidity,
    required this.description,
    required this.iconCode,
    required this.windSpeed,
    required this.cityName,
    required this.fetchedAt,
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
      cityName: city['name'] as String,
      fetchedAt: DateTime.now(),
    );
  }
}
