import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/app_settings.dart';
import '../models/calendar_event.dart';
import '../models/calendar_config.dart';
import '../services/calendar_service.dart';
import '../utils/constants.dart';

class CalendarProvider extends ChangeNotifier {
  final CalendarService _service;

  List<CalendarEvent> _events = [];
  bool _isLoading = false;
  String? _error;
  Timer? _refreshTimer;
  CalendarConfig? _config;

  CalendarProvider(this._service);

  List<CalendarEvent> get events => _events;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void onSettingsChanged(AppSettings settings) {
    final configChanged = _config?.apiKey != settings.calendarConfig?.apiKey ||
        _config?.calendarId != settings.calendarConfig?.calendarId;
    _config = settings.calendarConfig;

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
      _events = await _service.fetchEvents(_config!);
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  void _startPeriodicRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer =
        Timer.periodic(kCalendarRefreshInterval, (_) => fetch());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
}
