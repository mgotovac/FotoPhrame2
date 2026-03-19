import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../models/app_settings.dart';
import '../providers/settings_provider.dart';

/// Wraps [child] with a black overlay during configured night hours.
/// A touch wakes the screen; after 5 minutes of inactivity it dims again.
class NightDimmingOverlay extends StatefulWidget {
  final Widget child;

  const NightDimmingOverlay({super.key, required this.child});

  @override
  State<NightDimmingOverlay> createState() => _NightDimmingOverlayState();
}

class _NightDimmingOverlayState extends State<NightDimmingOverlay> {
  late final Timer _minuteTimer;
  Timer? _wakeTimer;
  bool _manuallyWoken = false;

  static const _wakeTimeout = Duration(minutes: 5);

  @override
  void initState() {
    super.initState();
    _minuteTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _minuteTimer.cancel();
    _wakeTimer?.cancel();
    super.dispose();
  }

  bool _isDimmingActive(AppSettings settings) {
    if (!settings.nightDimmingEnabled) return false;
    final hour = DateTime.now().hour;
    final start = settings.nightDimmingStartHour;
    final end = settings.nightDimmingEndHour;
    if (start == end) return false;
    return start > end
        ? hour >= start || hour < end
        : hour >= start && hour < end;
  }

  void _onUserInteraction() {
    _wakeTimer?.cancel();
    if (!_manuallyWoken) {
      WakelockPlus.enable();
      setState(() => _manuallyWoken = true);
    }
    _wakeTimer = Timer(_wakeTimeout, () {
      if (mounted) setState(() => _manuallyWoken = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settingsProvider, _) {
        final settings = settingsProvider.settings;
        final dimmingActive = _isDimmingActive(settings) && !_manuallyWoken;
        final screenOff = dimmingActive && settings.nightDimmingLevel == 0.0;

        if (screenOff) {
          WakelockPlus.disable();
        } else {
          WakelockPlus.enable();
        }

        return Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: (_) => _onUserInteraction(),
          child: Stack(
            children: [
              widget.child,
              if (dimmingActive && !screenOff)
                Container(
                  color: Colors.black.withValues(
                    alpha: 1.0 - settings.nightDimmingLevel,
                  ),
                ),
              if (screenOff) Container(color: Colors.black),
            ],
          ),
        );
      },
    );
  }
}
