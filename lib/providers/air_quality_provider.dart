import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/app_settings.dart';
import '../models/air_quality_data.dart';
import '../services/air_quality_service.dart';
import '../utils/constants.dart';

class AirQualityProvider extends ChangeNotifier {
  final AirQualityService _service;

  AirQualityData? _data;
  bool _isLoading = false;
  String? _error;
  Timer? _refreshTimer;
  String? _apiKey;
  String _city = kDefaultCity;
  String _state = kDefaultState;
  String _country = kDefaultCountry;
  int _refreshIntervalMinutes = kDefaultAirQualityRefreshIntervalMinutes;

  AirQualityProvider(this._service);

  AirQualityData? get data => _data;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void onSettingsChanged(AppSettings settings) {
    final changed = _apiKey != settings.iqAirApiKey ||
        _city != settings.iqAirCity ||
        _state != settings.iqAirState ||
        _country != settings.iqAirCountry;
    final intervalChanged = _refreshIntervalMinutes != settings.airQualityRefreshIntervalMinutes;
    _apiKey = settings.iqAirApiKey;
    _city = settings.iqAirCity;
    _state = settings.iqAirState;
    _country = settings.iqAirCountry;
    _refreshIntervalMinutes = settings.airQualityRefreshIntervalMinutes;

    if (_apiKey != null && _apiKey!.isNotEmpty) {
      if (changed) fetch();
      if (changed || intervalChanged) _startPeriodicRefresh();
    }
  }

  Future<void> fetch() async {
    if (_apiKey == null || _apiKey!.isEmpty) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _data = await _service.fetchAirQuality(_apiKey!, _city, _state, _country);
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  void _startPeriodicRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer =
        Timer.periodic(Duration(minutes: _refreshIntervalMinutes), (_) => fetch());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
}
