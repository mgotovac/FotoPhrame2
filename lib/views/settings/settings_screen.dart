import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/nas_source.dart';
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
              DropdownButtonFormField<int>(
                initialValue: settings.slideshowInterval.inSeconds,
                decoration: const InputDecoration(
                  labelText: 'Auto-advance interval',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 10, child: Text('10 seconds')),
                  DropdownMenuItem(value: 30, child: Text('30 seconds')),
                  DropdownMenuItem(value: 60, child: Text('1 minute')),
                  DropdownMenuItem(value: 120, child: Text('2 minutes')),
                  DropdownMenuItem(value: 300, child: Text('5 minutes')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    provider
                        .updateSlideshowInterval(Duration(seconds: value));
                  }
                },
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
              WaterQualityFieldConfig(
                config: settings.waterQualityConfig,
                onChanged: (config) =>
                    provider.updateWaterQualityConfig(config),
              ),
              const Divider(height: 32),

              // === Calendar ===
              _SectionHeader(title: 'Google Calendar'),
              const SizedBox(height: 8),
              CalendarConfigEditor(
                config: settings.calendarConfig,
                onChanged: (config) =>
                    provider.updateCalendarConfig(config),
              ),
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
