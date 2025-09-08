import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../plugins/plugin_manager.dart';
import '../../shared/screens/home_screen.dart';
import '../../shared/screens/settings_screen.dart';
import '../../shared/screens/plugin_management_screen.dart';

final dynamicRouterProvider = Provider<GoRouter>((ref) {
  final pluginManager = ref.watch(pluginManagerProvider);
  
  return GoRouter(
    initialLocation: '/',
    routes: [
      // 核心路由
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/plugins',
        builder: (context, state) => const PluginManagementScreen(),
      ),
      
      // 插件路由
      ...pluginManager.getAllRoutes(),
    ],
  );
});