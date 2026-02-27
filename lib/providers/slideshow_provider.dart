import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/app_settings.dart';
import '../models/media_item.dart';
import '../models/nas_source.dart';
import '../services/media_cache_service.dart';
import '../services/nas/nas_service.dart';
import '../services/nas/nas_service_factory.dart';
import '../utils/constants.dart';

class SlideshowProvider extends ChangeNotifier {
  final MediaCacheService _cacheService;
  final NasServiceFactory _nasFactory;

  List<MediaItem> _queue = [];
  int _currentIndex = -1;
  List<NasSource> _sources = [];
  Timer? _autoAdvanceTimer;
  Timer? _rescanTimer;
  bool _isPaused = false;
  bool _isScanning = false;
  String? _error;
  Duration _interval = kDefaultSlideshowInterval;
  bool _isVideoPlaying = false;

  SlideshowProvider(this._cacheService, this._nasFactory);

  MediaItem? get currentItem =>
      _currentIndex >= 0 && _currentIndex < _queue.length
          ? _queue[_currentIndex]
          : null;

  int get currentIndex => _currentIndex;
  int get totalItems => _queue.length;
  bool get isPaused => _isPaused;
  bool get isScanning => _isScanning;
  String? get error => _error;
  bool get hasMedia => _queue.isNotEmpty;
  bool get isVideoPlaying => _isVideoPlaying;

  void onSettingsChanged(AppSettings settings) {
    _interval = settings.slideshowInterval;
    if (_autoAdvanceTimer != null) {
      _startAutoAdvance();
    }
    if (settings.nasSources.isNotEmpty && _queue.isEmpty && !_isScanning) {
      scanSources(settings.nasSources);
    }
  }

  Future<void> scanSources(List<NasSource> sources) async {
    if (_isScanning) return;
    _sources = sources;
    _isScanning = true;
    _error = null;
    notifyListeners();

    final newQueue = <MediaItem>[];
    final diagLines = <String>[];

    for (final source in sources) {
      NasService? service;
      try {
        service = _nasFactory.create(source);
        await service.connect();

        if (source.folders.isEmpty) {
          diagLines.add('[${source.name}] no folders configured');
        }

        for (final folder in source.folders) {
          try {
            final items = await service.listMediaFiles(
              folder.path,
              recursive: folder.recursive,
            );
            diagLines.add('[${source.name}] ${folder.path} → ${items.length} file(s)');
            newQueue.addAll(items);
          } catch (e) {
            diagLines.add('[${source.name}] ${folder.path} → ERROR: $e');
          }
        }
      } catch (e) {
        diagLines.add('[${source.name}] connect failed: $e');
      } finally {
        await service?.disconnect();
      }
    }

    // Shuffle the queue for variety
    newQueue.shuffle();

    _queue = newQueue;
    if (_queue.isNotEmpty && _currentIndex < 0) {
      _currentIndex = 0;
      _prefetchCurrent();
    }
    _isScanning = false;

    if (_queue.isEmpty) {
      _error = 'No media files found\n${diagLines.join('\n')}';
    }

    notifyListeners();
    _startAutoAdvance();
    _startPeriodicRescan();
  }

  void _startPeriodicRescan() {
    _rescanTimer?.cancel();
    _rescanTimer = Timer.periodic(kSlideshowRescanInterval, (_) => _incrementalRescan());
  }

  Future<void> _incrementalRescan() async {
    if (_isScanning || _sources.isEmpty) return;

    final existingPaths = _queue.map((e) => e.remotePath).toSet();
    final newItems = <MediaItem>[];

    for (final source in _sources) {
      NasService? service;
      try {
        service = _nasFactory.create(source);
        await service.connect();
        for (final folder in source.folders) {
          try {
            final items = await service.listMediaFiles(
              folder.path,
              recursive: folder.recursive,
            );
            for (final item in items) {
              if (!existingPaths.contains(item.remotePath)) {
                newItems.add(item);
              }
            }
          } catch (_) {}
        }
      } catch (_) {
      } finally {
        await service?.disconnect();
      }
    }

    if (newItems.isNotEmpty) {
      newItems.shuffle();
      _queue.addAll(newItems);
      notifyListeners();
    }
  }

  void next() {
    if (_queue.isEmpty) return;
    _currentIndex = (_currentIndex + 1) % _queue.length;
    _isVideoPlaying = false;
    notifyListeners();
    _prefetchCurrent();
    _resetAutoAdvance();
  }

  void previous() {
    if (_queue.isEmpty) return;
    _currentIndex = (_currentIndex - 1 + _queue.length) % _queue.length;
    _isVideoPlaying = false;
    notifyListeners();
    _prefetchCurrent();
    _resetAutoAdvance();
  }

  void pause() {
    _isPaused = true;
    _autoAdvanceTimer?.cancel();
    _autoAdvanceTimer = null;
    notifyListeners();
  }

  void resume() {
    _isPaused = false;
    _startAutoAdvance();
    notifyListeners();
  }

  void setVideoPlaying(bool playing) {
    _isVideoPlaying = playing;
  }

  void onVideoCompleted() {
    _isVideoPlaying = false;
    next();
  }

  void _startAutoAdvance() {
    _autoAdvanceTimer?.cancel();
    if (_isPaused) return;
    _autoAdvanceTimer = Timer.periodic(_interval, (_) {
      if (!_isPaused && !_isVideoPlaying) {
        next();
      }
    });
  }

  void _resetAutoAdvance() {
    if (!_isPaused) {
      _startAutoAdvance();
    }
  }

  Future<void> _prefetchCurrent() async {
    if (_queue.isEmpty) return;

    // Prefetch current + next few items
    for (var i = 0; i < kPrefetchCount && i < _queue.length; i++) {
      final idx = (_currentIndex + i) % _queue.length;
      final item = _queue[idx];
      if (!item.isCached) {
        _downloadItem(item);
      }
    }
  }

  Future<void> _downloadItem(MediaItem item) async {
    final source = item.sourceId;
    final cachePath = _cacheService.getCachePath(source, item.remotePath);

    if (_cacheService.isCached(source, item.remotePath)) {
      item.localCachePath = cachePath;
    }
  }

  /// Download a specific item from NAS to cache
  Future<bool> ensureCached(MediaItem item, NasSource source) async {
    final cachePath =
        _cacheService.getCachePath(item.sourceId, item.remotePath);

    if (_cacheService.isCached(item.sourceId, item.remotePath)) {
      item.localCachePath = cachePath;
      return true;
    }

    NasService? service;
    try {
      await _cacheService.evictIfNeeded();
      service = _nasFactory.create(source);
      await service.connect();
      await service.downloadFile(item.remotePath, cachePath);
      item.localCachePath = cachePath;
      notifyListeners();
      return true;
    } catch (e) {
      print('Error downloading ${item.remotePath}: $e');
      return false;
    } finally {
      await service?.disconnect();
    }
  }

  @override
  void dispose() {
    _autoAdvanceTimer?.cancel();
    _rescanTimer?.cancel();
    super.dispose();
  }
}
