class AirQualityData {
  final int aqiUs;
  final String mainPollutant;
  final double temperature;
  final int humidity;
  final DateTime fetchedAt;

  const AirQualityData({
    required this.aqiUs,
    required this.mainPollutant,
    required this.temperature,
    required this.humidity,
    required this.fetchedAt,
  });

  String get category {
    if (aqiUs <= 50) return 'Good';
    if (aqiUs <= 100) return 'Moderate';
    if (aqiUs <= 150) return 'Unhealthy for Sensitive';
    if (aqiUs <= 200) return 'Unhealthy';
    if (aqiUs <= 300) return 'Very Unhealthy';
    return 'Hazardous';
  }

  int get colorValue {
    if (aqiUs <= 50) return 0xFF4CAF50; // green
    if (aqiUs <= 100) return 0xFFFFEB3B; // yellow
    if (aqiUs <= 150) return 0xFFFF9800; // orange
    if (aqiUs <= 200) return 0xFFF44336; // red
    if (aqiUs <= 300) return 0xFF9C27B0; // purple
    return 0xFF880E4F; // maroon
  }

  factory AirQualityData.fromIqAirJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    final current = data['current'] as Map<String, dynamic>;
    final pollution = current['pollution'] as Map<String, dynamic>;
    final weather = current['weather'] as Map<String, dynamic>;
    return AirQualityData(
      aqiUs: pollution['aqius'] as int,
      mainPollutant: pollution['mainus'] as String,
      temperature: (weather['tp'] as num).toDouble(),
      humidity: weather['hu'] as int,
      fetchedAt: DateTime.now(),
    );
  }
}
