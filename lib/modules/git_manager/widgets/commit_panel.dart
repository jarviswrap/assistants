import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/git_operations_provider.dart';

class CommitPanel extends ConsumerStatefulWidget {
  const CommitPanel({super.key});

  @override
  ConsumerState<CommitPanel> createState() => _CommitPanelState();
}

class _CommitPanelState extends ConsumerState<CommitPanel> {
  final _messageController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _amendLastCommit = false;

  @override
  void dispose() {
    _messageController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gitState = ref.watch(gitOperationsProvider);
    final stagedFiles = gitState.changedFiles.where((f) => f.isStaged).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题栏
          Row(
            children: [
              Icon(
                Icons.commit,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                '提交更改',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                '已暂存: ${stagedFiles.length} 个文件',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // 提交表单
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 提交消息
                Text(
                  '提交消息 *',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _messageController,
                  decoration: const InputDecoration(
                    hintText: '输入提交消息...',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                
                // 详细描述
                Text(
                  '详细描述（可选）',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: TextField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      hintText: '输入详细描述...',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                    maxLines: null,
                    expands: true,
                    textAlignVertical: TextAlignVertical.top,
                  ),
                ),
                const SizedBox(height: 16),
                
                // 选项
                CheckboxListTile(
                  value: _amendLastCommit,
                  onChanged: (value) {
                    setState(() {
                      _amendLastCommit = value ?? false;
                    });
                  },
                  title: const Text('修改上一次提交'),
                  subtitle: const Text('将更改合并到上一次提交中'),
                  dense: true,
                ),
                const SizedBox(height: 16),
                
                // 提交按钮
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: stagedFiles.isEmpty || _messageController.text.trim().isEmpty
                        ? null
                        : () => _performCommit(),
                    child: gitState.isLoading
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(_amendLastCommit ? '修改提交' : '提交更改'),
                  ),
                ),
                
                if (stagedFiles.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '没有已暂存的文件可以提交',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _performCommit() {
    final message = _messageController.text.trim();
    final description = _descriptionController.text.trim();
    
    final fullMessage = description.isEmpty 
        ? message 
        : '$message\n\n$description';
    
    ref.read(gitOperationsProvider.notifier).commit(
      fullMessage,
      amend: _amendLastCommit,
    ).then((_) {
      // 提交成功后清空表单
      _messageController.clear();
      _descriptionController.clear();
      setState(() {
        _amendLastCommit = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('提交成功'),
          backgroundColor: Colors.green,
        ),
      );
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('提交失败: $error'),
          backgroundColor: Colors.red,
        ),
      );
    });
  }
}