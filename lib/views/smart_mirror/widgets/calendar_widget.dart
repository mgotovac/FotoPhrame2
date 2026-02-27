import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../providers/calendar_provider.dart';
import '../../../models/calendar_event.dart';

class CalendarWidget extends StatelessWidget {
  const CalendarWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<CalendarProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.events.isEmpty) {
          return const _CalCard(
            child: Center(
              child: CircularProgressIndicator(color: Colors.white54),
            ),
          );
        }

        if (provider.error != null && provider.events.isEmpty) {
          return _CalCard(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.calendar_today,
                      color: Colors.white38, size: 32),
                  const SizedBox(height: 8),
                  Text('Calendar unavailable',
                      style:
                          TextStyle(color: Colors.white.withValues(alpha: 0.4))),
                ],
              ),
            ),
          );
        }

        if (provider.events.isEmpty) {
          return _CalCard(
            child: Center(
              child: Text(
                'Configure Google Calendar\nin settings',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
              ),
            ),
          );
        }

        return _CalCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.calendar_today,
                      color: Colors.white54, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'Upcoming Events',
                    style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...provider.events.take(8).map(
                    (event) => _buildEventItem(event),
                  ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEventItem(CalendarEvent event) {
    final now = DateTime.now();
    final isToday = event.start.year == now.year &&
        event.start.month == now.month &&
        event.start.day == now.day;

    final timeStr = event.isAllDay
        ? 'All day'
        : DateFormat('HH:mm').format(event.start);

    final dateStr = isToday
        ? 'Today'
        : DateFormat('E, d MMM').format(event.start);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 3,
            height: 36,
            decoration: BoxDecoration(
              color: isToday ? Colors.blue : Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '$dateStr  $timeStr',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.4), fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CalCard extends StatelessWidget {
  final Widget child;
  const _CalCard({required this.child});

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
