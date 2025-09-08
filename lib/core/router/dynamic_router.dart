import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../plugins/plugin_manager.dart';
import '../../shared/screens/home_screen.dart';
import '../../shared/screens/settings_screen.dart';
import '../../shared/screens/plugin_management_screen.dart';
import '../../shared/layouts/main_layout.dart';
import '../../plugins/git_manager/git_manager_plugin.dart';
import '../../plugins/music_player/music_player_plugin.dart';
import '../../plugins/daily_report/daily_report_plugin.dart';
import '../../plugins/crash_analyzer/crash_analyzer_plugin.dart';

// 插件初始化 Provider
final pluginInitializationProvider = FutureProvider<bool>((ref) async {
  final pluginManager = ref.read(pluginManagerProvider);
  
  try {
    await pluginManager.registerPlugin(GitManagerPlugin());
    await pluginManager.registerPlugin(MusicPlayerPlugin());
    await pluginManager.registerPlugin(DailyReportPlugin());
    await pluginManager.registerPlugin(CrashAnalyzerPlugin());
    return true;
  } catch (e) {
    debugPrint('Failed to register plugins: $e');
    return false;
  }
});

final dynamicRouterProvider = Provider<GoRouter>((ref) {
  final pluginManager = ref.watch(pluginManagerProvider);
  
  return GoRouter(
    initialLocation: '/',
    routes: [
      // 使用 ShellRoute 创建持久布局
      ShellRoute(
        builder: (context, state, child) {
          return MainLayout(
            child: child,
          );
        },
        routes: [
          // 核心路由 - 返回内容组件
          GoRoute(
            path: '/',
            builder: (context, state) => const HomeContent(),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsContent(),
          ),
          GoRoute(
            path: '/plugin-management',
            builder: (context, state) => const PluginManagementContent(),
          ),
          
          // 插件路由
          ...pluginManager.getAllRoutes(),
        ],
      ),
    ],
  );
});