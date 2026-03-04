import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/nas_source.dart';
import '../../models/calendar_config.dart';
import '../../providers/settings_provider.dart';
import 'widgets/nas_source_editor.dart';
import 'widgets/api_key_field.dart';
import 'widgets/water_quality_field_config.dart';
import 'widgets/calendar_config_editor.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Consumer<SettingsProvider>(
        builder: (context, provider, _) {
          final settings = provider.settings;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // === NAS Sources ===
              _SectionHeader(
                title: 'NAS Sources',
                trailing: IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () => _addNasSource(context, provider),
                ),
              ),
              if (settings.nasSources.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text('No NAS sources configured',
                      style: TextStyle(color: Colors.grey)),
                ),
              ...settings.nasSources.map((source) => _NasSourceTile(
                    source: source,
                    onEdit: () => _editNasSource(context, provider, source),
                    onDelete: () => provider.removeNasSource(source.id),
                  )),
              const Divider(height: 32),

              // === Slideshow ===
              _SectionHeader(title: 'Slideshow'),
              const SizedBox(height: 8),
              _IntervalField(
                value: settings.slideshowInterval,
                onChanged: provider.updateSlideshowInterval,
              ),
              const Divider(height: 32),

              // === Weather ===
              _SectionHeader(title: 'Weather (OpenWeather)'),
              const SizedBox(height: 8),
              ApiKeyField(
                label: 'OpenWeather API Key',
                value: settings.openWeatherApiKey,
                onChanged: (key) =>
                    provider.updateWeatherConfig(key, settings.weatherCity),
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: settings.weatherCity,
                decoration: const InputDecoration(
                  labelText: 'City',
                  border: OutlineInputBorder(),
                ),
                onChanged: (city) => provider.updateWeatherConfig(
                    settings.openWeatherApiKey ?? '', city),
              ),
              const Divider(height: 32),

              // === Air Quality ===
              _SectionHeader(title: 'Air Quality (IQAir)'),
              const SizedBox(height: 8),
              ApiKeyField(
                label: 'IQAir API Key',
                value: settings.iqAirApiKey,
                onChanged: (key) => provider.updateAirQualityConfig(
                    key,
                    settings.iqAirCity,
                    settings.iqAirState,
                    settings.iqAirCountry),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      initialValue: settings.iqAirCity,
                      decoration: const InputDecoration(
                        labelText: 'City',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (city) => provider.updateAirQualityConfig(
                          settings.iqAirApiKey ?? '',
                          city,
                          settings.iqAirState,
                          settings.iqAirCountry),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      initialValue: settings.iqAirState,
                      decoration: const InputDecoration(
                        labelText: 'State',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (state) => provider.updateAirQualityConfig(
                          settings.iqAirApiKey ?? '',
                          settings.iqAirCity,
                          state,
                          settings.iqAirCountry),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      initialValue: settings.iqAirCountry,
                      decoration: const InputDecoration(
                        labelText: 'Country',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (country) => provider.updateAirQualityConfig(
                          settings.iqAirApiKey ?? '',
                          settings.iqAirCity,
                          settings.iqAirState,
                          country),
                    ),
                  ),
                ],
              ),
              const Divider(height: 32),

              // === Water Quality ===
              _SectionHeader(title: 'Water Quality'),
              const SizedBox(height: 8),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Show Water Quality widget'),
                value: settings.showWaterQuality,
                onChanged: (val) =>
                    provider.updateShowWaterQuality(val ?? false),
                controlAffinity: ListTileControlAffinity.leading,
              ),
              WaterQualityFieldConfig(
                config: settings.waterQualityConfig,
                onChanged: (config) =>
                    provider.updateWaterQualityConfig(config),
              ),
              const Divider(height: 32),

              // === Calendars ===
              _SectionHeader(
                title: 'Calendars',
                trailing: IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () => _addCalendar(context, provider),
                ),
              ),
              if (settings.calendarConfigs.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('No calendars configured',
                      style: TextStyle(color: Colors.grey)),
                ),
              ...settings.calendarConfigs.map((cal) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(cal.name),
                    subtitle: Text(
                      cal.icsUrl,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, size: 20),
                          onPressed: () =>
                              _editCalendar(context, provider, cal),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, size: 20),
                          onPressed: () =>
                              provider.removeCalendarConfig(cal.id),
                        ),
                      ],
                    ),
                  )),
              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }

  Future<void> _addNasSource(
      BuildContext context, SettingsProvider provider) async {
    final result = await Navigator.push<NasSource>(
      context,
      MaterialPageRoute(builder: (_) => const NasSourceEditor()),
    );
    if (result != null) {
      await provider.addNasSource(result);
    }
  }

  Future<void> _editNasSource(BuildContext context,
      SettingsProvider provider, NasSource source) async {
    final result = await Navigator.push<NasSource>(
      context,
      MaterialPageRoute(builder: (_) => NasSourceEditor(source: source)),
    );
    if (result != null) {
      await provider.updateNasSource(result);
    }
  }

  Future<void> _addCalendar(
      BuildContext context, SettingsProvider provider) async {
    final result = await Navigator.push<CalendarConfig>(
      context,
      MaterialPageRoute(builder: (_) => const CalendarConfigEditor()),
    );
    if (result != null) {
      await provider.addCalendarConfig(result);
    }
  }

  Future<void> _editCalendar(BuildContext context, SettingsProvider provider,
      CalendarConfig config) async {
    final result = await Navigator.push<CalendarConfig>(
      context,
      MaterialPageRoute(
          builder: (_) => CalendarConfigEditor(initial: config)),
    );
    if (result != null) {
      await provider.updateCalendarConfig(result);
    }
  }
}

