import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import '../providers/repository_provider.dart';
import '../widgets/repository_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repositoryState = ref.watch(repositoryProvider);

    // 移除 Scaffold 和 SidebarNavigation，直接返回内容组件
    return Column(
      children: [
        // 顶部工具栏
        _buildTopBar(context, ref),
        
        // 仓库列表
        Expanded(
          child: _buildRepositoryList(context, repositoryState, ref),
        ),
      ],
    );
  }

  Widget _buildTopBar(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Text(
            'Git 仓库管理',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: () => _addRepository(context, ref),
            icon: const Icon(Icons.add),
            label: const Text('添加仓库'),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () => ref.read(repositoryProvider.notifier).refreshAllRepositories(),
            icon: const Icon(Icons.refresh),
            tooltip: '刷新所有仓库',
          ),
        ],
      ),
    );
  }

  Widget _buildRepositoryList(BuildContext context, RepositoryState state, WidgetRef ref) {
    if (state.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (state.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              '加载失败',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              state.error!,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.read(repositoryProvider.notifier).refreshAllRepositories(),
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }

    if (state.repositories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.folder_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              '暂无仓库',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              '点击上方按钮添加您的第一个Git仓库',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _addRepository(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('添加仓库'),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.5,
        ),
        itemCount: state.repositories.length,
        itemBuilder: (context, index) {
          final repository = state.repositories[index];
          return RepositoryCard(
            repository: repository,
            isSelected: state.currentRepository?.path == repository.path,
            onTap: () {
              ref.read(repositoryProvider.notifier).setCurrentRepository(repository);
              context.go('/repository');
            },
            onRemove: () => _removeRepository(context, ref, repository.path),
          );
        },
      ),
    );
  }

  Future<void> _addRepository(BuildContext context, WidgetRef ref) async {
    final result = await FilePicker.platform.getDirectoryPath(
      dialogTitle: '选择Git仓库目录',
    );
    
    if (result != null) {
      await ref.read(repositoryProvider.notifier).addRepository(result);
    }
  }

  void _removeRepository(BuildContext context, WidgetRef ref, String path) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要从列表中移除此仓库吗？这不会删除实际的文件。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(repositoryProvider.notifier).removeRepository(path);
              Navigator.of(context).pop();
            },
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }
}