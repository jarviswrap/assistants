import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/sidebar_navigation.dart';

class MainLayout extends ConsumerWidget {
  final Widget child;
  final String? title;
  final List<Widget>? actions;
  
  const MainLayout({
    super.key,
    required this.child,
    this.title,
    this.actions,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Row(
        children: [
          // 侧边栏导航 - 独立模块
          const SidebarNavigation(),
          
          // 主内容区域 - 独立模块
          Expanded(
            child: Column(
              children: [
                // 可选的顶部工具栏
                if (title != null) _buildTopBar(context),
                
                // 主要内容
                Expanded(
                  child: child,
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
          if (title != null) ...[
            Icon(
              Icons.dashboard,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              title!,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
          const Spacer(),
          if (actions != null) ...actions!,
        ],
      ),
    );
  }
}