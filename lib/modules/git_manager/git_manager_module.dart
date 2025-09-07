import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// 导入模块相关的屏幕
import 'screens/home_screen.dart';
import 'screens/repository_screen.dart';
import 'screens/commit_history_screen.dart';

class GitManagerModule {
  static const String name = 'Git Manager';
  static const String description = 'Git 仓库管理工具';
  static const IconData icon = Icons.source;
  
  // 模块路由配置
  static List<RouteBase> routes = [
    GoRoute(
      path: '/git-manager',
      builder: (context, state) => const GitManagerHomeScreen(),
      routes: [
        GoRoute(
          path: '/repository/:id',
          builder: (context, state) {
            final repositoryId = state.pathParameters['id']!;
            return RepositoryScreen(repositoryId: repositoryId);
          },
        ),
        GoRoute(
          path: '/commit-history/:id',
          builder: (context, state) {
            final repositoryId = state.pathParameters['id']!;
            return CommitHistoryScreen(repositoryId: repositoryId);
          },
        ),
      ],
    ),
  ];
}