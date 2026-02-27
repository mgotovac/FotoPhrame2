import 'package:flutter/foundation.dart';
import '../models/app_settings.dart';
import '../models/nas_source.dart';
import '../models/water_quality_config.dart';
import '../models/calendar_config.dart';
import '../services/settings_service.dart';

class SettingsProvider extends ChangeNotifier {
  final SettingsService _service;
  AppSettings _settings = const AppSettings();

  SettingsProvider(this._service);

  AppSettings get settings => _settings;

  void loadSettings() {
    _settings = _service.load();
    notifyListeners();
  }

  Future<void> _save() async {
    await _service.save(_settings);
    notifyListeners();
  }

  Future<void> updateNasSources(List<NasSource> sources) async {
    _settings = _settings.copyWith(nasSources: sources);
    await _save();
  }

  Future<void> addNasSource(NasSource source) async {
    final sources = List<NasSource>.from(_settings.nasSources)..add(source);
    await updateNasSources(sources);
  }

  Future<void> removeNasSource(String sourceId) async {
    final sources =
        _settings.nasSources.where((s) => s.id != sourceId).toList();
    await updateNasSources(sources);
  }

  Future<void> updateNasSource(NasSource source) async {
    final sources = _settings.nasSources
        .map((s) => s.id == source.id ? source : s)
        .toList();
    await updateNasSources(sources);
  }

  Future<void> updateSlideshowInterval(Duration interval) async {
    _settings = _settings.copyWith(slideshowInterval: interval);
    await _save();
  }

  Future<void> updateWeatherConfig(String apiKey, String city) async {
    _settings = _settings.copyWith(
      openWeatherApiKey: apiKey,
      weatherCity: city,
    );
    await _save();
  }

  Future<void> updateAirQualityConfig(
      String apiKey, String city, String state, String country) async {
    _settings = _settings.copyWith(
      iqAirApiKey: apiKey,
      iqAirCity: city,
      iqAirState: state,
      iqAirCountry: country,
    );
    await _save();
  }

  Future<void> updateWaterQualityConfig(WaterQualityConfig? config) async {
    if (config == null) {
      _settings = _settings.copyWith(clearWaterQualityConfig: true);
    } else {
      _settings = _settings.copyWith(waterQualityConfig: config);
    }
    await _save();
  }

  Future<void> updateCalendarConfig(CalendarConfig? config) async {
    if (config == null) {
      _settings = _settings.copyWith(clearCalendarConfig: true);
    } else {
      _settings = _settings.copyWith(calendarConfig: config);
    }
    await _save();
  }
}
