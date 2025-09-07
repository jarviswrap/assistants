import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/git_models.dart';
import '../providers/git_operations_provider.dart';

class BranchSelectorWidget extends ConsumerWidget {
  const BranchSelectorWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gitOperations = ref.watch(gitOperationsProvider);
    
    return PopupMenuButton<GitBranch>(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.account_tree, size: 16),
            const SizedBox(width: 8),
            Text(
              gitOperations.currentBranch?.name ?? 'No branch',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_drop_down, size: 16),
          ],
        ),
      ),
      itemBuilder: (context) {
        return gitOperations.branches.map((branch) {
          return PopupMenuItem<GitBranch>(
            value: branch,
            child: Row(
              children: [
                Icon(
                  branch.isCurrent ? Icons.check : Icons.account_tree,
                  size: 16,
                  color: branch.isCurrent ? Colors.green : Colors.grey,
                ),
                const SizedBox(width: 8),
                Text(branch.name),
                if (branch.isRemote) ...[
                  const SizedBox(width: 8),
                  Icon(
                    Icons.cloud,
                    size: 12,
                    color: Colors.grey[600],
                  ),
                ],
              ],
            ),
          );
        }).toList();
      },
      onSelected: (branch) {
        ref.read(gitOperationsProvider.notifier).switchBranch(branch.name);
      },
    );
  }
}