class _IntervalField extends StatefulWidget {
  final Duration value;
  final ValueChanged<Duration> onChanged;
  const _IntervalField({required this.value, required this.onChanged});
  @override
  State<_IntervalField> createState() => _IntervalFieldState();
}

class _IntervalFieldState extends State<_IntervalField> {
  static const _presets = [10, 30, 60, 120, 300];
  late final TextEditingController _ctrl;
  late final FocusNode _focusNode;
  int? _dropdownValue;

  @override
  void initState() {
    super.initState();
    final secs = widget.value.inSeconds;
    _dropdownValue = _presets.contains(secs) ? secs : null;
    _ctrl = TextEditingController(text: '$secs');
    _focusNode = FocusNode()..addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(_IntervalField old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) {
      final secs = widget.value.inSeconds;
      setState(() {
        _dropdownValue = _presets.contains(secs) ? secs : null;
        if (_ctrl.text != '$secs') _ctrl.text = '$secs';
      });
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus) _applyText();
  }

  void _applyText() {
    final secs = int.tryParse(_ctrl.text);
    if (secs == null || secs <= 0) {
      _ctrl.text = '${widget.value.inSeconds}'; // revert invalid input
      return;
    }
    setState(() => _dropdownValue = _presets.contains(secs) ? secs : null);
    widget.onChanged(Duration(seconds: secs));
  }

  void _onDropdownChanged(int? value) {
    if (value == null) return;
    setState(() {
      _dropdownValue = value;
      _ctrl.text = '$value';
    });
    widget.onChanged(Duration(seconds: value));
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: DropdownButtonFormField<int?>(
            value: _dropdownValue,
            hint: const Text('Custom'),
            decoration: const InputDecoration(
              labelText: 'Auto-advance interval',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem<int?>(value: 10, child: Text('10 seconds')),
              DropdownMenuItem<int?>(value: 30, child: Text('30 seconds')),
              DropdownMenuItem<int?>(value: 60, child: Text('1 minute')),
              DropdownMenuItem<int?>(value: 120, child: Text('2 minutes')),
              DropdownMenuItem<int?>(value: 300, child: Text('5 minutes')),
            ],
            onChanged: _onDropdownChanged,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TextField(
            controller: _ctrl,
            focusNode: _focusNode,
            decoration: const InputDecoration(
              labelText: 'Seconds',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            onSubmitted: (_) => _applyText(),
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;

  const _SectionHeader({required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const Spacer(),
        ?trailing,
      ],
    );
  }
}

class _NasSourceTile extends StatelessWidget {
  final NasSource source;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _NasSourceTile({
    required this.source,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(
          source.protocol == NasProtocol.smb
              ? Icons.computer
              : Icons.cloud,
        ),
        title: Text(source.name),
        subtitle: Text(
            '${source.protocol.name.toUpperCase()} - ${source.host} (${source.folders.length} folders)'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(icon: const Icon(Icons.edit), onPressed: onEdit),
            IconButton(
                icon: const Icon(Icons.delete_outline), onPressed: onDelete),
          ],
        ),
      ),
    );
  }
}
