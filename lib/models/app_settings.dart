import 'package:uuid/uuid.dart';
import 'nas_source.dart';
import 'water_quality_config.dart';
import 'calendar_config.dart';
import '../utils/constants.dart';

class AppSettings {
  final List<NasSource> nasSources;
  final Duration slideshowInterval;
  final String? openWeatherApiKey;
  final String weatherCity;
  final int weatherRefreshIntervalMinutes;
  final String? iqAirApiKey;
  final String iqAirCity;
  final String iqAirState;
  final String iqAirCountry;
  final WaterQualityConfig? waterQualityConfig;
  final bool showWaterQuality;
  final List<CalendarConfig> calendarConfigs;

  const AppSettings({
    this.nasSources = const [],
    this.slideshowInterval = kDefaultSlideshowInterval,
    this.openWeatherApiKey,
    this.weatherCity = kDefaultCity,
    this.weatherRefreshIntervalMinutes = kDefaultWeatherRefreshIntervalMinutes,
    this.iqAirApiKey,
    this.iqAirCity = kDefaultCity,
    this.iqAirState = kDefaultState,
    this.iqAirCountry = kDefaultCountry,
    this.waterQualityConfig,
    this.showWaterQuality = false,
    this.calendarConfigs = const [],
  });

  AppSettings copyWith({
    List<NasSource>? nasSources,
    Duration? slideshowInterval,
    String? openWeatherApiKey,
    String? weatherCity,
    int? weatherRefreshIntervalMinutes,
    String? iqAirApiKey,
    String? iqAirCity,
    String? iqAirState,
    String? iqAirCountry,
    WaterQualityConfig? waterQualityConfig,
    bool? showWaterQuality,
    List<CalendarConfig>? calendarConfigs,
    bool clearOpenWeatherApiKey = false,
    bool clearIqAirApiKey = false,
    bool clearWaterQualityConfig = false,
  }) =>
      AppSettings(
        nasSources: nasSources ?? this.nasSources,
        slideshowInterval: slideshowInterval ?? this.slideshowInterval,
        openWeatherApiKey: clearOpenWeatherApiKey
            ? null
            : (openWeatherApiKey ?? this.openWeatherApiKey),
        weatherCity: weatherCity ?? this.weatherCity,
        weatherRefreshIntervalMinutes:
            weatherRefreshIntervalMinutes ?? this.weatherRefreshIntervalMinutes,
        iqAirApiKey:
            clearIqAirApiKey ? null : (iqAirApiKey ?? this.iqAirApiKey),
        iqAirCity: iqAirCity ?? this.iqAirCity,
        iqAirState: iqAirState ?? this.iqAirState,
        iqAirCountry: iqAirCountry ?? this.iqAirCountry,
        waterQualityConfig: clearWaterQualityConfig
            ? null
            : (waterQualityConfig ?? this.waterQualityConfig),
        showWaterQuality: showWaterQuality ?? this.showWaterQuality,
        calendarConfigs: calendarConfigs ?? this.calendarConfigs,
      );

  Map<String, dynamic> toJson() => {
        'nasSources': nasSources.map((s) => s.toJson()).toList(),
        'slideshowIntervalSeconds': slideshowInterval.inSeconds,
        'openWeatherApiKey': openWeatherApiKey,
        'weatherCity': weatherCity,
        'weatherRefreshIntervalMinutes': weatherRefreshIntervalMinutes,
        'iqAirApiKey': iqAirApiKey,
        'iqAirCity': iqAirCity,
        'iqAirState': iqAirState,
        'iqAirCountry': iqAirCountry,
        'waterQualityConfig': waterQualityConfig?.toJson(),
        'showWaterQuality': showWaterQuality,
        'calendarConfigs': calendarConfigs.map((c) => c.toJson()).toList(),
      };

  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
        nasSources: (json['nasSources'] as List?)
                ?.map(
                    (s) => NasSource.fromJson(s as Map<String, dynamic>))
                .toList() ??
            [],
        slideshowInterval: Duration(
            seconds: json['slideshowIntervalSeconds'] as int? ??
                kDefaultSlideshowInterval.inSeconds),
        openWeatherApiKey: json['openWeatherApiKey'] as String?,
        weatherCity: json['weatherCity'] as String? ?? kDefaultCity,
        weatherRefreshIntervalMinutes:
            json['weatherRefreshIntervalMinutes'] as int? ??
                kDefaultWeatherRefreshIntervalMinutes,
        iqAirApiKey: json['iqAirApiKey'] as String?,
        iqAirCity: json['iqAirCity'] as String? ?? kDefaultCity,
        iqAirState: json['iqAirState'] as String? ?? kDefaultState,
        iqAirCountry: json['iqAirCountry'] as String? ?? kDefaultCountry,
        waterQualityConfig: json['waterQualityConfig'] != null
            ? WaterQualityConfig.fromJson(
                json['waterQualityConfig'] as Map<String, dynamic>)
            : null,
        showWaterQuality: json['showWaterQuality'] as bool? ?? false,
        calendarConfigs: _migrateCalendarConfigs(json),
      );

  // Handles both new list format ('calendarConfigs') and old single format ('calendarConfig').
  static List<CalendarConfig> _migrateCalendarConfigs(
      Map<String, dynamic> json) {
    // New list format
    if (json['calendarConfigs'] is List) {
      return (json['calendarConfigs'] as List).map((e) {
        try {
          return CalendarConfig.fromJson(e as Map<String, dynamic>);
        } catch (_) {
          return null;
        }
      }).whereType<CalendarConfig>().toList();
    }
    // Legacy single-config format — migrate automatically
    if (json['calendarConfig'] != null) {
      try {
        final old = json['calendarConfig'] as Map<String, dynamic>;
        final icsUrl = old['icsUrl'] as String;
        return [
          CalendarConfig(
            id: const Uuid().v4(),
            name: 'My Calendar',
            icsUrl: icsUrl,
          )
        ];
      } catch (_) {}
    }
    return [];
  }
}
