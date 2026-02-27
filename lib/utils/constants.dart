const Set<String> kSupportedImageExtensions = {
  'jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp', 'heic', 'heif',
};

const Set<String> kSupportedVideoExtensions = {
  'mp4', 'mov', 'avi', 'mkv', 'webm', 'm4v',
};

const String kOpenWeatherGeocodingUrl =
    'https://api.openweathermap.org/geo/1.0/direct';

const String kOpenWeatherOneCallUrl =
    'https://api.openweathermap.org/data/2.5/forecast';

const int kDefaultWeatherRefreshIntervalMinutes = 30;

const String kIqAirBaseUrl =
    'https://api.airvisual.com/v2/city';

const String kGoogleCalendarBaseUrl =
    'https://www.googleapis.com/calendar/v3/calendars';

const Duration kDefaultSlideshowInterval = Duration(seconds: 30);

const Duration kWeatherRefreshInterval = Duration(minutes: kDefaultWeatherRefreshIntervalMinutes);
const Duration kAirQualityRefreshInterval = Duration(minutes: 30);
const Duration kWaterQualityRefreshInterval = Duration(hours: 12);
const Duration kCalendarRefreshInterval = Duration(minutes: 5);
const Duration kSlideshowRescanInterval = Duration(hours: 1);

const int kMaxCacheSizeMb = 500;
const int kPrefetchCount = 3;

const String kDefaultCity = 'Zagreb';
const String kDefaultCountry = 'Croatia';
const String kDefaultState = 'Zagreb';
const String kDefaultTimezone = 'Europe/Zagreb';
