import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/git_operations_provider.dart';
import '../models/git_models.dart';

class GitStatusPanel extends ConsumerWidget {
  const GitStatusPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gitState = ref.watch(gitOperationsProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题栏
          Row(
            children: [
              Icon(
                Icons.change_circle,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                '更改',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (gitState.changedFiles.isNotEmpty) ...[
                TextButton(
                  onPressed: () => ref.read(gitOperationsProvider.notifier).stageAll(),
                  child: const Text('暂存所有'),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () => ref.read(gitOperationsProvider.notifier).discardAll(),
                  child: const Text('丢弃所有'),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          
          // 文件列表
          Expanded(
            child: _buildFileList(context, gitState, ref),
          ),
        ],
      ),
    );
  }

  Widget _buildFileList(BuildContext context, GitOperationsState state, WidgetRef ref) {
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
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              '加载失败',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              state.error!,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (state.changedFiles.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              '工作区干净',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              '没有需要提交的更改',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      );
    }

    // 分组显示文件
    final stagedFiles = state.changedFiles.where((f) => f.isStaged).toList();
    final unstagedFiles = state.changedFiles.where((f) => !f.isStaged).toList();

    return ListView(
      children: [
        if (stagedFiles.isNotEmpty) ...[
          _buildSectionHeader(context, '已暂存的更改', stagedFiles.length),
          ...stagedFiles.map((file) => _buildFileItem(context, file, ref, true)),
          const SizedBox(height: 16),
        ],
        if (unstagedFiles.isNotEmpty) ...[
          _buildSectionHeader(context, '未暂存的更改', unstagedFiles.length),
          ...unstagedFiles.map((file) => _buildFileItem(context, file, ref, false)),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        '$title ($count)',
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildFileItem(BuildContext context, GitFile file, WidgetRef ref, bool isStaged) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 2),
      child: ListTile(
        dense: true,
        leading: Icon(
          _getStatusIcon(file.status),
          size: 16,
          color: _getStatusColor(file.status),
        ),
        title: Text(
          file.filePath,
          style: const TextStyle(fontSize: 13),
        ),
        subtitle: Text(
          _getStatusText(file.status),
          style: TextStyle(
            fontSize: 11,
            color: _getStatusColor(file.status),
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isStaged)
              IconButton(
                onPressed: () => ref.read(gitOperationsProvider.notifier).stageFile(file.filePath),
                icon: const Icon(Icons.add, size: 16),
                tooltip: '暂存',
              ),
            if (isStaged)
              IconButton(
                onPressed: () => ref.read(gitOperationsProvider.notifier).unstageFile(file.filePath),
                icon: const Icon(Icons.remove, size: 16),
                tooltip: '取消暂存',
              ),
            IconButton(
              onPressed: () => ref.read(gitOperationsProvider.notifier).discardFile(file.filePath),
              icon: const Icon(Icons.undo, size: 16),
              tooltip: '丢弃更改',
            ),
          ],
        ),
      ),
    );
  }

  IconData _getStatusIcon(GitFileStatusType status) {
    switch (status) {
      case GitFileStatusType.added:
        return Icons.add_circle;
      case GitFileStatusType.modified:
        return Icons.edit;
      case GitFileStatusType.deleted:
        return Icons.remove_circle;
      case GitFileStatusType.untracked:
        return Icons.help_outline;
      case GitFileStatusType.unmodified:
        return Icons.check_circle;
      case GitFileStatusType.renamed:
        return Icons.drive_file_rename_outline;
      case GitFileStatusType.copied:
        return Icons.content_copy;
      case GitFileStatusType.ignored:
        return Icons.visibility_off;
    }
  }

  Color _getStatusColor(GitFileStatusType status) {
    switch (status) {
      case GitFileStatusType.added:
        return Colors.green;
      case GitFileStatusType.modified:
        return Colors.orange;
      case GitFileStatusType.deleted:
        return Colors.red;
      case GitFileStatusType.untracked:
        return Colors.blue;
      case GitFileStatusType.unmodified:
        return Colors.grey;
      case GitFileStatusType.renamed:
        return Colors.purple;
      case GitFileStatusType.copied:
        return Colors.teal;
      case GitFileStatusType.ignored:
        return Colors.grey.shade400;
    }
  }

  String _getStatusText(GitFileStatusType status) {
    switch (status) {
      case GitFileStatusType.added:
        return '新增';
      case GitFileStatusType.modified:
        return '修改';
      case GitFileStatusType.deleted:
        return '删除';
      case GitFileStatusType.untracked:
        return '未跟踪';
      case GitFileStatusType.unmodified:
        return '未修改';
      case GitFileStatusType.renamed:
        return '重命名';
      case GitFileStatusType.copied:
        return '复制';
      case GitFileStatusType.ignored:
        return '忽略';
    }
  }
}