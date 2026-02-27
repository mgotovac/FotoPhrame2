import 'package:flutter/material.dart';
import '../../../models/water_quality_config.dart';
import '../../../services/water_quality_service.dart';

class WaterQualityFieldConfig extends StatefulWidget {
  final WaterQualityConfig? config;
  final ValueChanged<WaterQualityConfig?> onChanged;

  const WaterQualityFieldConfig({
    super.key,
    this.config,
    required this.onChanged,
  });

  @override
  State<WaterQualityFieldConfig> createState() =>
      _WaterQualityFieldConfigState();
}

class _WaterQualityFieldConfigState extends State<WaterQualityFieldConfig> {
  late TextEditingController _urlController;
  List<String> _availableFields = [];
  final Map<String, bool> _selectedFields = {};
  final Map<String, TextEditingController> _labelControllers = {};
  final Map<String, TextEditingController> _unitControllers = {};
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(text: widget.config?.url ?? '');
    if (widget.config != null) {
      for (final field in widget.config!.selectedFields) {
        _selectedFields[field.jsonPath] = true;
        _labelControllers[field.jsonPath] =
            TextEditingController(text: field.label);
        _unitControllers[field.jsonPath] =
            TextEditingController(text: field.unit ?? '');
      }
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    for (final c in _labelControllers.values) {
      c.dispose();
    }
    for (final c in _unitControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _fetchSample() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final service = WaterQualityService();
      final json = await service.fetchRawJson(url);
      final paths = WaterQualityService.flattenJsonPaths(json);
      setState(() {
        _availableFields = paths;
        for (final path in paths) {
          _selectedFields.putIfAbsent(path, () => false);
          _labelControllers.putIfAbsent(
              path, () => TextEditingController(text: path.split('.').last));
          _unitControllers.putIfAbsent(
              path, () => TextEditingController());
        }
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _saveConfig() {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      widget.onChanged(null);
      return;
    }

    final selectedFields = <WaterQualityField>[];
    for (final path in _selectedFields.keys) {
      if (_selectedFields[path] == true) {
        selectedFields.add(WaterQualityField(
          jsonPath: path,
          label: _labelControllers[path]?.text ?? path,
          unit: _unitControllers[path]?.text.isNotEmpty == true
              ? _unitControllers[path]!.text
              : null,
        ));
      }
    }

    widget.onChanged(WaterQualityConfig(
      url: url,
      selectedFields: selectedFields,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _urlController,
                decoration: const InputDecoration(
                  labelText: 'REST Endpoint URL',
                  hintText: 'https://api.example.com/water-quality',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _isLoading ? null : _fetchSample,
              child: _isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Fetch'),
            ),
          ],
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(_error!, style: const TextStyle(color: Colors.red)),
          ),
        if (_availableFields.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Text('Select fields to display:',
              style: TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          ..._availableFields.map((path) {
            return CheckboxListTile(
              value: _selectedFields[path] ?? false,
              onChanged: (value) {
                setState(() => _selectedFields[path] = value ?? false);
                _saveConfig();
              },
              title: Text(path, style: const TextStyle(fontSize: 14)),
              subtitle: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _labelControllers[path],
                      decoration: const InputDecoration(
                        labelText: 'Label',
                        isDense: true,
                      ),
                      onChanged: (_) => _saveConfig(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 80,
                    child: TextField(
                      controller: _unitControllers[path],
                      decoration: const InputDecoration(
                        labelText: 'Unit',
                        isDense: true,
                      ),
                      onChanged: (_) => _saveConfig(),
                    ),
                  ),
                ],
              ),
              controlAffinity: ListTileControlAffinity.leading,
              dense: true,
            );
          }),
        ],
      ],
    );
  }
}
