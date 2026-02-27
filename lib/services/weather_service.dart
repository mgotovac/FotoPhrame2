import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/weather_data.dart';
import '../utils/constants.dart';

class WeatherService {
  String? _cachedCity;
  double? _cachedLat;
  double? _cachedLon;

  Future<({double lat, double lon})> _fetchCoordinates(
      String city, String apiKey) async {
    if (_cachedCity == city && _cachedLat != null && _cachedLon != null) {
      return (lat: _cachedLat!, lon: _cachedLon!);
    }

    final uri = Uri.parse(
        '$kOpenWeatherGeocodingUrl?q=${Uri.encodeComponent(city)}&limit=1&appid=$apiKey');
    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception(
          'Geocoding API error: ${response.statusCode} ${response.body}');
    }

    final list = jsonDecode(response.body) as List;
    if (list.isEmpty) {
      throw Exception('City not found: $city');
    }

    final place = list.first as Map<String, dynamic>;
    _cachedLat = (place['lat'] as num).toDouble();
    _cachedLon = (place['lon'] as num).toDouble();
    _cachedCity = city;

    return (lat: _cachedLat!, lon: _cachedLon!);
  }

  Future<WeatherData> fetchWeather(String apiKey, String city) async {
    final (:lat, :lon) = await _fetchCoordinates(city, apiKey);

    final uri = Uri.parse(
        '$kOpenWeatherOneCallUrl?lat=$lat&lon=$lon&appid=$apiKey&units=metric');
    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception(
          'Weather API error: ${response.statusCode} ${response.body}');
    }

    return WeatherData.fromForecastJson(
        jsonDecode(response.body) as Map<String, dynamic>);
  }
}
