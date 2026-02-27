import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/water_quality_data.dart';
import '../models/water_quality_config.dart';

class WaterQualityService {
  Future<WaterQualityData> fetchWaterQuality(
      WaterQualityConfig config) async {
    final uri = Uri.parse(config.url);
    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception(
          'Water Quality API error: ${response.statusCode} ${response.body}');
    }

    final json = jsonDecode(response.body);
    final fields = <String, dynamic>{};

    for (final field in config.selectedFields) {
      fields[field.label] = _extractField(json, field.jsonPath);
    }

    return WaterQualityData(fields: fields, fetchedAt: DateTime.now());
  }

  /// Fetch raw JSON from URL for field discovery in settings
  Future<Map<String, dynamic>> fetchRawJson(String url) async {
    final uri = Uri.parse(url);
    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception('HTTP error: ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic>) return decoded;
    return {'data': decoded};
  }

  /// Extract a value from nested JSON using dot-notation path
  dynamic _extractField(dynamic json, String path) {
    final parts = path.split('.');
    dynamic current = json;
    for (final part in parts) {
      if (current is Map<String, dynamic>) {
        current = current[part];
      } else if (current is List && int.tryParse(part) != null) {
        final index = int.parse(part);
        if (index < current.length) {
          current = current[index];
        } else {
          return null;
        }
      } else {
        return null;
      }
    }
    return current;
  }

  /// Flatten a JSON structure into dot-notation paths for field discovery
  static List<String> flattenJsonPaths(Map<String, dynamic> json,
      {String prefix = ''}) {
    final paths = <String>[];
    for (final entry in json.entries) {
      final path = prefix.isEmpty ? entry.key : '$prefix.${entry.key}';
      if (entry.value is Map<String, dynamic>) {
        paths.addAll(
            flattenJsonPaths(entry.value as Map<String, dynamic>, prefix: path));
      } else if (entry.value is List) {
        // Just record the list path, not individual indices
        paths.add(path);
      } else {
        paths.add(path);
      }
    }
    return paths;
  }
}
