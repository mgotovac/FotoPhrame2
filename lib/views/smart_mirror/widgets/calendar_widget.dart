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
      crossAxisAlignment: CrossAxisAlignment.stretch,
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
            Container(width: 1, color: Colors.white.withValues(alpha: 0.08)),
        ],
      ],
    );
  }
}

class _DayColumn extends StatefulWidget {
  final DateTime date;
  final List<CalendarEvent> events;
  final bool isToday;

  const _DayColumn({
    required this.date,
    required this.events,
    required this.isToday,
  });

  @override
  State<_DayColumn> createState() => _DayColumnState();
}

class _DayColumnState extends State<_DayColumn> {
  final _scrollController = ScrollController();
  bool _canScrollDown = false;
  bool _canScrollUp = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _onScroll());
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    final down = pos.maxScrollExtent > 0 && pos.pixels < pos.maxScrollExtent;
    final up = pos.pixels > 0;
    if (down != _canScrollDown || up != _canScrollUp) {
      setState(() {
        _canScrollDown = down;
        _canScrollUp = up;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Day header (fixed height)
          Text(
            DateFormat('EEE').format(widget.date).toUpperCase(),
            style: TextStyle(
              color: widget.isToday ? Colors.blue : Colors.white54,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          Text(
            DateFormat('d').format(widget.date),
            style: TextStyle(
              color: widget.isToday ? Colors.white : Colors.white70,
              fontSize: 20,
              fontWeight: widget.isToday ? FontWeight.w700 : FontWeight.w400,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 6),
          Container(height: 1, color: Colors.white.withValues(alpha: 0.12)),
          const SizedBox(height: 6),
          // Events — scrollable, shows all events
          Expanded(
            child: Stack(
              children: [
                SingleChildScrollView(
                  controller: _scrollController,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.events.isEmpty)
                        Text(
                          '–',
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.2), fontSize: 12),
                        )
                      else
                        for (final event in widget.events)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: _EventChip(event: event, isToday: widget.isToday),
                          ),
                    ],
                  ),
                ),
                if (_canScrollUp)
                  const Positioned(
                    left: 0,
                    right: 0,
                    top: 0,
                    child: Icon(Icons.keyboard_arrow_up,
                        color: Colors.white38, size: 16),
                  ),
                if (_canScrollDown)
                  const Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Icon(Icons.keyboard_arrow_down,
                        color: Colors.white38, size: 16),
                  ),
              ],
            ),
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
