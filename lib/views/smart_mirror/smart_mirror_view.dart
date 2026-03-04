import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/slideshow_provider.dart';
import '../../models/media_item.dart';
import 'widgets/clock_widget.dart';
import 'widgets/weather_widget.dart';
import 'widgets/air_quality_widget.dart';
import 'widgets/water_quality_widget.dart';
import 'widgets/calendar_widget.dart';
import '../photo_frame/widgets/dual_landscape_display.dart';
import '../photo_frame/widgets/photo_display.dart';

class SmartMirrorView extends StatelessWidget {
  const SmartMirrorView({super.key});

  @override
  Widget build(BuildContext context) {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    return Consumer<SettingsProvider>(
      builder: (context, settingsProvider, _) {
        final showWaterQuality = settingsProvider.settings.showWaterQuality;
        return Container(
          color: Colors.black,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: isLandscape
                  ? _buildLandscape(showWaterQuality)
                  : _buildPortrait(showWaterQuality),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLandscape(bool showWaterQuality) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Left side: Clock+AQ row + Weather + Calendar
        Expanded(
          flex: 5,
          child: Column(
            children: [
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: const [
                    Expanded(child: ClockWidget()),
                    SizedBox(width: 16),
                    SizedBox(
                      width: 160,
                      child: AirQualityWidget(compact: true),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const WeatherWidget(),
              const SizedBox(height: 16),
              const Expanded(child: CalendarWidget()),
            ],
          ),
        ),
        const SizedBox(width: 24),
        // Right side: photo preview
        Expanded(
          flex: 4,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: const _MirrorPhotoPreview(),
          ),
        ),
      ],
    );
  }

  Widget _buildPortrait(bool showWaterQuality) {
    return SingleChildScrollView(
      child: Column(
        children: [
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: const [
                Expanded(child: ClockWidget()),
                SizedBox(width: 16),
                SizedBox(
                  width: 160,
                  child: AirQualityWidget(compact: true),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const WeatherWidget(),
          if (showWaterQuality) ...[
            const SizedBox(height: 16),
            const WaterQualityWidget(),
          ],
          const SizedBox(height: 16),
          const CalendarWidget(),
        ],
      ),
    );
  }
}

class _MirrorPhotoPreview extends StatelessWidget {
  const _MirrorPhotoPreview();

  @override
  Widget build(BuildContext context) {
    return Consumer<SlideshowProvider>(
      builder: (context, slideshow, _) {
        final item = slideshow.currentItem;
        if (item == null || !item.isCached || item.type != MediaType.image) {
          return Container(
            color: Colors.white.withValues(alpha: 0.05),
            child: const Center(
              child: Icon(Icons.photo, color: Colors.white12, size: 48),
            ),
          );
        }

        final companion = slideshow.companionItem;
        final showDualLandscape = !item.isPortrait &&
            companion != null &&
            companion.isCached &&
            companion.type == MediaType.image;

        if (showDualLandscape) {
          return DualLandscapeDisplay(
            key: ValueKey('${item.remotePath}+${companion.remotePath}'),
            primary: item,
            companion: companion,
          );
        }

        return PhotoDisplay(
          key: ValueKey(item.remotePath),
          filePath: item.localCachePath!,
        );
      },
    );
  }
}
