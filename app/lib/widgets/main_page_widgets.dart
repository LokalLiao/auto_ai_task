import 'package:flutter/material.dart';
import '../viewmodels/main_view_model.dart';

//对应每个item实体类
class MainMenuItem {
  final String id;
  final String title;
  final IconData icon;

  const MainMenuItem({
    required this.id,
    required this.title,
    required this.icon,
  });
}

//item数据
const locationItem = MainMenuItem(
  id: 'location',
  title: '定位',
  icon: Icons.location_on,
);

const weatherItem = MainMenuItem(
  id: 'weather',
  title: '天气',
  icon: Icons.cloud,
);

const todoItem = MainMenuItem(
  id: 'todo',
  title: '待办任务',
  icon: Icons.checklist,
);

const aiItem = MainMenuItem(
  id: 'ai',
  title: 'AI 助手',
  icon: Icons.smart_toy,
);

const settingsItem = MainMenuItem(
  id: 'settings',
  title: '设置',
  icon: Icons.settings,
);

//共用的item控件
Widget _buildMenuItem({
  required MainMenuItem item,
  required VoidCallback? onTap,
  String? title,
}) {
  return ListTile(
    leading: Icon(item.icon),
    title: Text(
      title ?? item.title,
    ),
    trailing: const Icon(
      Icons.chevron_right,
    ),
    onTap: onTap,
  );
}

// 首页顶部状态显示栏
class MainTopCard extends StatelessWidget {
  final MainPageState state;
  final void Function(String id) onItemTap;

  const MainTopCard({
    super.key,
    required this.state,
    required this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        child: Column(
          children: [
            _buildMenuItem(
              item: locationItem,
              title: _getCityName(),
              onTap: () {
                onItemTap(locationItem.id);
              },
            ),
            const Divider(height: 1),
            _buildMenuItem(
              item: weatherItem,
              title: state.weather ?? '天气暂未获取',
              onTap: () {
                onItemTap(weatherItem.id);
              },
            ),
            const Divider(height: 1),
            _buildMenuItem(
              item: todoItem,
              title: '当前待办：无',
              onTap: () {
                onItemTap(todoItem.id);
              },
            ),
          ],
        ),
      ),
    );
  }

  String _getCityName() {
    final location = state.location;
    if (location == null) {
      return '未知位置';
    }
    // 优先调用 displayName，显示 "千葉県 市川市"，如果没有地址则退回经纬度
    return location.displayName;
  }
}

//首页底部listview加点击
class MainBottomMenu extends StatelessWidget {

  final void Function(String id) onItemTap;

  const MainBottomMenu({
    super.key,
    required this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildMenuItem(
          item: aiItem,
          onTap: () {
            onItemTap(aiItem.id);
          },
        ),
        _buildMenuItem(
          item: settingsItem,
          onTap: () {
            onItemTap(settingsItem.id);
          },
        ),
      ],
    );
  }

}