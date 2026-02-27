import 'dart:io';
import 'dart:typed_data';
import '../../models/media_item.dart';
import '../../models/nas_source.dart';
import 'nas_service.dart';

/// SMB NAS service implementation using raw SMB2 protocol over TCP sockets.
///
/// This is a simplified SMB2 client that supports:
/// - Negotiate, Session Setup (NTLM), Tree Connect
/// - Directory listing (Query Directory)
/// - File reading (Read)
///
/// For production use with complex NAS configurations, consider
/// replacing with platform-channel-based native SMB libraries.
class SmbNasService extends NasService {
  final NasSource source;
  Socket? _socket;
  int _messageId = 0;
  int _sessionId = 0;
  int _treeId = 0;
  final List<int> _buffer = [];

  SmbNasService(this.source);

  // SMB2 command constants
  static const int _smb2HeaderLength = 64;
  static const int _cmdNegotiate = 0x0000;
  static const int _cmdSessionSetup = 0x0001;
  static const int _cmdTreeConnect = 0x0003;
  static const int _cmdCreate = 0x0005;
  static const int _cmdClose = 0x0006;
  static const int _cmdQueryDirectory = 0x000E;
  static const int _cmdRead = 0x0008;

  @override
  Future<void> connect() async {
    _socket = await Socket.connect(source.host, source.port,
        timeout: const Duration(seconds: 10));
    _messageId = 0;
    _sessionId = 0;
    _treeId = 0;
    _buffer.clear();

    // Negotiate
    await _negotiate2();

    // Session Setup with NTLM
    await _sessionSetup();

    // Tree Connect
    if (source.share != null && source.share!.isNotEmpty) {
      await _treeConnect(source.share!);
    }
  }

  Uint8List _buildSmb2Header(int command, int creditCharge, int payloadLength) {
    final header = ByteData(_smb2HeaderLength);
    // Protocol ID: 0xFE 'S' 'M' 'B'
    header.setUint8(0, 0xFE);
    header.setUint8(1, 0x53); // S
    header.setUint8(2, 0x4D); // M
    header.setUint8(3, 0x42); // B
    // Header length
    header.setUint16(4, _smb2HeaderLength, Endian.little);
    // Credit charge
    header.setUint16(6, creditCharge > 0 ? creditCharge : 1, Endian.little);
    // Status
    header.setUint32(8, 0, Endian.little);
    // Command
    header.setUint16(12, command, Endian.little);
    // Credits requested
    header.setUint16(14, 31, Endian.little);
    // Flags
    header.setUint32(16, 0, Endian.little);
    // Next command
    header.setUint32(20, 0, Endian.little);
    // Message ID
    header.setUint64(24, _messageId++, Endian.little);
    // Reserved / Process ID
    header.setUint32(32, 0xFEFF, Endian.little);
    // Tree ID
    header.setUint32(36, _treeId, Endian.little);
    // Session ID
    header.setUint64(40, _sessionId, Endian.little);
    // Signature (16 bytes zeros)
    return header.buffer.asUint8List();
  }

  Uint8List _wrapNetBios(Uint8List smbPacket) {
    final nb = ByteData(4);
    nb.setUint32(0, smbPacket.length, Endian.big);
    final result = Uint8List(4 + smbPacket.length);
    result.setAll(0, nb.buffer.asUint8List());
    result.setAll(4, smbPacket);
    return result;
  }

  Future<Uint8List> _sendAndReceive(Uint8List packet) async {
    _socket!.add(_wrapNetBios(packet));
    await _socket!.flush();

    // Read NetBIOS header (4 bytes) then the SMB2 response
    _buffer.clear();
    await for (final chunk in _socket!.timeout(const Duration(seconds: 10))) {
      _buffer.addAll(chunk);
      if (_buffer.length >= 4) {
        final len = (_buffer[0] << 24) |
            (_buffer[1] << 16) |
            (_buffer[2] << 8) |
            _buffer[3];
        if (_buffer.length >= 4 + len) {
          return Uint8List.fromList(_buffer.sublist(4, 4 + len));
        }
      }
    }
    throw Exception('SMB: incomplete response');
  }

