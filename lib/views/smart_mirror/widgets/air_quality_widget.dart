import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/air_quality_provider.dart';

class AirQualityWidget extends StatelessWidget {
  const AirQualityWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AirQualityProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.data == null) {
          return const _AqCard(
            child: Center(
              child: CircularProgressIndicator(color: Colors.white54),
            ),
          );
        }

        if (provider.error != null && provider.data == null) {
          return _AqCard(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.warning_amber,
                      color: Colors.white38, size: 32),
                  const SizedBox(height: 8),
                  Text('Air quality unavailable',
                      style:
                          TextStyle(color: Colors.white.withValues(alpha: 0.4))),
                ],
              ),
            ),
          );
        }

        final data = provider.data;
        if (data == null) {
          return _AqCard(
            child: Center(
              child: Text(
                'Configure IQAir API key\nin settings',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
              ),
            ),
          );
        }

        final aqiColor = Color(data.colorValue);

        return _AqCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.air, color: Colors.white54, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'Air Quality',
                    style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // AQI number with color
                  Text(
                    '${data.aqiUs}',
                    style: TextStyle(
                      color: aqiColor,
                      fontSize: 48,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      'AQI',
                      style: TextStyle(color: aqiColor, fontSize: 16),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              // Category badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: aqiColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  data.category,
                  style: TextStyle(color: aqiColor, fontSize: 14),
                ),
              ),
              const SizedBox(height: 12),
              // AQI gauge bar
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (data.aqiUs / 500).clamp(0.0, 1.0),
                  backgroundColor: Colors.white12,
                  valueColor: AlwaysStoppedAnimation<Color>(aqiColor),
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Main pollutant: ${_pollutantName(data.mainPollutant)}',
                style:
                    TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 12),
              ),
            ],
          ),
        );
      },
    );
  }

  String _pollutantName(String code) {
    switch (code) {
      case 'p2':
        return 'PM2.5';
      case 'p1':
        return 'PM10';
      case 'o3':
        return 'Ozone';
      case 'n2':
        return 'NO2';
      case 's2':
        return 'SO2';
      case 'co':
        return 'CO';
      default:
        return code.toUpperCase();
    }
  }
}

class _AqCard extends StatelessWidget {
  final Widget child;
  const _AqCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }
}
