import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../utils/constants.dart';

class MediaCacheService {
  late Directory _cacheDir;

  Future<void> init() async {
    final appDir = await getApplicationCacheDirectory();
    _cacheDir = Directory('${appDir.path}/media_cache');
    if (!_cacheDir.existsSync()) {
      _cacheDir.createSync(recursive: true);
    }
  }

  String getCachePath(String sourceId, String remotePath) {
    final hash = remotePath.hashCode.toRadixString(16);
    final ext = remotePath.split('.').last.toLowerCase();
    return '${_cacheDir.path}/${sourceId}_$hash.$ext';
  }

  bool isCached(String sourceId, String remotePath) {
    return File(getCachePath(sourceId, remotePath)).existsSync();
  }

  Future<void> evictIfNeeded() async {
    final files = _cacheDir.listSync().whereType<File>().toList();
    var totalSize = 0;
    for (final file in files) {
      totalSize += file.lengthSync();
    }

    if (totalSize > kMaxCacheSizeMb * 1024 * 1024) {
      // Sort by last accessed time, delete oldest first
      files.sort((a, b) =>
          a.statSync().accessed.compareTo(b.statSync().accessed));

      for (final file in files) {
        if (totalSize <= kMaxCacheSizeMb * 1024 * 1024 * 0.8) break;
        totalSize -= file.lengthSync();
        file.deleteSync();
      }
    }
  }

  Future<void> clearCache() async {
    if (_cacheDir.existsSync()) {
      await _cacheDir.delete(recursive: true);
      _cacheDir.createSync(recursive: true);
    }
  }
}
