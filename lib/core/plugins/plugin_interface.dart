import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// 插件元数据
class PluginMetadata {
  final String id;
  final String name;
  final String description;
  final String version;
  final IconData icon;
  final String category;
  final List<String> dependencies;
  final bool enabled;

  const PluginMetadata({
    required this.id,
    required this.name,
    required this.description,
    required this.version,
    required this.icon,
    this.category = 'general',
    this.dependencies = const [],
    this.enabled = true,
  });
}

/// 插件菜单项
class PluginMenuItem {
  final String label;
  final IconData icon;
  final String route;
  final List<PluginMenuItem>? subItems;

  const PluginMenuItem({
    required this.label,
    required this.icon,
    required this.route,
    this.subItems,
  });
}

/// 插件权限
enum PluginPermission {
  fileSystem,
  network,
  storage,
  notifications,
  systemInfo,
}

/// 插件接口
abstract class IPlugin {
  /// 插件元数据
  PluginMetadata get metadata;

  /// 插件所需权限
  List<PluginPermission> get requiredPermissions => [];

  /// 插件路由
  List<RouteBase> get routes;

  /// 插件菜单项
  List<PluginMenuItem> get menuItems;

  /// 插件初始化
  Future<void> initialize();

  /// 插件销毁
  Future<void> dispose();

  /// 插件启用
  Future<void> onEnable();

  /// 插件禁用
  Future<void> onDisable();

  /// 插件配置页面
  Widget? get settingsWidget => null;

  /// 插件状态检查
  Future<bool> healthCheck() async => true;
}