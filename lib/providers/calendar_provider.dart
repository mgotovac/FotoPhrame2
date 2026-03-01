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
  List<CalendarConfig> _configs = [];

  CalendarProvider(this._service);

  List<CalendarEvent> get events => _events;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasConfig => _configs.isNotEmpty;

  void onSettingsChanged(AppSettings settings) {
    final oldSet = _configs.map((c) => '${c.id}:${c.icsUrl}').toSet();
    final newSet =
        settings.calendarConfigs.map((c) => '${c.id}:${c.icsUrl}').toSet();
    _configs = settings.calendarConfigs;

    if (oldSet != newSet) {
      if (_configs.isNotEmpty) {
        fetch();
        _startPeriodicRefresh();
      } else {
        _events = [];
        _refreshTimer?.cancel();
        notifyListeners();
      }
    }
  }

  Future<void> fetch() async {
    if (_configs.isEmpty) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _events = await _service.fetchEvents(_configs);
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
