import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/plugins/base_plugin.dart';
import '../../core/plugins/plugin_interface.dart';
import 'screens/daily_report_home_screen.dart';
import 'screens/report_editor_screen.dart';
import 'screens/report_history_screen.dart';

class DailyReportPlugin extends BasePlugin {
  @override
  PluginMetadata get metadata => const PluginMetadata(
    id: 'daily_report',
    name: '日报管理',
    description: '日常工作报告管理工具',
    version: '1.0.0',
    icon: Icons.assignment,
    enabled: true,  // 添加这行
  );

  @override
  List<PluginPermission> get requiredPermissions => [
    PluginPermission.storage,
    PluginPermission.fileSystem,
  ];

  @override
  List<GoRoute> get routes => [
    GoRoute(
      path: '/daily-report',
      builder: (context, state) => const DailyReportHomeScreen(),
      routes: [
        GoRoute(
          path: 'editor',
          builder: (context, state) => const ReportEditorScreen(),
        ),
        GoRoute(
          path: 'history',
          builder: (context, state) => const ReportHistoryScreen(),
        ),
      ],
    ),
  ];

  @override
  List<PluginMenuItem> get menuItems => [
    PluginMenuItem(
      label: '日报管理',
      icon: Icons.assignment,
      route: '/daily-report',
      subItems: [
        PluginMenuItem(
          label: '编写日报',
          icon: Icons.edit,
          route: '/daily-report/editor',
        ),
        PluginMenuItem(
          label: '历史记录',
          icon: Icons.history,
          route: '/daily-report/history',
        ),
      ],
    ),
  ];

  @override
  Widget? get settingsWidget => Builder(
    builder: (context) => Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('日报设置', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          const Text('这里可以配置日报的相关设置'),
        ],
      ),
    ),
  );

  @override
  Future<void> onInitialize() async {
    // 初始化日报插件
  }

  @override
  Future<void> onPluginEnable() async {
    // 插件启用时的操作
  }

  @override
  Future<void> onPluginDisable() async {
    // 插件禁用时的操作
  }

  @override
  Future<bool> healthCheck() async {
    return true;
  }
}