import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/git_models.dart';
import '../providers/git_operations_provider.dart';

class CommitHistoryWidget extends ConsumerWidget {
  const CommitHistoryWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gitOperations = ref.watch(gitOperationsProvider);
    
    if (gitOperations.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (gitOperations.commits.isEmpty) {
      return const Center(
        child: Text('No commits found'),
      );
    }

    return ListView.builder(
      itemCount: gitOperations.commits.length,
      itemBuilder: (context, index) {
        final commit = gitOperations.commits[index];
        return CommitItem(
          commit: commit,
          onTap: () => ref.read(gitOperationsProvider.notifier).selectCommit(commit),
        );
      },
    );
  }
}

class CommitItem extends StatelessWidget {
  final GitCommit commit;
  final VoidCallback onTap;

  const CommitItem({
    super.key,
    required this.commit,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          child: Text(
            commit.author.substring(0, 1).toUpperCase(),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          commit.message,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'by ${commit.author}',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
            Text(
              _formatDate(commit.date),
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 11,
              ),
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            commit.hash.substring(0, 7),
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 11,
            ),
          ),
        ),
        onTap: onTap,
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }
}