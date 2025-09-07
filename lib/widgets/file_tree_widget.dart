import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/git_models.dart';
import '../providers/file_explorer_provider.dart';

class FileTreeWidget extends ConsumerWidget {
  const FileTreeWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fileExplorer = ref.watch(fileExplorerProvider);
    
    if (fileExplorer.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (fileExplorer.files.isEmpty) {
      return const Center(
        child: Text('No files found'),
      );
    }

    return ListView.builder(
      itemCount: fileExplorer.files.length,
      itemBuilder: (context, index) {
        final file = fileExplorer.files[index];
        return FileTreeItem(
          file: file,
          onTap: () => ref.read(fileExplorerProvider.notifier).selectFile(file),
          isSelected: fileExplorer.selectedFile?.path == file.path,
        );
      },
    );
  }
}

class FileTreeItem extends StatelessWidget {
  final GitFile file;
  final VoidCallback onTap;
  final bool isSelected;

  const FileTreeItem({
    Key? key,
    required this.file,
    required this.onTap,
    required this.isSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        file.isDirectory ? Icons.folder : Icons.insert_drive_file,
        color: _getStatusColor(file.status),
      ),
      title: Text(
        file.name,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: _getStatusColor(file.status),
        ),
      ),
      subtitle: file.status != GitFileStatus.unmodified
          ? Text(_getStatusText(file.status))
          : null,
      selected: isSelected,
      onTap: onTap,
      trailing: file.status != GitFileStatus.unmodified
          ? Icon(
              _getStatusIcon(file.status),
              size: 16,
              color: _getStatusColor(file.status),
            )
          : null,
    );
  }

  Color _getStatusColor(GitFileStatus status) {
    switch (status) {
      case GitFileStatus.added:
        return Colors.green;
      case GitFileStatus.modified:
        return Colors.orange;
      case GitFileStatus.deleted:
        return Colors.red;
      case GitFileStatus.untracked:
        return Colors.blue;
      case GitFileStatus.unmodified:
        return Colors.grey;
    }
  }

  String _getStatusText(GitFileStatus status) {
    switch (status) {
      case GitFileStatus.added:
        return 'Added';
      case GitFileStatus.modified:
        return 'Modified';
      case GitFileStatus.deleted:
        return 'Deleted';
      case GitFileStatus.untracked:
        return 'Untracked';
      case GitFileStatus.unmodified:
        return '';
    }
  }

  IconData _getStatusIcon(GitFileStatus status) {
    switch (status) {
      case GitFileStatus.added:
        return Icons.add;
      case GitFileStatus.modified:
        return Icons.edit;
      case GitFileStatus.deleted:
        return Icons.remove;
      case GitFileStatus.untracked:
        return Icons.help_outline;
      case GitFileStatus.unmodified:
        return Icons.check;
    }
  }
}