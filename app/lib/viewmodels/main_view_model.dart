import 'package:flutter/foundation.dart';
import '../models/app_location.dart';
import '../services/location_service.dart';
import '../services/weather_service.dart';

class MainPageState {
  bool loading;
  AppLocation? location;
  String? weather;
  String? error;

  MainPageState({
    this.loading = false,
    this.location,
    this.weather,
    this.error,
  });
}

class MainViewModel extends ChangeNotifier {

  final LocationService _locationService = LocationService.instance;
  final WeatherService _weatherService = WeatherService.instance;
  final MainPageState state = MainPageState();

  //加载定位信息，天气预报等信息
  Future<void> loadInitData() async {
    print('[MainViewModel] 开始加载数据');
    state.loading = true;
    state.error = null;
    notifyListeners(); // 刷新 UI -> 显示转圈
    try {
      //1.获取定位
      final location = await _locationService.getCurrentLocation();
      print('[MainViewModel] 定位获取成功: $location');
      state.location = location;
      //2.根据经纬度获取实时天气
      final weather = await _weatherService.fetchCurrentWeather(
        location.latitude,
        location.longitude,
      );
      state.weather = weather;
      print('[MainViewModel] 天气拉取成功: $weather');
    } catch(e) {
      print('[MainViewModel] 加载出错: $e');
      state.error = e.toString();
    } finally {
      state.loading = false;
      notifyListeners(); // 刷新 UI -> 停下转圈展示内容或错误
      print('[MainViewModel] 数据加载结束');
    }
  }

}