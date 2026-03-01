import 'package:flutter/material.dart';
import '../../../models/nas_source.dart';
import '../../../services/nas/nas_service.dart';
import '../../../services/nas/nas_service_factory.dart';

class FolderBrowserDialog extends StatefulWidget {
  final NasSource source;
  const FolderBrowserDialog({required this.source, super.key});

  @override
  State<FolderBrowserDialog> createState() => _FolderBrowserDialogState();
}

class _FolderBrowserDialogState extends State<FolderBrowserDialog> {
  NasService? _service;
  String _currentPath = '/';
  List<String> _dirs = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _navigate('/');
  }

  @override
  void dispose() {
    _service?.disconnect();
    super.dispose();
  }

  String _parentOf(String path) {
    if (path == '/') return '/';
    final idx = path.lastIndexOf('/');
    if (idx <= 0) return '/';
    return path.substring(0, idx);
  }

  Future<void> _navigate(String path) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (_service == null) {
        _service = NasServiceFactory().create(widget.source);
        await _service!.connect();
      }
      final dirs = await _service!.listDirectories(path);
      dirs.sort();
      setState(() {
        _currentPath = path;
        _dirs = dirs;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SizedBox(
        width: 500,
        height: 480,
        child: Column(
          children: [
            // Title bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
              child: Row(
                children: [
                  const Text(
                    'Browse Folders',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context, null),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Path header with Up button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  if (_currentPath != '/')
                    IconButton(
                      icon: const Icon(Icons.arrow_upward),
                      tooltip: 'Go up',
                      onPressed: _loading
                          ? null
                          : () => _navigate(_parentOf(_currentPath)),
                    ),
                  Expanded(
                    child: Text(
                      _currentPath,
                      style: const TextStyle(fontFamily: 'monospace'),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Content area
            Expanded(
              child: _buildContent(),
            ),

            const Divider(height: 1),

            // Select button
            Padding(
              padding: const EdgeInsets.all(8),
              child: Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  onPressed:
                      _loading ? null : () => Navigator.pop(context, _currentPath),
                  child: const Text('Select this folder'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => _navigate(_currentPath),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    if (_dirs.isEmpty) {
      return const Center(
        child: Text(
          'No subfolders',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }
    return ListView.builder(
      itemCount: _dirs.length,
      itemBuilder: (context, index) {
        final name = _dirs[index];
        final childPath =
            '$_currentPath/$name'.replaceAll('//', '/');
        return ListTile(
          leading: const Icon(Icons.folder),
          title: Text(name),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _navigate(childPath),
        );
      },
    );
  }
}
