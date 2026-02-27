import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/water_quality_provider.dart';

class WaterQualityWidget extends StatelessWidget {
  const WaterQualityWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<WaterQualityProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.data == null) {
          return const _WqCard(
            child: Center(
              child: CircularProgressIndicator(color: Colors.white54),
            ),
          );
        }

        if (provider.error != null && provider.data == null) {
          return _WqCard(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.water, color: Colors.white38, size: 32),
                  const SizedBox(height: 8),
                  Text('Water quality unavailable',
                      style:
                          TextStyle(color: Colors.white.withValues(alpha: 0.4))),
                ],
              ),
            ),
          );
        }

        final data = provider.data;
        if (data == null) {
          return _WqCard(
            child: Center(
              child: Text(
                'Configure water quality\nendpoint in settings',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
              ),
            ),
          );
        }

        return _WqCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.water_drop, color: Colors.blue, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'Water Quality',
                    style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.w500),
                  ),
                  const Spacer(),
                  Text(
                    'Zagreb',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4), fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...data.fields.entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        entry.key,
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 14),
                      ),
                      Text(
                        '${entry.value ?? 'N/A'}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w300),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _WqCard extends StatelessWidget {
  final Widget child;
  const _WqCard({required this.child});

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
