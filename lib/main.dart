import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:wakelock_plus/wakelock_plus.dart';

import 'app.dart';
import 'providers/settings_provider.dart';
import 'providers/slideshow_provider.dart';
import 'providers/weather_provider.dart';
import 'providers/air_quality_provider.dart';
import 'providers/water_quality_provider.dart';
import 'providers/calendar_provider.dart';
import 'providers/volume_provider.dart';
import 'services/settings_service.dart';
import 'services/media_cache_service.dart';
import 'services/nas/nas_service_factory.dart';
import 'services/weather_service.dart';
import 'services/air_quality_service.dart';
import 'services/water_quality_service.dart';
import 'services/calendar_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize timezone data
  tz.initializeTimeZones();

  // Keep screen on
  WakelockPlus.enable();

  // Initialize services
  final settingsService = SettingsService();
  await settingsService.init();

  final mediaCacheService = MediaCacheService();
  await mediaCacheService.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => SettingsProvider(settingsService)..loadSettings(),
        ),
        ChangeNotifierProxyProvider<SettingsProvider, SlideshowProvider>(
          create: (_) =>
              SlideshowProvider(mediaCacheService, NasServiceFactory()),
          update: (_, settings, slideshow) =>
              slideshow!..onSettingsChanged(settings.settings),
        ),
        ChangeNotifierProxyProvider<SettingsProvider, WeatherProvider>(
          create: (_) => WeatherProvider(WeatherService()),
          update: (_, settings, weather) =>
              weather!..onSettingsChanged(settings.settings),
        ),
        ChangeNotifierProxyProvider<SettingsProvider, AirQualityProvider>(
          create: (_) => AirQualityProvider(AirQualityService()),
          update: (_, settings, aq) =>
              aq!..onSettingsChanged(settings.settings),
        ),
        ChangeNotifierProxyProvider<SettingsProvider, WaterQualityProvider>(
          create: (_) => WaterQualityProvider(WaterQualityService()),
          update: (_, settings, wq) =>
              wq!..onSettingsChanged(settings.settings),
        ),
        ChangeNotifierProxyProvider<SettingsProvider, CalendarProvider>(
          create: (_) => CalendarProvider(CalendarService()),
          update: (_, settings, cal) =>
              cal!..onSettingsChanged(settings.settings),
        ),
        ChangeNotifierProvider(
          create: (_) => VolumeProvider()..init(),
        ),
      ],
      child: const FotoPhrame(),
    ),
  );
}
