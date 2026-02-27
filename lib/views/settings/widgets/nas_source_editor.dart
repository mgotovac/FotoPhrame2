import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../../models/nas_source.dart';

class NasSourceEditor extends StatefulWidget {
  final NasSource? source; // null for new source

  const NasSourceEditor({super.key, this.source});

  @override
  State<NasSourceEditor> createState() => _NasSourceEditorState();
}

class _NasSourceEditorState extends State<NasSourceEditor> {
  late TextEditingController _nameController;
  late TextEditingController _hostController;
  late TextEditingController _portController;
  late TextEditingController _shareController;
  late TextEditingController _basePathController;
  late TextEditingController _usernameController;
  late TextEditingController _passwordController;
  NasProtocol _protocol = NasProtocol.smb;
  List<NasFolder> _folders = [];
  final _folderPathController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final s = widget.source;
    _nameController = TextEditingController(text: s?.name ?? '');
    _hostController = TextEditingController(text: s?.host ?? '');
    _portController = TextEditingController(
        text: s != null ? '${s.port}' : '${NasSource.defaultPort(NasProtocol.smb)}');
    _shareController = TextEditingController(text: s?.share ?? '');
    _basePathController = TextEditingController(text: s?.basePath ?? '');
    _usernameController = TextEditingController(text: s?.username ?? '');
    _passwordController = TextEditingController(text: s?.password ?? '');
    if (s != null) {
      _protocol = s.protocol;
      _folders = List.from(s.folders);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _hostController.dispose();
    _portController.dispose();
    _shareController.dispose();
    _basePathController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _folderPathController.dispose();
    super.dispose();
  }

  void _onProtocolChanged(NasProtocol? protocol) {
    if (protocol == null) return;
    setState(() {
      _protocol = protocol;
      _portController.text = '${NasSource.defaultPort(protocol)}';
    });
  }

  void _addFolder() {
    final path = _folderPathController.text.trim();
    if (path.isEmpty) return;
    setState(() {
      _folders.add(NasFolder(path: path, recursive: true));
      _folderPathController.clear();
    });
  }

  void _removeFolder(int index) {
    setState(() => _folders.removeAt(index));
  }

  NasSource _buildSource() {
    return NasSource(
      id: widget.source?.id ?? const Uuid().v4(),
      name: _nameController.text.trim(),
      protocol: _protocol,
      host: _hostController.text.trim(),
      port: int.tryParse(_portController.text) ??
          NasSource.defaultPort(_protocol),
      share: _protocol == NasProtocol.smb ? _shareController.text.trim() : null,
      basePath:
          _protocol == NasProtocol.webdav ? _basePathController.text.trim() : null,
      username: _usernameController.text.trim(),
      password: _passwordController.text,
      folders: _folders,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.source == null ? 'Add NAS Source' : 'Edit NAS Source'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, _buildSource()),
            child: const Text('Save'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Name',
              hintText: 'e.g. My NAS',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),

          // Protocol
          DropdownButtonFormField<NasProtocol>(
            initialValue: _protocol,
            decoration: const InputDecoration(
              labelText: 'Protocol',
              border: OutlineInputBorder(),
            ),
            items: NasProtocol.values
                .map((p) => DropdownMenuItem(
                      value: p,
                      child: Text(p.name.toUpperCase()),
                    ))
                .toList(),
            onChanged: _onProtocolChanged,
          ),
          const SizedBox(height: 16),

          // Host + Port
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _hostController,
                  decoration: const InputDecoration(
                    labelText: 'Host / IP',
                    hintText: '192.168.1.100',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _portController,
                  decoration: const InputDecoration(
                    labelText: 'Port',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // SMB Share or WebDAV Base Path
          if (_protocol == NasProtocol.smb)
            TextField(
              controller: _shareController,
              decoration: const InputDecoration(
                labelText: 'Share Name',
                hintText: 'photos',
                border: OutlineInputBorder(),
              ),
            ),
          if (_protocol == NasProtocol.webdav)
            TextField(
              controller: _basePathController,
              decoration: const InputDecoration(
                labelText: 'Base Path',
                hintText: '/webdav',
                border: OutlineInputBorder(),
              ),
            ),
          const SizedBox(height: 16),

          // Credentials
          TextField(
            controller: _usernameController,
            decoration: const InputDecoration(
              labelText: 'Username',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _passwordController,
            decoration: const InputDecoration(
              labelText: 'Password',
              border: OutlineInputBorder(),
            ),
            obscureText: true,
          ),
          const SizedBox(height: 24),

          // Folders
          const Text('Folders to scan',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _folderPathController,
                  decoration: const InputDecoration(
                    hintText: '/photos/family',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: _addFolder,
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ..._folders.asMap().entries.map((entry) {
            final idx = entry.key;
            final folder = entry.value;
            return ListTile(
              leading: const Icon(Icons.folder),
              title: Text(folder.path),
              subtitle: Text(folder.recursive ? 'Recursive' : 'Top level only'),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () => _removeFolder(idx),
              ),
            );
          }),
        ],
      ),
    );
  }
}
