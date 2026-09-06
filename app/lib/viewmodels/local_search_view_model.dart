import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

// 盘符模型
class DriveItem {
  final String label; // 如 "C盘", "D盘"
  final String path; // 如 "C:\"
  bool isSelected;

  DriveItem({
    required this.label,
    required this.path,
    this.isSelected = false,
  });
}

// 搜索结果项模型
class SearchFileItem {
  final String name;
  final String path;
  final double score;
  bool isSelected;

  SearchFileItem({
    required this.name,
    required this.path,
    required this.score,
    this.isSelected = false,
  });

  factory SearchFileItem.fromJson(Map<String, dynamic> json) {
    return SearchFileItem(
      name: json['name'] as String? ?? '',
      path: json['path'] as String? ?? '',
      score: (json['score'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class LocalSearchViewModel extends ChangeNotifier {
  // 根据实际后端地址配置 (例如 'http://127.0.0.1:8000/files')
  static const String _baseUrl = 'http://192.168.1.5:8000/files';

  bool _loading = false;
  bool _searching = false;
  String? _error;

  List<DriveItem> _drives = [];
  List<SearchFileItem> _searchResultList = [];

  // Getters
  bool get loading => _loading;
  bool get searching => _searching;
  String? get error => _error;
  List<DriveItem> get drives => _drives;
  List<SearchFileItem> get searchResultList => _searchResultList;

  /// 1. 获取当前主机设备存在的盘符: GET /files/drives
  Future<void> fetchDrives() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final response = await http.get(Uri.parse('$_baseUrl/drives'));
      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(utf8.decode(response.bodyBytes));
        final List<dynamic> driveList = body['data']['drives'] ?? [];
        _drives = driveList.map((driveStr) {
          final path = driveStr.toString();
          // 将 "C:\" 格式化为方便展示的 "C盘" 标签
          final letter = path.replaceAll(RegExp(r'[:\\/]'), '');
          return DriveItem(
            label: letter.isNotEmpty ? '$letter盘' : path,
            path: path,
            isSelected: false,
          );
        }).toList();
      } else {
        _error = '获取盘符失败: 状态码 ${response.statusCode}';
      }
    } catch (e) {
      _error = '网络请求异常: $e';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// 切换盘符选中状态
  void toggleDriveSelection(int index, bool? value) {
    if (index >= 0 && index < _drives.length) {
      _drives[index].isSelected = value ?? false;
      notifyListeners();
    }
  }

  /// 2. 搜索指定名称文件: POST /files/search
  Future<void> searchFiles(String keyword) async {
    final cleanKeyword = keyword.trim();
    if (cleanKeyword.isEmpty) return;
    // 提取选中的盘符，若未选中任何盘符则传 null 让后端全盘搜索
    final selectedDrives = _drives
        .where((item) => item.isSelected)
        .map((item) => item.path)
        .toList();
    _searching = true;
    _error = null;
    notifyListeners();
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/search'),
        headers: {'Content-Type': 'application/json; charset=utf-8'},
        body: jsonEncode({
          'query': cleanKeyword,
          'drives': selectedDrives.isEmpty ? null : selectedDrives,
        }),
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(utf8.decode(response.bodyBytes));
        final List<dynamic> results = body['data']['results'] ?? [];

        _searchResultList = results
            .map((item) => SearchFileItem.fromJson(item as Map<String, dynamic>))
            .toList();
      } else {
        _error = '搜索失败: 状态码 ${response.statusCode}';
      }
    } catch (e) {
      _error = '搜索异常: $e';
    } finally {
      _searching = false;
      notifyListeners();
    }
  }

  /// 切换搜索结果项勾选状态
  void toggleFileSelection(int index, bool? value) {
    if (index >= 0 && index < _searchResultList.length) {
      _searchResultList[index].isSelected = value ?? false;
      notifyListeners();
    }
  }

  /// 3. 将对应路径文件放入回收站: POST /files/trash
  Future<bool> moveToTrash(SearchFileItem item) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/trash'),
        headers: {'Content-Type': 'application/json; charset=utf-8'},
        body: jsonEncode({
          'file_path': item.path,
        }),
      );
      if (response.statusCode == 200) {
        // 从当前列表中移除已放入回收站的文件项
        _searchResultList.remove(item);
        notifyListeners();
        return true;
      } else {
        final Map<String, dynamic> body = jsonDecode(utf8.decode(response.bodyBytes));
        _error = body['detail'] ?? '移入回收站失败';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = '回收站操作异常: $e';
      notifyListeners();
      return false;
    }
  }

}