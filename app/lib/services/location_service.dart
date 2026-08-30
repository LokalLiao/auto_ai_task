import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import '../models/app_location.dart';

class LocationService {
  LocationService._internal();
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  static LocationService get instance => _instance;

  Future<AppLocation> getCurrentLocation() async {
    print('[LocationService] 开始获取原生定位');
    // 1. 检查手机定位总开关
    final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('系统定位服务未开启，请在手机设置中开启 GPS');
    }
    // 2. 检查并请求定位权限
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('用户未授予定位权限');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      throw Exception('定位权限被永久拒绝，请在系统设置中手动开启');
    }
    // 3. 原生经纬度
    final Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
      timeLimit: const Duration(seconds: 15),
    );
    print('[LocationService] 经纬度已获取: lat=${position.latitude}, lng=${position.longitude}');
    // 4. 通过通用 HTTP 逆地理编码（100% 稳定，不依赖 Google Play 服务）
    String? country;
    String? city;
    String? district;
    String? address;
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=${position.latitude}&lon=${position.longitude}&accept-language=ja',
      );
      final response = await http.get(
        url,
        headers: {'User-Agent': 'FlutterApp/1.0'}, // OSM 规范必须带 User-Agent
      ).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        final addressObj = data['address'] as Map<String, dynamic>?;
        if (addressObj != null) {
          country = addressObj['country'];
          // 日本都道府县（如 千葉県 / 東京都）
          city = addressObj['province'] ?? addressObj['state'] ?? addressObj['region'];
          // 市区町村（如 市川市 / 船橋市）
          district = addressObj['city'] ?? addressObj['ward'] ?? addressObj['town'] ?? addressObj['suburb'];
          address = data['display_name'];
          print('[LocationService] HTTP 逆地理编码成功: $city $district ($address)');
        }
      }
    } catch (e) {
      print('[LocationService] 逆地理编码请求异常: $e');
    }
    return AppLocation(
      latitude: position.latitude,
      longitude: position.longitude,
      country: country,
      city: city,
      district: district,
      address: address,
    );
  }
}