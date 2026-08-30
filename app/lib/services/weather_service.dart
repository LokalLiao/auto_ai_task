import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

class DailyWeather {
  final String date;
  final String condition;
  final IconData icon;
  final double maxTemp;
  final double minTemp;
  final int precipitationProbability; // 降水概率 %
  final double maxWindSpeed;           // 最大风速 km/h
  final double maxUvIndex;             // UV 指数
  final String sunrise;                // 日出 (HH:mm)
  final String sunset;                 // 日落 (HH:mm)

  DailyWeather({
    required this.date,
    required this.condition,
    required this.icon,
    required this.maxTemp,
    required this.minTemp,
    required this.precipitationProbability,
    required this.maxWindSpeed,
    required this.maxUvIndex,
    required this.sunrise,
    required this.sunset,
  });

  String get tempRange => '$minTemp°C ~ $maxTemp°C';
}

class WeatherService {

  WeatherService._internal();
  static final WeatherService _instance = WeatherService._internal();
  factory WeatherService() => _instance;
  static WeatherService get instance => _instance;

  //根据经纬度获取当前天气信息
  Future<String> fetchCurrentWeather(double latitude, double longitude) async {
    print('[WeatherService] 获取天气: lat=$latitude, lng=$longitude');
    final url = Uri.parse(
      'https://api.open-meteo.com/v1/forecast?latitude=$latitude&longitude=$longitude&current=temperature_2m,relative_humidity_2m,weather_code&timezone=auto',
    );
    final response = await http.get(url).timeout(const Duration(seconds: 8));
    if (response.statusCode != 200) {
      throw Exception('天气服务请求失败，状态码: ${response.statusCode}');
    }
    final data = json.decode(response.body);
    final current = data['current'] as Map<String, dynamic>;
    final double temp = (current['temperature_2m'] as num).toDouble();
    final int humidity = (current['relative_humidity_2m'] as num).toInt();
    final int code = (current['weather_code'] as num).toInt();
    final String condition = _parseWmoCode(code).$1;
    //格式化输出：如 "晴 22.5°C 湿度 55%"
    return '$condition $temp°C (湿度 $humidity%)';
  }

  //获取未来 7 天天气预报列表
  Future<List<DailyWeather>> fetch7DaysForecast(double latitude, double longitude) async {
    print('[WeatherService] 获取详细7天天气: lat=$latitude, lng=$longitude');
    final url = Uri.parse(
      'https://api.open-meteo.com/v1/forecast?latitude=$latitude&longitude=$longitude'
          '&daily=weather_code,temperature_2m_max,temperature_2m_min,precipitation_probability_max,wind_speed_10m_max,uv_index_max,sunrise,sunset'
          '&timezone=auto',
    );
    final response = await http.get(url).timeout(const Duration(seconds: 8));
    if (response.statusCode != 200) {
      throw Exception('7天天气请求失败: ${response.statusCode}');
    }
    final data = json.decode(response.body);
    final daily = data['daily'] as Map<String, dynamic>;
    final List<dynamic> dates = daily['time'] ?? [];
    final List<dynamic> codes = daily['weather_code'] ?? [];
    final List<dynamic> maxTemps = daily['temperature_2m_max'] ?? [];
    final List<dynamic> minTemps = daily['temperature_2m_min'] ?? [];
    final List<dynamic> rainProb = daily['precipitation_probability_max'] ?? [];
    final List<dynamic> windSpeeds = daily['wind_speed_10m_max'] ?? [];
    final List<dynamic> uvIndexes = daily['uv_index_max'] ?? [];
    final List<dynamic> sunrises = daily['sunrise'] ?? [];
    final List<dynamic> sunsets = daily['sunset'] ?? [];
    final List<DailyWeather> list = [];
    for (int i = 0; i < dates.length; i++) {
      final (condition, icon) = _parseWmoCode((codes[i] as num).toInt());
      list.add(
        DailyWeather(
          date: dates[i].toString(),
          condition: condition,
          icon: icon,
          maxTemp: (maxTemps[i] as num).toDouble(),
          minTemp: (minTemps[i] as num).toDouble(),
          precipitationProbability: (rainProb[i] as num?)?.toInt() ?? 0,
          maxWindSpeed: (windSpeeds[i] as num?)?.toDouble() ?? 0.0,
          maxUvIndex: (uvIndexes[i] as num?)?.toDouble() ?? 0.0,
          sunrise: _formatTime(sunrises[i].toString()),
          sunset: _formatTime(sunsets[i].toString()),
        ),
      );
    }
    return list;
  }

  String _formatTime(String fullTime) {
    if (fullTime.contains('T')) {
      return fullTime.split('T').last;
    }
    return fullTime;
  }

  // WMO 国际编码转 (中文描述, 对应图标)
  (String, IconData) _parseWmoCode(int code) {
    if (code == 0) return ('晴朗', Icons.wb_sunny);
    if (code == 1) return ('大部分晴', Icons.wb_sunny_outlined);
    if (code == 2) return ('局部多云', Icons.cloud_queue);
    if (code == 3) return ('阴天', Icons.cloud);
    if (code >= 45 && code <= 48) return ('有雾', Icons.foggy);
    if (code >= 51 && code <= 55) return ('毛毛雨', Icons.grain);
    if (code >= 61 && code <= 65) return ('降雨', Icons.water_drop);
    if (code >= 71 && code <= 77) return ('降雪', Icons.ac_unit);
    if (code >= 80 && code <= 82) return ('阵雨', Icons.umbrella);
    if (code >= 95 && code <= 99) return ('雷阵雨', Icons.flash_on);
    return ('多云', Icons.cloud);
  }

}