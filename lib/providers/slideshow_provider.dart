import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:video_player/video_player.dart';
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
  int? _companionIndex;
  List<NasSource> _sources = [];
  Timer? _autoAdvanceTimer;
  Timer? _rescanTimer;
  bool _isPaused = false;
  bool _isScanning = false;
  bool _isBackgroundIndexing = false;
  String? _error;
  Duration _interval = kDefaultSlideshowInterval;
  bool _isVideoPlaying = false;

  SlideshowProvider(this._cacheService, this._nasFactory);

  MediaItem? get currentItem =>
      _currentIndex >= 0 && _currentIndex < _queue.length
          ? _queue[_currentIndex]
          : null;

  MediaItem? get companionItem =>
      _companionIndex != null && _companionIndex! < _queue.length
          ? _queue[_companionIndex!]
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

  List<MediaItem> _filterFolder(List<MediaItem> items, NasFolder folder) {
    if (folder.showVideos) return items;
    return items.where((i) => i.type != MediaType.video).toList();
  }

  Future<void> scanSources(List<NasSource> sources) async {
    if (_isScanning || _isBackgroundIndexing) return;
    _sources = sources;
    _isScanning = true;
    _isBackgroundIndexing = true;
    _error = null;
    notifyListeners(); // → UI shows loading screen

    bool firstFolderLoaded = false;
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
            final raw = await service.listMediaFiles(
              folder.path,
              recursive: folder.recursive,
            );
            final items = _filterFolder(raw, folder);
            diagLines.add('[${source.name}] ${folder.path} → ${items.length} file(s)');

            if (!firstFolderLoaded) {
              // Eager start: show this folder immediately
              items.shuffle();
              _queue = List.from(items);
              if (_queue.isNotEmpty && _currentIndex < 0) {
                _currentIndex = 0;
                _prefetchCurrent();
              }
              _isScanning = false; // ← dismiss loading screen
              firstFolderLoaded = true;
              notifyListeners(); // → UI switches to slideshow
              _startAutoAdvance();
            } else {
              // Background: append only new items
              final existingPaths = _queue.map((e) => e.remotePath).toSet();
              final newItems = items
                  .where((i) => !existingPaths.contains(i.remotePath))
                  .toList();
              if (newItems.isNotEmpty) {
                newItems.shuffle();
                _queue.addAll(newItems);
                notifyListeners();
              }
            }
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

    _isBackgroundIndexing = false;

    // If no folder loaded at all, clear the loading screen
    if (!firstFolderLoaded) {
      _isScanning = false;
      _error = 'No media files found\n${diagLines.join('\n')}';
      notifyListeners();
    }

    _startPeriodicRescan();
  }

  void _startPeriodicRescan() {
    _rescanTimer?.cancel();
    _rescanTimer = Timer.periodic(kSlideshowRescanInterval, (_) => _incrementalRescan());
  }

  Future<void> _incrementalRescan() async {
    if (_isScanning || _isBackgroundIndexing || _sources.isEmpty) return;

    final existingPaths = _queue.map((e) => e.remotePath).toSet();
    final newItems = <MediaItem>[];

    for (final source in _sources) {
      NasService? service;
      try {
        service = _nasFactory.create(source);
        await service.connect();
        for (final folder in source.folders) {
          try {
            final raw = await service.listMediaFiles(
              folder.path,
              recursive: folder.recursive,
            );
            for (final item in _filterFolder(raw, folder)) {
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
    final skipTo = _companionIndex != null
        ? (_companionIndex! + 1) % _queue.length
        : (_currentIndex + 1) % _queue.length;
    _currentIndex = skipTo;
    _companionIndex = null;
    _isVideoPlaying = false;
    notifyListeners();
    _prefetchCurrent();
    _resetAutoAdvance();
  }

  void previous() {
    if (_queue.isEmpty) return;
    _companionIndex = null;
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

  Future<void> rescanFolder(NasSource source, NasFolder folder) async {
    NasService? service;
    try {
      service = _nasFactory.create(source);
      await service.connect();
      final raw = await service.listMediaFiles(
        folder.path,
        recursive: folder.recursive,
      );
      final freshItems = _filterFolder(raw, folder);
      final freshPaths = freshItems.map((i) => i.remotePath).toSet();

      // Identify stale items from this folder (present in queue but absent from
      // the fresh filtered listing — e.g. videos when showVideos was just turned off,
      // or files that were deleted from the NAS).
      final folderPrefix =
          folder.path.endsWith('/') ? folder.path : '${folder.path}/';
      final staleIndices = <int>{};
      for (var i = 0; i < _queue.length; i++) {
        final item = _queue[i];
        if (item.sourceId == source.id &&
            item.remotePath.startsWith(folderPrefix) &&
            !freshPaths.contains(item.remotePath)) {
          staleIndices.add(i);
        }
      }

      bool changed = false;

      if (staleIndices.isNotEmpty) {
        final currentItem =
            _currentIndex >= 0 && _currentIndex < _queue.length
                ? _queue[_currentIndex]
                : null;
        _queue = [
          for (var i = 0; i < _queue.length; i++)
            if (!staleIndices.contains(i)) _queue[i],
        ];
        if (currentItem != null) {
          final newIdx = _queue.indexOf(currentItem);
          _currentIndex = newIdx >= 0
              ? newIdx
              : (_queue.isEmpty ? -1 : _currentIndex.clamp(0, _queue.length - 1));
        } else {
          _currentIndex =
              _queue.isEmpty ? -1 : _currentIndex.clamp(0, _queue.length - 1);
        }
        changed = true;
      }

      // Add items that are genuinely new (not already in queue)
      final existingPaths = _queue.map((e) => e.remotePath).toSet();
      final newItems =
          freshItems.where((i) => !existingPaths.contains(i.remotePath)).toList();
      if (newItems.isNotEmpty) {
        newItems.shuffle();
        _queue.addAll(newItems);
        changed = true;
      }

      if (changed) notifyListeners();
    } catch (_) {
    } finally {
      await service?.disconnect();
    }
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

    await _updateCompanion();
  }

  Future<void> _downloadItem(MediaItem item) async {
    final source = item.sourceId;
    final cachePath = _cacheService.getCachePath(source, item.remotePath);

    if (_cacheService.isCached(source, item.remotePath)) {
      item.localCachePath = cachePath;
      if (item.width == null) unawaited(_loadItemDimensions(item));
    }
  }

  /// Download a specific item from NAS to cache
  Future<bool> ensureCached(MediaItem item, NasSource source) async {
    final cachePath =
        _cacheService.getCachePath(item.sourceId, item.remotePath);

    if (_cacheService.isCached(item.sourceId, item.remotePath)) {
      item.localCachePath = cachePath;
      if (item.width == null) await _loadItemDimensions(item);
      return true;
    }

    NasService? service;
    try {
      await _cacheService.evictIfNeeded();
      service = _nasFactory.create(source);
      await service.connect();
      await service.downloadFile(item.remotePath, cachePath);
      item.localCachePath = cachePath;
      if (item.width == null) await _loadItemDimensions(item);
      notifyListeners();
      return true;
    } catch (e) {
      print('Error downloading ${item.remotePath}: $e');
      return false;
    } finally {
      await service?.disconnect();
    }
  }

  Future<void> _loadItemDimensions(MediaItem item) async {
    if (item.localCachePath == null) return;
    try {
      final size = item.type == MediaType.image
          ? await _readImageSize(item.localCachePath!)
          : await _readVideoSize(item.localCachePath!);
      if (size != null) {
        item.width = size.width.toInt();
        item.height = size.height.toInt();
      }
    } catch (_) {}
  }

  Future<ui.Size?> _readImageSize(String path) async {
    try {
      final buffer = await ui.ImmutableBuffer.fromFilePath(path);
      final descriptor = await ui.ImageDescriptor.encoded(buffer);
      final size = ui.Size(
        descriptor.width.toDouble(),
        descriptor.height.toDouble(),
      );
      descriptor.dispose();
      buffer.dispose();
      return size;
    } catch (_) {
      return null;
    }
  }

  Future<ui.Size?> _readVideoSize(String path) async {
    final controller = VideoPlayerController.file(File(path));
    try {
      await controller.initialize();
      final size = controller.value.size;
      return size.width > 0 ? size : null;
    } catch (_) {
      return null;
    } finally {
      await controller.dispose();
    }
  }

  Future<void> _updateCompanion() async {
    final current = currentItem;
    if (current == null) {
      _companionIndex = null;
      notifyListeners();
      return;
    }

    // Only probe images here — probing a video creates a second VideoPlayerController
    // for the same file and kills the active player. Video dimensions are loaded
    // in the background by _downloadItem / ensureCached before playback begins.
    if (current.width == null && current.isCached && current.type == MediaType.image) {
      await _loadItemDimensions(current);
    }

    // Find the closest companion with the same orientation (portrait↔portrait or landscape↔landscape)
    for (var i = 1; i <= kPrefetchCount && i < _queue.length; i++) {
      final idx = (_currentIndex + i) % _queue.length;
      final candidate = _queue[idx];
      if (!candidate.isCached) continue;
      // Only probe images inline; skip video candidates with unknown dimensions
      // (they will be probed by the background _downloadItem path).
      if (candidate.width == null && candidate.type == MediaType.image) {
        await _loadItemDimensions(candidate);
      }
      if (candidate.isPortrait == current.isPortrait) {
        if (_companionIndex != idx) {
          _companionIndex = idx;
          notifyListeners();
        }
        return;
      }
    }

    if (_companionIndex != null) {
      _companionIndex = null;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _autoAdvanceTimer?.cancel();
    _rescanTimer?.cancel();
    super.dispose();
  }
}
