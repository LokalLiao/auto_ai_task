import 'package:flutter/material.dart';
import 'package:map_launcher/map_launcher.dart';
import '../models/poi_item.dart';
import '../services/location_service.dart';

class LocationsViewModel extends ChangeNotifier {
  final LocationService _locationService = LocationService.instance;

  bool _loading = false;
  String? _error;
  String _currentAddress = '正在定位...';
  List<PoiItem> _allPois = [];
  String _selectedCategory = '全部';

  bool get loading => _loading;
  String? get error => _error;
  String get currentAddress => _currentAddress;
  String get selectedCategory => _selectedCategory;

  List<PoiItem> get filteredPois {
    if (_selectedCategory == '全部') {
      return _allPois;
    }
    return _allPois.where((item) => item.category == _selectedCategory).toList();
  }

  final List<String> categories = [
    '全部',
    '便利店',
    '电车站',
    '餐馆',
    '医院',
    '学校',
    '银行',
    '警察局',
    '公交站',
  ];

  void setCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  Future<void> loadNearbyPois() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final location = await _locationService.getCurrentLocation();
      _currentAddress = location.displayName;
      // 直接调用 LocationService 的方法
      _allPois = await _locationService.fetchNearbyPois(
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

  Future<void> openNavigation(BuildContext context, PoiItem poi) async {
    try {
      final availableMaps = await MapLauncher.installedMaps;

      if (!context.mounted) return;

      if (availableMaps.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('未检测到安装的地图应用')),
        );
        return;
      }
      showModalBottomSheet(
        context: context,
        builder: (ctx) {
          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    '导航至: ${poi.name}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                const Divider(height: 1),
                ...availableMaps.map(
                      (map) => ListTile(
                    leading: const Icon(Icons.navigation, color: Colors.blue),
                    title: Text(map.mapName),
                    onTap: () {
                      Navigator.pop(ctx);
                      map.showDirections(
                        destination: Coords(poi.latitude, poi.longitude),
                        destinationTitle: poi.name,
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('调起导航失败: $e')),
        );
      }
    }
  }
}