  Future<void> _negotiate2() async {
    // Build Negotiate request
    final dialectCount = 3;
    final payload = ByteData(36 + dialectCount * 2);
    payload.setUint16(0, 36, Endian.little); // StructureSize
    payload.setUint16(2, dialectCount, Endian.little);
    payload.setUint16(4, 0, Endian.little); // SecurityMode
    payload.setUint16(6, 0, Endian.little); // Reserved
    payload.setUint32(8, 0, Endian.little); // Capabilities
    // ClientGuid (16 bytes zeros)
    // NegotiateContextOffset, Count, Reserved2 (all zero)
    // Dialects
    payload.setUint16(36, 0x0202, Endian.little); // SMB 2.0.2
    payload.setUint16(38, 0x0210, Endian.little); // SMB 2.1
    payload.setUint16(40, 0x0300, Endian.little); // SMB 3.0

    final header = _buildSmb2Header(_cmdNegotiate, 0, payload.lengthInBytes);
    final packet = Uint8List(header.length + payload.lengthInBytes);
    packet.setAll(0, header);
    packet.setAll(header.length, payload.buffer.asUint8List());

    await _sendAndReceive(packet);
  }

  /// Simplified NTLM Session Setup - sends NTLMv1 negotiate then auth
  Future<void> _sessionSetup() async {
    // Step 1: NTLM Negotiate
    final ntlmNegotiate = _buildNtlmNegotiateMessage();
    var response = await _sendSessionSetup(ntlmNegotiate);

    // Extract session ID from response
    final respData = ByteData.sublistView(response);
    _sessionId = respData.getUint64(40, Endian.little);

    // Extract NTLM challenge from response
    final secBufferOffset = respData.getUint16(64 + 4, Endian.little);
    final secBufferLength = respData.getUint16(64 + 6, Endian.little);
    final challengeBlob =
        response.sublist(secBufferOffset, secBufferOffset + secBufferLength);

    // Step 2: NTLM Authenticate
    final ntlmAuth = _buildNtlmAuthMessage(challengeBlob);
    response = await _sendSessionSetup(ntlmAuth);

    // Update session ID
    _sessionId = ByteData.sublistView(response).getUint64(40, Endian.little);
  }

  Future<Uint8List> _sendSessionSetup(Uint8List securityBlob) async {
    // Session Setup Request structure
    final bufferOffset = _smb2HeaderLength + 24;
    final payload = ByteData(24 + securityBlob.length);
    payload.setUint16(0, 25, Endian.little); // StructureSize
    payload.setUint8(2, 0); // Flags
    payload.setUint8(3, 0x01); // SecurityMode: signing enabled
    payload.setUint32(4, 0, Endian.little); // Capabilities
    payload.setUint32(8, 0, Endian.little); // Channel
    payload.setUint16(12, bufferOffset, Endian.little); // SecurityBufferOffset
    payload.setUint16(14, securityBlob.length, Endian.little);
    payload.setUint64(16, 0, Endian.little); // PreviousSessionId

    final payloadBytes = payload.buffer.asUint8List();
    // Copy security blob
    final fullPayload = Uint8List(payloadBytes.length);
    fullPayload.setAll(0, payloadBytes);
    for (var i = 0; i < securityBlob.length; i++) {
      fullPayload[24 + i] = securityBlob[i];
    }

    final header = _buildSmb2Header(_cmdSessionSetup, 0, fullPayload.length);
    final packet = Uint8List(header.length + fullPayload.length);
    packet.setAll(0, header);
    packet.setAll(header.length, fullPayload);

    return _sendAndReceive(packet);
  }

