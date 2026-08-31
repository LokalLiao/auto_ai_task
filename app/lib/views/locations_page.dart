import 'package:flutter/material.dart';
import '../utils/app_navigator.dart';
import '../viewmodels/locations_view_model.dart';
import '../models/poi_item.dart';

class LocationsPage extends StatefulWidget {
  const LocationsPage({super.key});

  @override
  State<LocationsPage> createState() => _LocationPageState();
}

class _LocationPageState extends State<LocationsPage> {
  late final LocationsViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = LocationsViewModel();
    _viewModel.loadNearbyPois();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('周边 3km 设施'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => AppNavigator.back(context),
        ),
      ),
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) {
          if (_viewModel.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (_viewModel.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_viewModel.error!, style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _viewModel.loadNearbyPois,
                    child: const Text('重试'),
                  ),
                ],
              ),
            );
          }
          return Column(
            children: [
              // 1. 顶部当前定位显示
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                color: Colors.blue.withOpacity(0.08),
                child: Row(
                  children: [
                    const Icon(Icons.my_location, size: 18, color: Colors.blue),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '中心点: ${_viewModel.currentAddress}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              // 2. 分类筛选 Chip 栏
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: _viewModel.categories.map((category) {
                    final isSelected = _viewModel.selectedCategory == category;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ChoiceChip(
                        label: Text(category),
                        selected: isSelected,
                        onSelected: (_) => _viewModel.setCategory(category),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const Divider(height: 1),
              // 3. POI 列表
              Expanded(
                child: _viewModel.filteredPois.isEmpty
                    ? const Center(child: Text('该分类下暂无搜索结果'))
                    : ListView.separated(
                  itemCount: _viewModel.filteredPois.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final item = _viewModel.filteredPois[index];
                    return _buildPoiTile(item);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPoiTile(PoiItem item) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.blue.shade50,
        child: Icon(item.icon, color: Colors.blue),
      ),
      title: Text(
        item.name,
        style: const TextStyle(fontWeight: FontWeight.bold),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        '${item.category} · 距中心约 ${item.distanceText}',
        style: const TextStyle(fontSize: 12, color: Colors.grey),
      ),
      trailing: const Icon(Icons.navigation, color: Colors.blue),
      onTap: () => _viewModel.openNavigation(context, item),
    );
  }
}