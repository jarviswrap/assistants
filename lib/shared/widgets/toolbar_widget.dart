import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/git_operations_provider.dart';
import '../providers/repository_provider.dart';

class ToolbarWidget extends ConsumerWidget {
  const ToolbarWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.watch(repositoryProvider);
    final gitOperations = ref.watch(gitOperationsProvider);
    
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey[300]!,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.folder_open),
            tooltip: 'Open Repository',
            onPressed: () => ref.read(repositoryProvider.notifier).openRepository(),
          ),
          const VerticalDivider(),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: gitOperations.isLoading ? null : () => ref.read(gitOperationsProvider.notifier).refresh(),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Stage Changes',
            onPressed: gitOperations.isLoading ? null : () => ref.read(gitOperationsProvider.notifier).stageAll(),
          ),
          IconButton(
            icon: const Icon(Icons.commit),
            tooltip: 'Commit Changes',
            onPressed: gitOperations.isLoading ? null : () => _showCommitDialog(context, ref),
          ),
          IconButton(
            icon: const Icon(Icons.cloud_upload),
            tooltip: 'Push Changes',
            onPressed: gitOperations.isLoading ? null : () => ref.read(gitOperationsProvider.notifier).push(),
          ),
          IconButton(
            icon: const Icon(Icons.cloud_download),
            tooltip: 'Pull Changes',
            onPressed: gitOperations.isLoading ? null : () => ref.read(gitOperationsProvider.notifier).pull(),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
        ],
      ),
    );
  }

  void _showCommitDialog(BuildContext context, WidgetRef ref) {
    final messageController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Commit Changes'),
        content: TextField(
          controller: messageController,
          decoration: const InputDecoration(
            labelText: 'Commit message',
            hintText: 'Enter commit message...',
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (messageController.text.isNotEmpty) {
                ref.read(gitOperationsProvider.notifier).commit(messageController.text);
                Navigator.pop(context);
              }
            },
            child: const Text('Commit'),
          ),
        ],
      ),
    );
  }
}