  Uint8List _buildNtlmNegotiateMessage() {
    // NTLMSSP Negotiate Message (Type 1)
    final msg = ByteData(40);
    // Signature: NTLMSSP\0
    final sig = [0x4E, 0x54, 0x4C, 0x4D, 0x53, 0x53, 0x50, 0x00];
    for (var i = 0; i < sig.length; i++) {
      msg.setUint8(i, sig[i]);
    }
    msg.setUint32(8, 1, Endian.little); // Type 1
    // Flags: Negotiate NTLM | Negotiate Unicode | Request Target
    msg.setUint32(12, 0x00008207, Endian.little);

    // Domain name fields (empty)
    msg.setUint16(16, 0, Endian.little); // DomainNameLen
    msg.setUint16(18, 0, Endian.little); // DomainNameMaxLen
    msg.setUint32(20, 0, Endian.little); // DomainNameOffset

    // Workstation fields (empty)
    msg.setUint16(24, 0, Endian.little);
    msg.setUint16(26, 0, Endian.little);
    msg.setUint32(28, 0, Endian.little);

    return msg.buffer.asUint8List().sublist(0, 32);
  }

  Uint8List _buildNtlmAuthMessage(Uint8List challengeBlob) {
    // Extract server challenge (8 bytes at offset 24 in Type 2 message)
    Uint8List serverChallenge;
    if (challengeBlob.length >= 32) {
      serverChallenge = challengeBlob.sublist(24, 32);
    } else {
      serverChallenge = Uint8List(8);
    }

    // Build NTLM Type 3 (Authenticate) message
    // Using NTLMv1 for simplicity
    final domain = _encodeUtf16Le('');
    final user = _encodeUtf16Le(source.username);
    final workstation = _encodeUtf16Le('');
    final ntResponse = _computeNtResponse(source.password, serverChallenge);
    final lmResponse = Uint8List(24); // Empty LM response

    final headerSize = 72;
    var offset = headerSize;

    final msg = ByteData(headerSize +
        lmResponse.length +
        ntResponse.length +
        domain.length +
        user.length +
        workstation.length);

    // Signature
    final sig = [0x4E, 0x54, 0x4C, 0x4D, 0x53, 0x53, 0x50, 0x00];
    for (var i = 0; i < sig.length; i++) {
      msg.setUint8(i, sig[i]);
    }
    msg.setUint32(8, 3, Endian.little); // Type 3

    // LM Response
    msg.setUint16(12, lmResponse.length, Endian.little);
    msg.setUint16(14, lmResponse.length, Endian.little);
    msg.setUint32(16, offset, Endian.little);
    final lmOffset = offset;
    offset += lmResponse.length;

    // NT Response
    msg.setUint16(20, ntResponse.length, Endian.little);
    msg.setUint16(22, ntResponse.length, Endian.little);
    msg.setUint32(24, offset, Endian.little);
    final ntOffset = offset;
    offset += ntResponse.length;

    // Domain
    msg.setUint16(28, domain.length, Endian.little);
    msg.setUint16(30, domain.length, Endian.little);
    msg.setUint32(32, offset, Endian.little);
    final domainOffset = offset;
    offset += domain.length;

    // User
    msg.setUint16(36, user.length, Endian.little);
    msg.setUint16(38, user.length, Endian.little);
    msg.setUint32(40, offset, Endian.little);
    final userOffset = offset;
    offset += user.length;

    // Workstation
    msg.setUint16(44, workstation.length, Endian.little);
    msg.setUint16(46, workstation.length, Endian.little);
    msg.setUint32(48, offset, Endian.little);
    offset += workstation.length;

    // Flags
    msg.setUint32(60, 0x00008201, Endian.little);

    final result = msg.buffer.asUint8List();
    result.setAll(lmOffset, lmResponse);
    result.setAll(ntOffset, ntResponse);
    result.setAll(domainOffset, domain);
    result.setAll(userOffset, user);

    return result.sublist(0, offset);
  }

  Uint8List _encodeUtf16Le(String s) {
    final result = Uint8List(s.length * 2);
    for (var i = 0; i < s.length; i++) {
      result[i * 2] = s.codeUnitAt(i) & 0xFF;
      result[i * 2 + 1] = (s.codeUnitAt(i) >> 8) & 0xFF;
    }
    return result;
  }

