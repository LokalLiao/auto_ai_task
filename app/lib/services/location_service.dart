import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import '../models/app_location.dart';
import '../models/poi_item.dart';

class LocationService {
  // ============================================================
  // 单例
  // ============================================================
  LocationService._internal();

  static final LocationService _instance = LocationService._internal();

  factory LocationService() => _instance;

  static LocationService get instance => _instance;

  // ============================================================
  // 1. 获取当前定位与地址信息
  // ============================================================
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
    // 4. 通过通用 HTTP 逆地理编码（稳定，不依赖系统 Google Play 框架）
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
          city = addressObj['province'] ??
              addressObj['state'] ??
              addressObj['region'];
          // 市区町村（如 市川市 / 船橋市）
          district = addressObj['city'] ??
              addressObj['ward'] ??
              addressObj['town'] ??
              addressObj['suburb'];
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

  // ============================================================
  // 2. 检索以当前经纬度为圆心、3km 半径内的 POI 设施
  // ============================================================
  Future<List<PoiItem>> fetchNearbyPois(double latitude, double longitude) async {
    print('[LocationService] 检索 3km 内周边设施: lat=$latitude, lng=$longitude');
    // 标准 Overpass QL 查询脚本
    final query = '''
[out:json][timeout:25];
(
  node["amenity"~"school|bank|restaurant|police|hospital"](around:3000,$latitude,$longitude);
  node["shop"="convenience"](around:3000,$latitude,$longitude);
  node["railway"="station"](around:3000,$latitude,$longitude);
  node["highway"="bus_stop"](around:3000,$latitude,$longitude);
);
out body;
''';
    // 备用镜像节点列表（优先请求官方主节点，失败自动轮询）
    final endpoints = [
      'https://overpass-api.de/api/interpreter',
      'https://maps.mail.ru/osm/tools/overpass/api/interpreter',
      'https://overpass.kumi.systems/api/interpreter',
    ];
    http.Response? response;
    Exception? lastException;
    for (final endpoint in endpoints) {
      try {
        response = await http.post(
          Uri.parse(endpoint),
          headers: {
            'User-Agent': 'PersonalAiTaskApp/1.0 (contact: app_dev@example.com)',
            'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
            'Accept': 'application/json',
          },
          // 采用标准 data=urlencoded 格式传参，防止 406 拦截
          body: 'data=${Uri.encodeComponent(query)}',
        ).timeout(const Duration(seconds: 15));
        if (response.statusCode == 200) {
          break; // 请求成功，跳出重试
        } else {
          print('[LocationService] 节点 $endpoint 返回错误: ${response.statusCode}');
        }
      } catch (e) {
        lastException = Exception(e.toString());
        print('[LocationService] 节点 $endpoint 连接异常: $e');
      }
    }
    if (response == null || response.statusCode != 200) {
      throw Exception(
        '周边数据请求失败，状态码: ${response?.statusCode ?? "无响应"}，${lastException ?? ""}',
      );
    }
    final data = json.decode(utf8.decode(response.bodyBytes));
    final elements = data['elements'] as List<dynamic>? ?? [];
    final List<PoiItem> poiList = [];
    for (final elem in elements) {
      final tags = elem['tags'] as Map<String, dynamic>?;
      if (tags == null) continue;
      // 提取地点名称（优先中文/日文/默认名称）
      final String? name = tags['name:zh'] ?? tags['name:ja'] ?? tags['name'];
      if (name == null || name.trim().isEmpty) {
        continue; // 过滤无名节点
      }
      final double poiLat = (elem['lat'] as num).toDouble();
      final double poiLng = (elem['lon'] as num).toDouble();
      // 计算与中心点的距离
      final double distance = Geolocator.distanceBetween(
        latitude,
        longitude,
        poiLat,
        poiLng,
      );
      final (category, icon) = _resolveCategory(tags);
      poiList.add(
        PoiItem(
          id: elem['id'].toString(),
          name: name,
          category: category,
          icon: icon,
          latitude: poiLat,
          longitude: poiLng,
          distanceInMeters: distance,
        ),
      );
    }
    // 按距离由近到远排序
    poiList.sort((a, b) => a.distanceInMeters.compareTo(b.distanceInMeters));
    print('[LocationService] 成功检索到 ${poiList.length} 个周边地点');
    return poiList;
  }

  // 分类与图标匹配助手函数
  (String, IconData) _resolveCategory(Map<String, dynamic> tags) {
    if (tags['shop'] == 'convenience')
      return ('便利店', Icons.local_convenience_store);
    if (tags['railway'] == 'station') return ('电车站', Icons.train);
    if (tags['highway'] == 'bus_stop') return ('公交站', Icons.directions_bus);
    final amenity = tags['amenity'];
    switch (amenity) {
      case 'school':
        return ('学校', Icons.school);
      case 'bank':
        return ('银行', Icons.account_balance);
      case 'restaurant':
        return ('餐馆', Icons.restaurant);
      case 'police':
        return ('警察局', Icons.local_police);
      case 'hospital':
        return ('医院', Icons.local_hospital);
      default:
        return ('其他设施', Icons.place);
    }
  }
}
