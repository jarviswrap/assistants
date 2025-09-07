import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/repository_provider.dart';
import '../providers/git_operations_provider.dart';
import '../widgets/sidebar_navigation.dart';
import '../widgets/commit_list_item.dart';
import '../core/themes/app_theme.dart';

class CommitHistoryScreen extends ConsumerWidget {
  const CommitHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repositoryState = ref.watch(repositoryProvider);
    final gitOperationsState = ref.watch(gitOperationsProvider);
    final currentRepo = repositoryState.currentRepository;

    if (currentRepo == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.folder_outlined,
                size: 64,
              ),
              const SizedBox(height: 16),
              const Text('请先选择一个仓库'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go('/'),
                child: const Text('返回首页'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: Row(
        children: [
          // 侧边栏导航
          const SidebarNavigation(),
          
          // 主内容区域
          Expanded(
            child: Column(
              children: [
                // 顶部工具栏
                _buildTopBar(context, currentRepo, ref),
                
                // 提交历史列表
                Expanded(
                  child: _buildCommitHistory(context, gitOperationsState, ref),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, repository, WidgetRef ref) {
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
          IconButton(
            onPressed: () => context.go('/repository'),
            icon: const Icon(Icons.arrow_back),
            tooltip: '返回',
          ),
          const SizedBox(width: 8),
          Icon(
            Icons.history,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Text(
            '提交历史',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 16),
          Text(
            repository.name,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const Spacer(),
          
          // 刷新按钮
          IconButton(
            onPressed: () => ref.read(gitOperationsProvider.notifier).loadCommitHistory(),
            icon: const Icon(Icons.refresh),
            tooltip: '刷新',
          ),
        ],
      ),
    );
  }

  Widget _buildCommitHistory(BuildContext context, GitOperationsState state, WidgetRef ref) {
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
              onPressed: () => ref.read(gitOperationsProvider.notifier).loadCommitHistory(),
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }

    if (state.commits.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.commit,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              '暂无提交记录',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              '此仓库还没有任何提交记录',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: state.commits.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final commit = state.commits[index];
        return CommitListItem(
          commit: commit,
          onTap: () {
            // TODO: 实现提交详情页面
          },
        );
      },
    );
  }

  void _showCommitDetails(BuildContext context, commit) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('提交详情'),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('哈希值', commit.shortHash),
              _buildDetailRow('作者', '${commit.author} <${commit.email}>'),
              _buildDetailRow('时间', commit.date.toString()),
              const SizedBox(height: 16),
              Text(
                '提交信息',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  commit.message,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}