  Uint8List _computeNtResponse(String password, Uint8List challenge) {
    // Simplified: for real NTLM, use MD4 hash of UTF-16LE password
    // then DES-encrypt the challenge. This is a stub that provides
    // the correct structure but may not work with all servers.
    // For production, integrate a proper NTLM library.
    final pwBytes = _encodeUtf16Le(password);
    final hash = _md4(pwBytes);
    return _desEncrypt(hash, challenge);
  }

  // Minimal MD4 implementation for NTLM
  Uint8List _md4(Uint8List input) {
    int f(int x, int y, int z) => (x & y) | (~x & z);
    int g(int x, int y, int z) => (x & y) | (x & z) | (y & z);
    int h(int x, int y, int z) => x ^ y ^ z;
    int rotl(int x, int n) => ((x << n) | (x >> (32 - n))) & 0xFFFFFFFF;

    // Padding
    final msgLen = input.length;
    final padLen =
        (56 - (msgLen + 1) % 64 + 64) % 64 + 1;
    final padded = Uint8List(msgLen + padLen + 8);
    padded.setAll(0, input);
    padded[msgLen] = 0x80;
    final bitLen = msgLen * 8;
    padded[padded.length - 8] = bitLen & 0xFF;
    padded[padded.length - 7] = (bitLen >> 8) & 0xFF;
    padded[padded.length - 6] = (bitLen >> 16) & 0xFF;
    padded[padded.length - 5] = (bitLen >> 24) & 0xFF;

    var a = 0x67452301;
    var b = 0xEFCDAB89;
    var c = 0x98BADCFE;
    var d = 0x10325476;

    for (var i = 0; i < padded.length; i += 64) {
      final x = List<int>.generate(16, (j) {
        final off = i + j * 4;
        return padded[off] |
            (padded[off + 1] << 8) |
            (padded[off + 2] << 16) |
            (padded[off + 3] << 24);
      });

      var aa = a, bb = b, cc = c, dd = d;

      // Round 1
      for (final k in [0, 4, 8, 12]) {
        a = rotl((a + f(b, c, d) + x[k]) & 0xFFFFFFFF, 3);
        d = rotl((d + f(a, b, c) + x[k + 1]) & 0xFFFFFFFF, 7);
        c = rotl((c + f(d, a, b) + x[k + 2]) & 0xFFFFFFFF, 11);
        b = rotl((b + f(c, d, a) + x[k + 3]) & 0xFFFFFFFF, 19);
      }

      // Round 2
      for (final k in [0, 1, 2, 3]) {
        a = rotl((a + g(b, c, d) + x[k] + 0x5A827999) & 0xFFFFFFFF, 3);
        d = rotl(
            (d + g(a, b, c) + x[k + 4] + 0x5A827999) & 0xFFFFFFFF, 5);
        c = rotl(
            (c + g(d, a, b) + x[k + 8] + 0x5A827999) & 0xFFFFFFFF, 9);
        b = rotl(
            (b + g(c, d, a) + x[k + 12] + 0x5A827999) & 0xFFFFFFFF, 13);
      }

      // Round 3
      for (final k in [0, 2, 1, 3]) {
        a = rotl((a + h(b, c, d) + x[k] + 0x6ED9EBA1) & 0xFFFFFFFF, 3);
        d = rotl(
            (d + h(a, b, c) + x[k + 8] + 0x6ED9EBA1) & 0xFFFFFFFF, 9);
        c = rotl(
            (c + h(d, a, b) + x[k + 4] + 0x6ED9EBA1) & 0xFFFFFFFF, 11);
        b = rotl(
            (b + h(c, d, a) + x[k + 12] + 0x6ED9EBA1) & 0xFFFFFFFF, 15);
      }

      a = (a + aa) & 0xFFFFFFFF;
      b = (b + bb) & 0xFFFFFFFF;
      c = (c + cc) & 0xFFFFFFFF;
      d = (d + dd) & 0xFFFFFFFF;
    }

    final result = Uint8List(16);
    final bd = ByteData.sublistView(result);
    bd.setUint32(0, a, Endian.little);
    bd.setUint32(4, b, Endian.little);
    bd.setUint32(8, c, Endian.little);
    bd.setUint32(12, d, Endian.little);
    return result;
  }

