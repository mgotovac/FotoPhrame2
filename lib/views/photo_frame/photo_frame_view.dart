import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/media_item.dart';
import '../../providers/slideshow_provider.dart';
import '../../providers/settings_provider.dart';
import 'widgets/photo_display.dart';
import 'widgets/video_display.dart';
import 'widgets/media_controls_overlay.dart';

class PhotoFrameView extends StatefulWidget {
  const PhotoFrameView({super.key});

  @override
  State<PhotoFrameView> createState() => _PhotoFrameViewState();
}

class _PhotoFrameViewState extends State<PhotoFrameView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initSources();
    });
  }

  void _initSources() {
    final settings = context.read<SettingsProvider>().settings;
    final slideshow = context.read<SlideshowProvider>();
    if (settings.nasSources.isNotEmpty && !slideshow.hasMedia) {
      slideshow.scanSources(settings.nasSources);
    }
  }

  NasSourceForItem? _findSource(MediaItem item) {
    final settings = context.read<SettingsProvider>().settings;
    try {
      final source =
          settings.nasSources.firstWhere((s) => s.id == item.sourceId);
      return NasSourceForItem(source);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SlideshowProvider>(
      builder: (context, slideshow, _) {
        if (slideshow.isScanning) {
          return Container(
            color: Colors.black,
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.white54),
                  SizedBox(height: 16),
                  Text('Scanning NAS sources...',
                      style: TextStyle(color: Colors.white54)),
                ],
              ),
            ),
          );
        }

        if (!slideshow.hasMedia) {
          return Container(
            color: Colors.black,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.photo_library_outlined,
                      color: Colors.white24, size: 80),
                  const SizedBox(height: 16),
                  Text(
                    slideshow.error ?? 'No media configured',
                    style: const TextStyle(color: Colors.white54, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Long press to open settings',
                    style: TextStyle(color: Colors.white38, fontSize: 14),
                  ),
                ],
              ),
            ),
          );
        }

        final item = slideshow.currentItem;
        if (item == null) {
          return Container(color: Colors.black);
        }

        // If item isn't cached yet, trigger download
        if (!item.isCached) {
          final sourceInfo = _findSource(item);
          if (sourceInfo != null) {
            slideshow.ensureCached(item, sourceInfo.source);
          }
          return Container(
            color: Colors.black,
            child: const Center(
              child: CircularProgressIndicator(color: Colors.white54),
            ),
          );
        }

        return MediaControlsOverlay(
          onNext: slideshow.next,
          onPrevious: slideshow.previous,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 800),
            child: _buildMediaDisplay(item),
          ),
        );
      },
    );
  }

  Widget _buildMediaDisplay(MediaItem item) {
    switch (item.type) {
      case MediaType.image:
        return PhotoDisplay(
          key: ValueKey(item.remotePath),
          filePath: item.localCachePath!,
        );
      case MediaType.video:
        return VideoDisplay(
          key: ValueKey(item.remotePath),
          filePath: item.localCachePath!,
        );
    }
  }
}

class NasSourceForItem {
  final dynamic source;
  NasSourceForItem(this.source);
}
