import 'package:flutter/material.dart';
import '../viewmodels/main_view_model.dart';
import '../../widgets/main_page_widgets.dart';
import '../utils/app_navigator.dart';

class MainPage extends StatefulWidget {

  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {

  //初始化ViewModel实例
  late final MainViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = MainViewModel();
    //页面进入直接触发数据加载
    _viewModel.loadInitData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Personal AI Task'),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                _onItemTap(settingsItem.id);
              },
            ),
          ]
      ),
      // 3. 监听 ViewModel 变化，布局结构 100% 保持原样
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) {
          final state = _viewModel.state;
          print(
            '[MainPage] rebuild '
                'loading=${state.loading}, '
                'location=${state.location}, '
                'error=${state.error}',
          );
          // 加载中
          if (state.loading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          // 加载失败
          if (state.error != null) {
            return Center(
              child: Text(state.error!),
            );
          }
          // 正常布局（完全不变）
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: MainTopCard(
                  state: state,
                  onItemTap: _onItemTap,
                ),
              ),
              const Divider(height: 1),
              // 底部菜单，滚动
              Expanded(
                child: MainBottomMenu(
                  onItemTap: _onItemTap,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  //所有页面点击事件统一从这里进入
  void _onItemTap(String id) {
    AppNavigator.navigate(context, id);
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }
}