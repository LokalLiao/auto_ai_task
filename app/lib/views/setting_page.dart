import 'package:flutter/material.dart';
import '../utils/app_navigator.dart';
import '../viewmodels/setting_view_model.dart';

class SettingPage extends StatefulWidget {
  const SettingPage({super.key});

  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  late final SettingViewModel _viewModel;
  final TextEditingController _ipController = TextEditingController();
  final TextEditingController _portController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _viewModel = SettingViewModel();
    _initData();
  }

  Future<void> _initData() async {
    await _viewModel.loadSettings();
    // 回显本地存储的数据到输入框
    _ipController.text = _viewModel.ip;
    _portController.text = _viewModel.port;
  }

  @override
  void dispose() {
    _viewModel.dispose();
    _ipController.dispose();
    _portController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Setting'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            AppNavigator.back(context);
          },
        ),
      ),
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) {
          if (_viewModel.loading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          TextField(
                            controller: _ipController,
                            decoration: const InputDecoration(
                              labelText: 'IP 地址',
                              hintText: '例如: 192.168.1.100',
                              prefixIcon: Icon(Icons.computer),
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.url,
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _portController,
                            decoration: const InputDecoration(
                              labelText: '端口 (Port)',
                              hintText: '例如: 8080',
                              prefixIcon: Icon(Icons.numbers),
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                          if (_viewModel.errorMessage != null) ...[
                            const SizedBox(height: 12),
                            Text(
                              _viewModel.errorMessage!,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _onSavePressed,
                      child: const Text(
                        '保存',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _onSavePressed() async {
    // 收起键盘
    FocusScope.of(context).unfocus();
    final success = await _viewModel.saveSettings(
      _ipController.text,
      _portController.text,
    );
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('设置保存成功'),
          duration: Duration(seconds: 1),
        ),
      );
      // 调用路由返回
      AppNavigator.back(context);
    }
  }
}