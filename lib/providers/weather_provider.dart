import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/app_settings.dart';
import '../models/weather_data.dart';
import '../services/weather_service.dart';
import '../utils/constants.dart';

class WeatherProvider extends ChangeNotifier {
  final WeatherService _service;

  WeatherData? _data;
  bool _isLoading = false;
  String? _error;
  Timer? _refreshTimer;
  String? _apiKey;
  String _city = kDefaultCity;
  int _refreshIntervalMinutes = kDefaultWeatherRefreshIntervalMinutes;

  WeatherProvider(this._service);

  WeatherData? get data => _data;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void onSettingsChanged(AppSettings settings) {
    final keyChanged = _apiKey != settings.openWeatherApiKey;
    final cityChanged = _city != settings.weatherCity;
    final intervalChanged =
        _refreshIntervalMinutes != settings.weatherRefreshIntervalMinutes;
    _apiKey = settings.openWeatherApiKey;
    _city = settings.weatherCity;
    _refreshIntervalMinutes = settings.weatherRefreshIntervalMinutes;

    if (_apiKey != null && _apiKey!.isNotEmpty) {
      if (keyChanged || cityChanged) fetch();
      if (keyChanged || cityChanged || intervalChanged) _startPeriodicRefresh();
    }
  }

  Future<void> fetch() async {
    if (_apiKey == null || _apiKey!.isEmpty) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _data = await _service.fetchWeather(_apiKey!, _city);
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  void _startPeriodicRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(
        Duration(minutes: _refreshIntervalMinutes), (_) => fetch());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
}
