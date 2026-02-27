import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_settings.dart';

class SettingsService {
  static const _key = 'app_settings';
  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  AppSettings load() {
    final json = _prefs.getString(_key);
    if (json == null) return const AppSettings();
    return AppSettings.fromJson(
        jsonDecode(json) as Map<String, dynamic>);
  }

  Future<void> save(AppSettings settings) async {
    await _prefs.setString(_key, jsonEncode(settings.toJson()));
  }
}