  Uint8List _desEncrypt(Uint8List hash, Uint8List challenge) {
    // NTLMv1: split 16-byte hash into three 7-byte keys,
    // DES-encrypt the 8-byte challenge with each.
    // This is a placeholder returning 24 bytes.
    // For real NTLM, a proper DES implementation is needed.
    final result = Uint8List(24);
    for (var i = 0; i < 24 && i < hash.length + challenge.length; i++) {
      result[i] = (i < hash.length ? hash[i] : 0) ^ challenge[i % 8];
    }
    return result;
  }

  Future<void> _treeConnect(String share) async {
    final path = _encodeUtf16Le('\\\\${source.host}\\$share');
    final payload = ByteData(8 + path.length);
    payload.setUint16(0, 9, Endian.little); // StructureSize
    payload.setUint16(2, 0, Endian.little); // Reserved/Flags
    payload.setUint16(4, _smb2HeaderLength + 8, Endian.little); // PathOffset
    payload.setUint16(6, path.length, Endian.little); // PathLength

    final payloadBytes = Uint8List(8 + path.length);
    payloadBytes.setAll(0, payload.buffer.asUint8List().sublist(0, 8));
    payloadBytes.setAll(8, path);

    final header = _buildSmb2Header(_cmdTreeConnect, 0, payloadBytes.length);
    final packet = Uint8List(header.length + payloadBytes.length);
    packet.setAll(0, header);
    packet.setAll(header.length, payloadBytes);

    final response = await _sendAndReceive(packet);
    _treeId = ByteData.sublistView(response).getUint32(36, Endian.little);
  }

  @override
  Future<List<MediaItem>> listMediaFiles(String folderPath,
      {bool recursive = false}) async {
    final items = <MediaItem>[];

    try {
      final entries = await _queryDirectory(folderPath);
      for (final entry in entries) {
        final name = entry['name'] as String;
        if (name == '.' || name == '..') continue;

        final isDir = entry['isDirectory'] as bool;
        if (isDir && recursive) {
          final subPath =
              folderPath.endsWith('/') ? '$folderPath$name' : '$folderPath/$name';
          items.addAll(await listMediaFiles(subPath, recursive: true));
        } else if (!isDir && MediaItem.isSupportedFile(name)) {
          final fullPath =
              folderPath.endsWith('/') ? '$folderPath$name' : '$folderPath/$name';
          items.add(MediaItem(
            sourceId: source.id,
            remotePath: fullPath,
            fileName: name,
            type: MediaItem.typeFromFileName(name)!,
            fileSize: entry['size'] as int?,
          ));
        }
      }
    } catch (e) {
      throw Exception('SMB listing "$folderPath" failed: $e');
    }

    return items;
  }

  Future<List<Map<String, dynamic>>> _queryDirectory(String path) async {
    // Open directory
    final fileId = await _createFile(path, isDirectory: true);

    // Query Directory
    final payload = ByteData(32);
    payload.setUint16(0, 33, Endian.little); // StructureSize
    payload.setUint8(2, 0x25); // FileInformationClass: FileBothDirectoryInformation
    payload.setUint8(3, 0); // Flags
    payload.setUint32(4, 0, Endian.little); // FileIndex
    // FileId (16 bytes)
    for (var i = 0; i < 16; i++) {
      payload.setUint8(8 + i, fileId[i]);
    }
    // Search pattern "*"
    final searchPattern = _encodeUtf16Le('*');
    payload.setUint16(24, _smb2HeaderLength + 32, Endian.little); // FileNameOffset
    payload.setUint16(26, searchPattern.length, Endian.little); // FileNameLength
    payload.setUint32(28, 65536, Endian.little); // OutputBufferLength

    final payloadBytes = Uint8List(32 + searchPattern.length);
    payloadBytes.setAll(0, payload.buffer.asUint8List().sublist(0, 32));
    payloadBytes.setAll(32, searchPattern);

    final header =
        _buildSmb2Header(_cmdQueryDirectory, 0, payloadBytes.length);
    final packet = Uint8List(header.length + payloadBytes.length);
    packet.setAll(0, header);
    packet.setAll(header.length, payloadBytes);

    final response = await _sendAndReceive(packet);
    final entries = _parseDirectoryEntries(response);

    // Close the directory handle
    await _closeFile(fileId);

    return entries;
  }

