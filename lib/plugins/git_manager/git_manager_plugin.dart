import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/plugins/base_plugin.dart';
import '../../core/plugins/plugin_interface.dart';
import 'screens/git_manager_home_screen.dart';

class GitManagerPlugin extends BasePlugin {
  @override
  PluginMetadata get metadata => const PluginMetadata(
    id: 'git_manager',
    name: 'Git管理器',
    description: 'Git仓库管理和版本控制工具',
    version: '1.0.0',
    icon: Icons.source,
    category: 'development',
  );

  @override
  List<PluginPermission> get requiredPermissions => [
    PluginPermission.fileSystem
  ];

  @override
  List<GoRoute> get routes => [
    GoRoute(
      path: '/git-manager',
      builder: (context, state) => const GitManagerHomeScreen(),
    ),
  ];

  @override
  List<PluginMenuItem> get menuItems => [
    PluginMenuItem(
      label: 'Git管理器',
      icon: Icons.source,
      route: '/git-manager',
    ),
  ];

  @override
  Widget? get settingsWidget => Builder(
    builder: (context) => Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Git设置', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          const Text('这里可以配置Git的相关设置'),
        ],
      ),
    ),
  );

  @override
  Future<void> onInitialize() async {
    // 初始化Git管理器
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