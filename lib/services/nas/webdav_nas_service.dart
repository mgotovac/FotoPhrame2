import 'package:webdav_client/webdav_client.dart' as webdav;
import '../../models/media_item.dart';
import '../../models/nas_source.dart';
import 'nas_service.dart';

class WebDavNasService extends NasService {
  final NasSource source;
  late webdav.Client _client;

  WebDavNasService(this.source);

  String get _baseUrl {
    final scheme = source.port == 443 ? 'https' : 'http';
    final portSuffix =
        (source.port == 80 || source.port == 443) ? '' : ':${source.port}';
    final path = source.basePath ?? '';
    return '$scheme://${source.host}$portSuffix$path';
  }

  @override
  Future<void> connect() async {
    _client = webdav.newClient(
      _baseUrl,
      user: source.username,
      password: source.password,
    );
    _client.setConnectTimeout(10000);
    _client.setSendTimeout(30000);
    _client.setReceiveTimeout(30000);
  }

  @override
  Future<List<MediaItem>> listMediaFiles(String folderPath,
      {bool recursive = false}) async {
    final items = <MediaItem>[];
    try {
      final files = await _client.readDir(folderPath);
      for (final file in files) {
        final name = file.name ?? '';
        if (name.isEmpty || name == '.' || name == '..') continue;

        if (file.isDir == true && recursive) {
          final subPath = folderPath.endsWith('/')
              ? '$folderPath$name'
              : '$folderPath/$name';
          items.addAll(await listMediaFiles(subPath, recursive: true));
        } else if (file.isDir != true && MediaItem.isSupportedFile(name)) {
          final fullPath = file.path ?? '$folderPath/$name';
          items.add(MediaItem(
            sourceId: source.id,
            remotePath: fullPath,
            fileName: name,
            type: MediaItem.typeFromFileName(name)!,
            fileSize: file.size,
            modified: file.mTime,
          ));
        }
      }
    } catch (e) {
      throw Exception('WebDAV listing "$folderPath" failed: $e');
    }
    return items;
  }

  @override
  Future<String> downloadFile(String remotePath, String localPath) async {
    await _client.read2File(remotePath, localPath);
    return localPath;
  }

  /// Returns a direct WebDAV URL for network video playback
  String getDirectUrl(String remotePath) {
    final encodedPath = Uri.encodeFull(remotePath);
    return '$_baseUrl$encodedPath';
  }

  /// Returns basic auth headers for authenticated WebDAV URL access
  Map<String, String> getAuthHeaders() {
    return {
      'Authorization':
          'Basic ${_base64Encode('${source.username}:${source.password}')}',
    };
  }

  String _base64Encode(String input) {
    final bytes = input.codeUnits;
    const chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    final buffer = StringBuffer();
    for (var i = 0; i < bytes.length; i += 3) {
      final b0 = bytes[i];
      final b1 = i + 1 < bytes.length ? bytes[i + 1] : 0;
      final b2 = i + 2 < bytes.length ? bytes[i + 2] : 0;
      buffer.write(chars[(b0 >> 2) & 0x3F]);
      buffer.write(chars[((b0 << 4) | (b1 >> 4)) & 0x3F]);
      buffer.write(
          i + 1 < bytes.length ? chars[((b1 << 2) | (b2 >> 6)) & 0x3F] : '=');
      buffer.write(i + 2 < bytes.length ? chars[b2 & 0x3F] : '=');
    }
    return buffer.toString();
  }

  @override
  Future<bool> testConnection() async {
    try {
      await connect();
      await _client.ping();
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<List<String>> listDirectories(String path) async {
    final dirs = <String>[];
    try {
      final files = await _client.readDir(path);
      for (final file in files) {
        if (file.isDir == true) {
          final name = file.name ?? '';
          if (name.isNotEmpty && name != '.' && name != '..') {
            dirs.add(name);
          }
        }
      }
    } catch (e) {
      print('WebDAV: Error listing directories in $path: $e');
    }
    return dirs;
  }

  @override
  Future<void> disconnect() async {
    // WebDAV is stateless HTTP, no persistent connection to close
  }
}