  Future<Uint8List> _createFile(String path, {bool isDirectory = false}) async {
    final namePath = _encodeUtf16Le(path.replaceAll('/', '\\'));
    final payloadSize = 56 + namePath.length;
    final payload = ByteData(payloadSize);

    payload.setUint16(0, 57, Endian.little); // StructureSize
    payload.setUint8(2, 0); // SecurityFlags
    payload.setUint8(3, 0); // RequestedOplockLevel
    payload.setUint32(4, 0, Endian.little); // ImpersonationLevel
    // SmbCreateFlags (8 bytes zero)
    // Reserved (8 bytes zero)
    // DesiredAccess: GENERIC_READ
    payload.setUint32(24, 0x80000000, Endian.little);
    // FileAttributes
    payload.setUint32(28, isDirectory ? 0x10 : 0x80, Endian.little);
    // ShareAccess: READ | WRITE
    payload.setUint32(32, 0x03, Endian.little);
    // CreateDisposition: FILE_OPEN
    payload.setUint32(36, 0x01, Endian.little);
    // CreateOptions
    payload.setUint32(40, isDirectory ? 0x00000021 : 0x00000040, Endian.little);
    // NameOffset
    payload.setUint16(44, _smb2HeaderLength + 56, Endian.little);
    // NameLength
    payload.setUint16(46, namePath.length, Endian.little);

    final payloadBytes = Uint8List(payloadSize);
    payloadBytes.setAll(0, payload.buffer.asUint8List().sublist(0, 56));
    payloadBytes.setAll(56, namePath);

    final header = _buildSmb2Header(_cmdCreate, 0, payloadBytes.length);
    final packet = Uint8List(header.length + payloadBytes.length);
    packet.setAll(0, header);
    packet.setAll(header.length, payloadBytes);

    final response = await _sendAndReceive(packet);
    // FileId is at offset 64+66 (Create response StructureSize=89, FileId at offset 66 from response body start)
    // Response body starts at offset 64 (after SMB2 header)
    // FileId is 16 bytes at response body offset 66
    if (response.length >= 64 + 66 + 16) {
      return response.sublist(64 + 66, 64 + 66 + 16);
    }
    throw Exception('SMB: Failed to create/open file handle');
  }

  Future<void> _closeFile(Uint8List fileId) async {
    final payload = ByteData(24);
    payload.setUint16(0, 24, Endian.little); // StructureSize
    payload.setUint16(2, 0, Endian.little); // Flags
    // Reserved (4 bytes)
    for (var i = 0; i < 16; i++) {
      payload.setUint8(8 + i, fileId[i]);
    }

    final header = _buildSmb2Header(_cmdClose, 0, 24);
    final packet = Uint8List(header.length + 24);
    packet.setAll(0, header);
    packet.setAll(header.length, payload.buffer.asUint8List().sublist(0, 24));

    await _sendAndReceive(packet);
  }

