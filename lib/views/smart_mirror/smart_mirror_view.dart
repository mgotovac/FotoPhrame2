import 'package:flutter/material.dart';
import 'widgets/clock_widget.dart';
import 'widgets/weather_widget.dart';
import 'widgets/air_quality_widget.dart';
import 'widgets/water_quality_widget.dart';
import 'widgets/calendar_widget.dart';

class SmartMirrorView extends StatelessWidget {
  const SmartMirrorView({super.key});

  @override
  Widget build(BuildContext context) {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return Container(
      color: Colors.black,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: isLandscape ? _buildLandscape() : _buildPortrait(),
        ),
      ),
    );
  }

  Widget _buildLandscape() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left side: Clock + Weather
        Expanded(
          flex: 5,
          child: Column(
            children: [
              const ClockWidget(),
              const SizedBox(height: 24),
              const WeatherWidget(),
              const SizedBox(height: 16),
              const Expanded(child: CalendarWidget()),
            ],
          ),
        ),
        const SizedBox(width: 24),
        // Right side: Air Quality + Water Quality
        Expanded(
          flex: 4,
          child: Column(
            children: [
              const AirQualityWidget(),
              const SizedBox(height: 16),
              const WaterQualityWidget(),
              const Spacer(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPortrait() {
    return SingleChildScrollView(
      child: Column(
        children: [
          const ClockWidget(),
          const SizedBox(height: 24),
          const WeatherWidget(),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(child: AirQualityWidget()),
              const SizedBox(width: 16),
              const Expanded(child: WaterQualityWidget()),
            ],
          ),
          const SizedBox(height: 16),
          const CalendarWidget(),
        ],
      ),
    );
  }
}
