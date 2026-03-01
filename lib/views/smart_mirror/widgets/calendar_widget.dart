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
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.4))),
                ],
              ),
            ),
          );
        }

        if (!provider.isLoading && provider.events.isEmpty && provider.error == null) {
          return _CalCard(
            child: Center(
              child: Text(
                provider.hasConfig
                    ? 'No events in the next 5 days'
                    : 'Configure Google Calendar\nin settings',
                textAlign: TextAlign.center,
                style:
                    TextStyle(color: Colors.white.withValues(alpha: 0.4)),
              ),
            ),
          );
        }

        return _CalCard(child: _DayTable(events: provider.events));
      },
    );
  }
}

class _DayTable extends StatelessWidget {
  final List<CalendarEvent> events;
  const _DayTable({required this.events});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Group events into 5 day buckets (today … today+4)
    final byDay = List.generate(5, (_) => <CalendarEvent>[]);
    for (final event in events) {
      final idx = event.start.difference(today).inDays;
      if (idx >= 0 && idx < 5) byDay[idx].add(event);
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < 5; i++) ...[
          Expanded(
            child: _DayColumn(
              date: today.add(Duration(days: i)),
              events: byDay[i],
              isToday: i == 0,
            ),
          ),
          if (i < 4)
            Container(
              width: 1,
              height: double.infinity,
              color: Colors.white.withValues(alpha: 0.08),
            ),
        ],
      ],
    );
  }
}

class _DayColumn extends StatelessWidget {
  final DateTime date;
  final List<CalendarEvent> events;
  final bool isToday;

  const _DayColumn({
    required this.date,
    required this.events,
    required this.isToday,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Day header
          Text(
            DateFormat('EEE').format(date).toUpperCase(),
            style: TextStyle(
              color: isToday ? Colors.blue : Colors.white54,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          Text(
            DateFormat('d').format(date),
            style: TextStyle(
              color: isToday ? Colors.white : Colors.white70,
              fontSize: 20,
              fontWeight: isToday ? FontWeight.w700 : FontWeight.w400,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 6),
          Container(height: 1, color: Colors.white.withValues(alpha: 0.12)),
          const SizedBox(height: 6),
          // Events
          if (events.isEmpty)
            Text(
              '–',
              style:
                  TextStyle(color: Colors.white.withValues(alpha: 0.2), fontSize: 12),
            )
          else
            for (final event in events)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: _EventChip(event: event, isToday: isToday),
              ),
        ],
      ),
    );
  }
}

class _EventChip extends StatelessWidget {
  final CalendarEvent event;
  final bool isToday;
  const _EventChip({required this.event, required this.isToday});

  @override
  Widget build(BuildContext context) {
    final timeStr =
        event.isAllDay ? 'All day' : DateFormat('HH:mm').format(event.start);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          event.title,
          style: TextStyle(
            color: isToday ? Colors.white : Colors.white.withValues(alpha: 0.8),
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          timeStr,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.4),
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}

class _CalCard extends StatelessWidget {
  final Widget child;
  const _CalCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }
}
