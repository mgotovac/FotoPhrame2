import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/app_settings.dart';
import '../models/water_quality_data.dart';
import '../models/water_quality_config.dart';
import '../services/water_quality_service.dart';
import '../utils/constants.dart';

class WaterQualityProvider extends ChangeNotifier {
  final WaterQualityService _service;

  WaterQualityData? _data;
  bool _isLoading = false;
  String? _error;
  Timer? _refreshTimer;
  WaterQualityConfig? _config;

  WaterQualityProvider(this._service);

  WaterQualityData? get data => _data;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void onSettingsChanged(AppSettings settings) {
    final configChanged = _config?.url != settings.waterQualityConfig?.url ||
        _config?.selectedFields.length !=
            settings.waterQualityConfig?.selectedFields.length;
    _config = settings.waterQualityConfig;

    if (_config != null && configChanged) {
      fetch();
      _startPeriodicRefresh();
    }
  }

  Future<void> fetch() async {
    if (_config == null) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _data = await _service.fetchWaterQuality(_config!);
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  void _startPeriodicRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer =
        Timer.periodic(kWaterQualityRefreshInterval, (_) => fetch());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
}
