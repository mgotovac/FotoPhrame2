enum NasProtocol { smb, webdav }

class NasFolder {
  final String path;
  final bool recursive;

  const NasFolder({required this.path, this.recursive = false});

  Map<String, dynamic> toJson() => {
        'path': path,
        'recursive': recursive,
      };

  factory NasFolder.fromJson(Map<String, dynamic> json) => NasFolder(
        path: json['path'] as String,
        recursive: json['recursive'] as bool? ?? false,
      );
}

class NasSource {
  final String id;
  final String name;
  final NasProtocol protocol;
  final String host;
  final int port;
  final String? share; // SMB share name
  final String? basePath; // WebDAV base path
  final String username;
  final String password;
  final List<NasFolder> folders;

  const NasSource({
    required this.id,
    required this.name,
    required this.protocol,
    required this.host,
    required this.port,
    this.share,
    this.basePath,
    required this.username,
    required this.password,
    required this.folders,
  });

  NasSource copyWith({
    String? id,
    String? name,
    NasProtocol? protocol,
    String? host,
    int? port,
    String? share,
    String? basePath,
    String? username,
    String? password,
    List<NasFolder>? folders,
  }) =>
      NasSource(
        id: id ?? this.id,
        name: name ?? this.name,
        protocol: protocol ?? this.protocol,
        host: host ?? this.host,
        port: port ?? this.port,
        share: share ?? this.share,
        basePath: basePath ?? this.basePath,
        username: username ?? this.username,
        password: password ?? this.password,
        folders: folders ?? this.folders,
      );

  static int defaultPort(NasProtocol protocol) {
    switch (protocol) {
      case NasProtocol.smb:
        return 445;
      case NasProtocol.webdav:
        return 80;
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'protocol': protocol.name,
        'host': host,
        'port': port,
        'share': share,
        'basePath': basePath,
        'username': username,
        'password': password,
        'folders': folders.map((f) => f.toJson()).toList(),
      };

  factory NasSource.fromJson(Map<String, dynamic> json) => NasSource(
        id: json['id'] as String,
        name: json['name'] as String,
        protocol: NasProtocol.values.byName(json['protocol'] as String),
        host: json['host'] as String,
        port: json['port'] as int,
        share: json['share'] as String?,
        basePath: json['basePath'] as String?,
        username: json['username'] as String,
        password: json['password'] as String,
        folders: (json['folders'] as List)
            .map((f) => NasFolder.fromJson(f as Map<String, dynamic>))
            .toList(),
      );
}
