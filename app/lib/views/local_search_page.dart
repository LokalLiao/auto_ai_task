import 'package:flutter/material.dart';
import '../utils/app_navigator.dart';
import '../viewmodels/local_search_view_model.dart';

class LocalSearchPage extends StatefulWidget {
  const LocalSearchPage({super.key});

  @override
  State<LocalSearchPage> createState() => _LocalSearchPageState();
}

class _LocalSearchPageState extends State<LocalSearchPage> {
  late final LocalSearchViewModel _viewModel;
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _viewModel = LocalSearchViewModel();
    _searchController = TextEditingController();
    _viewModel.fetchDrives();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  void _onSearch() {
    FocusScope.of(context).unfocus();
    _viewModel.searchFiles(_searchController.text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('本地文件搜索'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => AppNavigator.back(context),
        ),
      ),
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) {
          // 初始化加载盘符
          if (_viewModel.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          // 初始化出错且盘符为空时展示重试界面
          if (_viewModel.error != null && _viewModel.drives.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_viewModel.error!, style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _viewModel.fetchDrives,
                    child: const Text('重试'),
                  ),
                ],
              ),
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 第一栏：显示获取到的所有盘符及复选框
              _buildDriveSection(),
              const Divider(height: 1),
              // 第二栏：输入框和搜索按钮
              _buildSearchBar(),
              const Divider(height: 1),
              // 搜索错误浮条提示（如果仅是搜索/删除时出错）
              if (_viewModel.error != null && _viewModel.drives.isNotEmpty)
                Container(
                  width: double.infinity,
                  color: Colors.red.shade50,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    _viewModel.error!,
                    style: const TextStyle(color: Colors.red, fontSize: 13),
                  ),
                ),
              // 第三栏：搜索结果列表
              Expanded(
                child: _buildResultListView(),
              ),
            ],
          );
        },
      ),
    );
  }

  /// 第一栏：盘符选择区域
  Widget _buildDriveSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '选择搜索盘符（默认全选/全盘）：',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 12.0,
            runSpacing: 4.0,
            children: List.generate(_viewModel.drives.length, (index) {
              final drive = _viewModel.drives[index];
              return InkWell(
                borderRadius: BorderRadius.circular(6),
                onTap: () => _viewModel.toggleDriveSelection(index, !drive.isSelected),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Checkbox(
                      value: drive.isSelected,
                      onChanged: (val) => _viewModel.toggleDriveSelection(index, val),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    Text(drive.label, style: const TextStyle(fontSize: 14)),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  /// 第二栏：搜索输入框 + 搜索按钮
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '输入关键词搜索文件...',
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                isDense: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                prefixIcon: const Icon(Icons.search, size: 20),
              ),
              onSubmitted: (_) => _onSearch(),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: _viewModel.searching ? null : _onSearch,
            child: _viewModel.searching
                ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
                : const Text('搜索'),
          ),
        ],
      ),
    );
  }

  /// 第三栏：搜索结果展示
  Widget _buildResultListView() {
    if (_viewModel.searching) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 12),
            Text('正在检索本地文件中...'),
          ],
        ),
      );
    }

    if (_viewModel.searchResultList.isEmpty) {
      return const Center(
        child: Text('暂无搜索结果', style: TextStyle(color: Colors.grey)),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _viewModel.searchResultList.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final item = _viewModel.searchResultList[index];
        return _buildFileItem(item);
      },
    );
  }

  /// 单条搜索结果项（无复选框）
  Widget _buildFileItem(SearchFileItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          const Icon(Icons.insert_drive_file_outlined, color: Colors.blueGrey, size: 22),
          const SizedBox(width: 10),
          // 文件名称与完整路径
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  item.path,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // 发送邮件按钮
          IconButton(
            tooltip: '发送邮件',
            icon: const Icon(Icons.email_outlined, color: Colors.blue),
            onPressed: () {
              // 触发系统默认邮件客户端或调用业务逻辑
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('准备发送邮件: ${item.name}')),
              );
            },
          ),
          // 回收站按钮
          IconButton(
            tooltip: '移至回收站',
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () => _confirmDelete(item),
          ),
        ],
      ),
    );
  }

  /// 移入回收站确认弹窗
  void _confirmDelete(SearchFileItem item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('是否将以下文件放入回收站？\n\n${item.path}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('取消'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.of(ctx).pop();
              _viewModel.moveToTrash(item);
            },
            child: const Text('移入回收站', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}