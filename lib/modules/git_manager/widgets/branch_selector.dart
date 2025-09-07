import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/git_operations_provider.dart';
import '../models/git_models.dart';

class BranchSelector extends ConsumerWidget {
  final GitRepository repository;
  
  const BranchSelector({
    super.key,
    required this.repository,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gitState = ref.watch(gitOperationsProvider);
    final currentBranch = gitState.currentBranch;

    return PopupMenuButton<GitBranch>(
      onSelected: (branch) {
        if (branch.name != currentBranch?.name) {
          ref.read(gitOperationsProvider.notifier).switchBranch(branch.name);
        }
      },
      itemBuilder: (context) {
        return gitState.branches.map((branch) {
          return PopupMenuItem<GitBranch>(
            value: branch,
            child: Row(
              children: [
                Icon(
                  branch.isCurrent ? Icons.check : Icons.account_tree,
                  size: 16,
                  color: branch.isCurrent 
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    branch.name,
                    style: TextStyle(
                      fontWeight: branch.isCurrent ? FontWeight.w600 : FontWeight.normal,
                      color: branch.isCurrent 
                          ? Theme.of(context).colorScheme.primary
                          : null,
                    ),
                  ),
                ),
                if (branch.isRemote)
                  Icon(
                    Icons.cloud,
                    size: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              ],
            ),
          );
        }).toList();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context).colorScheme.outline,
          ),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.account_tree,
              size: 16,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 6),
            Text(
              currentBranch?.name ?? 'main',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_drop_down,
              size: 16,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}