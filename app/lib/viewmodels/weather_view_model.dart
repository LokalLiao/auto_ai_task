import 'package:flutter/foundation.dart';
import '../services/location_service.dart';
import '../services/weather_service.dart';

class WeatherViewModel extends ChangeNotifier {
  final WeatherService _weatherService = WeatherService.instance;
  final LocationService _locationService = LocationService.instance;

  bool _loading = false;
  String? _error;
  String _cityName = '';
  List<DailyWeather> _forecastList = [];

  bool get loading => _loading;
  String? get error => _error;
  String get cityName => _cityName;
  List<DailyWeather> get forecastList => _forecastList;

  Future<void> load7DaysWeather() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      // 1. 获取定位
      final location = await _locationService.getCurrentLocation();
      _cityName = location.displayName;
      // 2. 拉取 7 天天气
      _forecastList = await _weatherService.fetch7DaysForecast(
        location.latitude,
        location.longitude,
      );
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}