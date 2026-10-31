import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherData {
  final double currentTemp;
  final double apparentTemp;
  final int humidity;
  final double windSpeed;
  final String condition;
  final String icon;
  final List<DayForecast> daily;

  WeatherData({
    required this.currentTemp,
    required this.apparentTemp,
    required this.humidity,
    required this.windSpeed,
    required this.condition,
    required this.icon,
    required this.daily,
  });
}

class DayForecast {
  final String dayName;
  final double maxTemp;
  final double minTemp;
  final String icon;

  DayForecast({
    required this.dayName,
    required this.maxTemp,
    required this.minTemp,
    required this.icon,
  });
}

class WeatherService {
  static const String _defaultUrl =
      'https://api.open-meteo.com/v1/forecast?latitude=39.9334&longitude=32.8597&current=temperature_2m,relative_humidity_2m,apparent_temperature,weather_code,wind_speed_10m&daily=weather_code,temperature_2m_max,temperature_2m_min&timezone=auto';

  Future<WeatherData> fetchWeather() async {
    try {
      final res = await http.get(Uri.parse(_defaultUrl)).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final current = data['current'];
        final daily = data['daily'];

        List<DayForecast> forecastList = [];
        final days = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
        final times = daily['time'] as List;

        for (int i = 0; i < times.length && i < 5; i++) {
          final dt = DateTime.parse(times[i]);
          forecastList.add(DayForecast(
            dayName: days[dt.weekday - 1],
            maxTemp: (daily['temperature_2m_max'][i] as num).toDouble(),
            minTemp: (daily['temperature_2m_min'][i] as num).toDouble(),
            icon: _resolveWeatherIcon(daily['weather_code'][i]),
          ));
        }

        return WeatherData(
          currentTemp: (current['temperature_2m'] as num).toDouble(),
          apparentTemp: (current['apparent_temperature'] as num).toDouble(),
          humidity: (current['relative_humidity_2m'] as num).toInt(),
          windSpeed: (current['wind_speed_10m'] as num).toDouble(),
          condition: _resolveWeatherText(current['weather_code']),
          icon: _resolveWeatherIcon(current['weather_code']),
          daily: forecastList,
        );
      }
    } catch (_) {
      // Fallback
    }

    return WeatherData(
      currentTemp: 14.2,
      apparentTemp: 13.0,
      humidity: 55,
      windSpeed: 12.0,
      condition: 'Parçalı Bulutlu',
      icon: '⛅',
      daily: [
        DayForecast(dayName: 'Bugün', maxTemp: 16, minTemp: 7, icon: '⛅'),
        DayForecast(dayName: 'Yarın', maxTemp: 15, minTemp: 6, icon: '🌧️'),
        DayForecast(dayName: 'Sal', maxTemp: 14, minTemp: 5, icon: '⛅'),
        DayForecast(dayName: 'Çar', maxTemp: 17, minTemp: 8, icon: '☀️'),
        DayForecast(dayName: 'Per', maxTemp: 18, minTemp: 9, icon: '☀️'),
      ],
    );
  }

  String _resolveWeatherIcon(int code) {
    if (code == 0) return '☀️';
    if (code <= 3) return '⛅';
    if (code <= 48) return '🌫️';
    if (code <= 67) return '🌧️';
    if (code <= 77) return '❄️';
    return '⛈️';
  }

  String _resolveWeatherText(int code) {
    if (code == 0) return 'Açık & Güneşli';
    if (code <= 3) return 'Parçalı Bulutlu';
    if (code <= 48) return 'Sisli';
    if (code <= 67) return 'Yağmurlu';
    if (code <= 77) return 'Karlı';
    return 'Fırtınalı';
  }
}
