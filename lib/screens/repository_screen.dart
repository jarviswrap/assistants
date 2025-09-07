import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/repository_provider.dart';
import '../providers/git_operations_provider.dart';
import '../providers/file_explorer_provider.dart';
import '../widgets/sidebar_navigation.dart';
import '../widgets/file_explorer.dart';
import '../widgets/git_status_panel.dart';
import '../widgets/commit_panel.dart';
import '../widgets/branch_selector.dart';

class RepositoryScreen extends ConsumerStatefulWidget {
  const RepositoryScreen({super.key});

  @override
  ConsumerState<RepositoryScreen> createState() => _RepositoryScreenState();
}

class _RepositoryScreenState extends ConsumerState<RepositoryScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    // 加载提交历史
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(gitOperationsProvider.notifier).loadCommitHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    final repositoryState = ref.watch(repositoryProvider);
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
                _buildTopBar(context, currentRepo),
                
                // 主要内容区域
                Expanded(
                  child: Row(
                    children: [
                      // 左侧文件浏览器
                      SizedBox(
                        width: 300,
                        child: FileExplorer(),
                      ),
                      
                      // 分隔线
                      const VerticalDivider(width: 1),
                      
                      // 右侧内容区域
                      Expanded(
                        child: _buildMainContent(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, repository) {
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
          Icon(
            Icons.folder,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  repository.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  repository.path,
                  style: Theme.of(context).textTheme.bodySmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          
          // 分支选择器
          BranchSelector(repository: repository),
          
          const SizedBox(width: 16),
          
          // 操作按钮
          Row(
            children: [
              IconButton(
                onPressed: () => ref.read(gitOperationsProvider.notifier).pull(),
                icon: const Icon(Icons.download),
                tooltip: '拉取',
              ),
              IconButton(
                onPressed: () => ref.read(gitOperationsProvider.notifier).push(),
                icon: const Icon(Icons.upload),
                tooltip: '推送',
              ),
              IconButton(
                onPressed: () => context.go('/repository/history'),
                icon: const Icon(Icons.history),
                tooltip: '提交历史',
              ),
              IconButton(
                onPressed: () => ref.read(repositoryProvider.notifier).refreshRepository(repository.path),
                icon: const Icon(Icons.refresh),
                tooltip: '刷新',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return Column(
      children: [
        // 标签栏
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).dividerColor,
                width: 1,
              ),
            ),
          ),
          child: TabBar(
            controller: null,
            tabs: const [
              Tab(text: '更改'),
              Tab(text: '提交'),
            ],
            onTap: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
          ),
        ),
        
        // 内容区域
        Expanded(
          child: IndexedStack(
            index: _selectedIndex,
            children: const [
              GitStatusPanel(),
              CommitPanel(),
            ],
          ),
        ),
      ],
    );
  }
}