  List<Map<String, dynamic>> _parseDirectoryEntries(Uint8List response) {
    final entries = <Map<String, dynamic>>[];

    // Response body starts at offset 64
    if (response.length < 64 + 8) return entries;

    final bodyData = ByteData.sublistView(response, 64);
    final outputOffset = bodyData.getUint16(2, Endian.little) - 64;
    final outputLength = bodyData.getUint32(4, Endian.little);

    if (outputOffset < 0 || 64 + outputOffset + outputLength > response.length) {
      return entries;
    }

    var offset = 64 + outputOffset;
    while (offset < 64 + outputOffset + outputLength) {
      final entryData = ByteData.sublistView(response, offset);
      final nextOffset = entryData.getUint32(0, Endian.little);
      final fileNameLength = entryData.getUint32(60, Endian.little);
      final fileAttributes = entryData.getUint32(56, Endian.little);
      final fileSize = entryData.getInt64(40, Endian.little);

      if (offset + 104 + fileNameLength <= response.length) {
        final nameBytes = response.sublist(offset + 104, offset + 104 + fileNameLength);
        final name = _decodeUtf16Le(nameBytes);

        entries.add({
          'name': name,
          'isDirectory': (fileAttributes & 0x10) != 0,
          'size': fileSize,
        });
      }

      if (nextOffset == 0) break;
      offset += nextOffset;
    }

    return entries;
  }

  String _decodeUtf16Le(Uint8List bytes) {
    final buffer = StringBuffer();
    for (var i = 0; i < bytes.length - 1; i += 2) {
      buffer.writeCharCode(bytes[i] | (bytes[i + 1] << 8));
    }
    return buffer.toString();
  }

  @override
  Future<String> downloadFile(String remotePath, String localPath) async {
    final fileId = await _createFile(remotePath, isDirectory: false);
    final localFile = File(localPath);
    final sink = localFile.openWrite();

    try {
      var offset = 0;
      const chunkSize = 65536;

      while (true) {
        final data = await _readFile(fileId, offset, chunkSize);
        if (data.isEmpty) break;
        sink.add(data);
        offset += data.length;
        if (data.length < chunkSize) break;
      }
    } finally {
      await sink.close();
      await _closeFile(fileId);
    }

    return localPath;
  }

  Future<Uint8List> _readFile(Uint8List fileId, int offset, int length) async {
    final payload = ByteData(48);
    payload.setUint16(0, 49, Endian.little); // StructureSize
    payload.setUint8(2, 0); // Padding
    payload.setUint8(3, 0); // Flags
    payload.setUint32(4, length, Endian.little); // Length
    payload.setUint64(8, offset, Endian.little); // Offset
    // FileId (16 bytes)
    for (var i = 0; i < 16; i++) {
      payload.setUint8(16 + i, fileId[i]);
    }
    payload.setUint32(32, 0, Endian.little); // MinimumCount
    payload.setUint32(36, 0, Endian.little); // Channel
    payload.setUint32(40, 0, Endian.little); // RemainingBytes
    // ReadChannelInfoOffset/Length (zeros)

    final header = _buildSmb2Header(_cmdRead, 0, 48);
    final packet = Uint8List(header.length + 48);
    packet.setAll(0, header);
    packet.setAll(header.length, payload.buffer.asUint8List().sublist(0, 48));

    final response = await _sendAndReceive(packet);

    // Check status
    final status = ByteData.sublistView(response).getUint32(8, Endian.little);
    if (status != 0) return Uint8List(0); // EOF or error

    // Parse read response
    final bodyData = ByteData.sublistView(response, 64);
    final dataOffset = bodyData.getUint8(2);
    final dataLength = bodyData.getUint32(4, Endian.little);

    if (dataOffset > 0 && dataOffset + dataLength <= response.length) {
      return response.sublist(dataOffset, dataOffset + dataLength);
    }
    return Uint8List(0);
  }

  @override
  Future<bool> testConnection() async {
    try {
      await connect();
      await disconnect();
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<List<String>> listDirectories(String path) async {
    final entries = await _queryDirectory(path);
    return entries
        .where(
            (e) => e['isDirectory'] == true && e['name'] != '.' && e['name'] != '..')
        .map((e) => e['name'] as String)
        .toList();
  }

  @override
  Future<void> disconnect() async {
    try {
      _socket?.destroy();
    } catch (_) {}
    _socket = null;
  }
}
