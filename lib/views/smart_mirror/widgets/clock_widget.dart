import 'dart:async';
import 'package:flutter/material.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:intl/intl.dart';
import '../../../utils/constants.dart';

class ClockWidget extends StatefulWidget {
  const ClockWidget({super.key});

  @override
  State<ClockWidget> createState() => _ClockWidgetState();
}

class _ClockWidgetState extends State<ClockWidget> {
  late Timer _timer;
  late tz.TZDateTime _now;

  @override
  void initState() {
    super.initState();
    _now = tz.TZDateTime.now(tz.getLocation(kDefaultTimezone));
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _now = tz.TZDateTime.now(tz.getLocation(kDefaultTimezone));
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('HH:mm:ss');
    final dateFormat = DateFormat('EEEE, d MMMM yyyy');

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          timeFormat.format(_now),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 72,
            fontWeight: FontWeight.w200,
            letterSpacing: 4,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          dateFormat.format(_now),
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 20,
            fontWeight: FontWeight.w300,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'Zagreb, Croatia',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.4),
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}
