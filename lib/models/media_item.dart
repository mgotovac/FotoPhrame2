import '../utils/constants.dart';

enum MediaType { image, video }

class MediaItem {
  final String sourceId;
  final String remotePath;
  final String fileName;
  final MediaType type;
  final int? fileSize;
  final DateTime? modified;
  String? localCachePath;

  MediaItem({
    required this.sourceId,
    required this.remotePath,
    required this.fileName,
    required this.type,
    this.fileSize,
    this.modified,
    this.localCachePath,
  });

  bool get isCached => localCachePath != null;

  static MediaType? typeFromFileName(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    if (kSupportedImageExtensions.contains(ext)) return MediaType.image;
    if (kSupportedVideoExtensions.contains(ext)) return MediaType.video;
    return null;
  }

  static bool isSupportedFile(String fileName) {
    return typeFromFileName(fileName) != null;
  }
}
