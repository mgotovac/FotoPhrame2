import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/slideshow_provider.dart';
import '../providers/weather_provider.dart';
import '../providers/air_quality_provider.dart';
import '../providers/water_quality_provider.dart';
import '../providers/calendar_provider.dart';
import 'photo_frame/photo_frame_view.dart';
import 'smart_mirror/smart_mirror_view.dart';
import 'settings/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _showSettingsIcon = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() => _currentPage = page);
    if (page == 0) {
      context.read<SlideshowProvider>().next();
    } else if (page == 1) {
      context.read<WeatherProvider>().fetch();
      context.read<AirQualityProvider>().fetch();
      context.read<WaterQualityProvider>().fetch();
      context.read<CalendarProvider>().fetch();
    }
  }

  void _openSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );
  }

  void _showSettingsIconBriefly() {
    setState(() => _showSettingsIcon = true);
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _showSettingsIcon = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onLongPress: _openSettings,
        onDoubleTap: _showSettingsIconBriefly,
        child: Stack(
          children: [
            PageView(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              children: const [
                PhotoFrameView(),
                SmartMirrorView(),
              ],
            ),
            // Page indicator
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _PageDot(active: _currentPage == 0),
                  const SizedBox(width: 8),
                  _PageDot(active: _currentPage == 1),
                ],
              ),
            ),
            // Settings gear icon (shown on double tap)
            if (_showSettingsIcon)
              Positioned(
                top: 40,
                right: 16,
                child: IconButton(
                  icon: const Icon(Icons.settings, color: Colors.white54),
                  iconSize: 32,
                  onPressed: _openSettings,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PageDot extends StatelessWidget {
  final bool active;
  const _PageDot({required this.active});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: active ? 12 : 8,
      height: active ? 12 : 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active ? Colors.white54 : Colors.white24,
      ),
    );
  }
}
