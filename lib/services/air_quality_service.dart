import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/air_quality_data.dart';
import '../utils/constants.dart';

class AirQualityService {
  Future<AirQualityData> fetchAirQuality(
      String apiKey, String city, String state, String country) async {
    final uri = Uri.parse(
        '$kIqAirBaseUrl?city=$city&state=$state&country=$country&key=$apiKey');
    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception(
          'Air Quality API error: ${response.statusCode} ${response.body}');
    }

    return AirQualityData.fromIqAirJson(
        jsonDecode(response.body) as Map<String, dynamic>);
  }
}
