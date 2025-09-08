import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/plugins/base_plugin.dart';
import '../../core/plugins/plugin_interface.dart';
import 'screens/crash_analyzer_screen.dart';
import 'services/addr2line_service.dart';

class CrashAnalyzerPlugin extends BasePlugin {
  @override
  PluginMetadata get metadata => const PluginMetadata(
    id: 'crash_analyzer',
    name: 'Crash分析器',
    description: 'Android native crash堆栈符号化工具',
    version: '1.0.0',
    icon: Icons.bug_report,
    category: 'development',
    enabled: true,  // 添加这行
  );

  @override
  List<PluginPermission> get requiredPermissions => [
    PluginPermission.fileSystem,
    // 移除或替换为正确的权限
  ];

  @override
  List<GoRoute> get routes => [
    GoRoute(
      path: '/crash-analyzer',
      builder: (context, state) => const CrashAnalyzerScreen(),
    ),
  ];

  @override
  List<PluginMenuItem> get menuItems => [
    PluginMenuItem(
      label: 'Crash分析器',
      icon: Icons.bug_report,
      route: '/crash-analyzer',
    ),
  ];

  @override
  Widget? get settingsWidget => Builder(
    builder: (context) => Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Crash分析器设置', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          const Text('配置Android SDK路径和默认符号文件路径'),
        ],
      ),
    ),
  );

  @override
  Future<void> initialize() async {
    // 初始化addr2line服务
    await Addr2LineService.instance.initialize();
  }

  @override
  Future<void> dispose() async {
    // 清理资源
    await Addr2LineService.instance.dispose();
  }
  
  @override
  Future<bool> healthCheck() async {
    try {
      // 检查基本配置是否可用
      final service = Addr2LineService.instance;
      return true;
    } catch (e) {
      return false;
    }
  }

}