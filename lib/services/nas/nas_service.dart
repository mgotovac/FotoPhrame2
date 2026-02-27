import '../../models/media_item.dart';

abstract class NasService {
  Future<void> connect();
  Future<List<MediaItem>> listMediaFiles(String folderPath,
      {bool recursive = false});
  Future<String> downloadFile(String remotePath, String localPath);
  Future<bool> testConnection();
  Future<void> disconnect();
  Future<List<String>> listDirectories(String path);
}
