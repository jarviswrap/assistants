import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/widgets/sidebar_navigation.dart';

class ReportEditorScreen extends ConsumerWidget {
  final String? reportId;
  
  const ReportEditorScreen({super.key, this.reportId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Row(
        children: [
          const SidebarNavigation(),
          Expanded(
            child: Column(
              children: [
                _buildTopBar(context),
                Expanded(
                  child: _buildEditor(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
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
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back),
          ),
          const SizedBox(width: 8),
          Text(
            reportId == null ? '新建日报' : '编辑日报',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: () {},
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  Widget _buildEditor(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: TextField(
        maxLines: null,
        expands: true,
        decoration: InputDecoration(
          hintText: '开始编写您的日报...',
          border: OutlineInputBorder(),
        ),
      ),
    );
  }
}