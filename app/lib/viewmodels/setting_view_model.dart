import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingViewModel extends ChangeNotifier {
  static const String _keyIp = 'server_ip';
  static const String _keyPort = 'server_port';

  String _ip = '';
  String _port = '';
  bool _loading = false;
  String? _errorMessage;

  String get ip => _ip;
  String get port => _port;
  bool get loading => _loading;
  String? get errorMessage => _errorMessage;

  //初始化加载本地保存的 IP 和 Port
  Future<void> loadSettings() async {
    _loading = true;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      _ip = prefs.getString(_keyIp) ?? '';
      _port = prefs.getString(_keyPort) ?? '';
    } catch (e) {
      _errorMessage = '加载设置失败: $e';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  //保存 IP 和 Port 到本地
  Future<bool> saveSettings(String newIp, String newPort) async {
    final cleanIp = newIp.trim();
    final cleanPort = newPort.trim();
    if (cleanIp.isEmpty) {
      _errorMessage = 'IP 地址不能为空';
      notifyListeners();
      return false;
    }
    if (cleanPort.isEmpty) {
      _errorMessage = '端口号不能为空';
      notifyListeners();
      return false;
    }
    _loading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyIp, cleanIp);
      await prefs.setString(_keyPort, cleanPort);
      _ip = cleanIp;
      _port = cleanPort;
      return true;
    } catch (e) {
      _errorMessage = '保存失败: $e';
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}