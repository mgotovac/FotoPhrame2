import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/weather_provider.dart';

class WeatherWidget extends StatelessWidget {
  const WeatherWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<WeatherProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.data == null) {
          return const _WeatherCard(
            child: Center(
              child: CircularProgressIndicator(color: Colors.white54),
            ),
          );
        }

        if (provider.error != null && provider.data == null) {
          return _WeatherCard(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.cloud_off, color: Colors.white38, size: 40),
                  const SizedBox(height: 8),
                  Text(
                    'Weather unavailable',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    provider.error!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.3),
                        fontSize: 10),
                  ),
                ],
              ),
            ),
          );
        }

        final data = provider.data;
        if (data == null) {
          return _WeatherCard(
            child: Center(
              child: Text(
                'Configure Weather API key\nin settings',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
              ),
            ),
          );
        }

        return _WeatherCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Weather icon
                  _buildWeatherIcon(data.iconCode),
                  const SizedBox(width: 12),
                  // Temperature
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${data.temperature.round()}°C',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 42,
                          fontWeight: FontWeight.w200,
                        ),
                      ),
                      Text(
                        data.description[0].toUpperCase() +
                            data.description.substring(1),
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 16),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildDetail(Icons.thermostat, 'Feels like',
                      '${data.feelsLike.round()}°C'),
                  const SizedBox(width: 24),
                  _buildDetail(
                      Icons.water_drop, 'Humidity', '${data.humidity}%'),
                  const SizedBox(width: 24),
                  _buildDetail(Icons.air, 'Wind',
                      '${data.windSpeed.toStringAsFixed(1)} m/s'),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWeatherIcon(String iconCode) {
    // Map OpenWeather icon codes to Material icons
    IconData icon;
    Color color;

    switch (iconCode.replaceAll('n', 'd')) {
      case '01d':
        icon = Icons.wb_sunny;
        color = Colors.amber;
        break;
      case '02d':
        icon = Icons.cloud;
        color = Colors.amber.shade200;
        break;
      case '03d':
        icon = Icons.cloud;
        color = Colors.white70;
        break;
      case '04d':
        icon = Icons.cloud_queue;
        color = Colors.white54;
        break;
      case '09d':
        icon = Icons.grain;
        color = Colors.lightBlue.shade200;
        break;
      case '10d':
        icon = Icons.beach_access;
        color = Colors.lightBlue;
        break;
      case '11d':
        icon = Icons.flash_on;
        color = Colors.yellow;
        break;
      case '13d':
        icon = Icons.ac_unit;
        color = Colors.white;
        break;
      case '50d':
        icon = Icons.blur_on;
        color = Colors.white54;
        break;
      default:
        icon = Icons.cloud;
        color = Colors.white70;
    }

    // Use night variant color
    if (iconCode.endsWith('n')) {
      color = color.withValues(alpha: 0.7);
    }

    return Icon(icon, size: 56, color: color);
  }

  Widget _buildDetail(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.white38, size: 16),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(color: Colors.white38, fontSize: 10)),
            Text(value,
                style: const TextStyle(color: Colors.white70, fontSize: 14)),
          ],
        ),
      ],
    );
  }
}

class _WeatherCard extends StatelessWidget {
  final Widget child;
  const _WeatherCard({required this.child});

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
