import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'plugin_interface.dart';

/// 插件状态
enum PluginStatus {
  unloaded,
  loading,
  loaded,
  enabled,
  disabled,
  error,
}

/// 插件信息
class PluginInfo {
  final IPlugin plugin;
  final PluginStatus status;
  final String? errorMessage;
  final DateTime? lastUpdated;
  final bool isEnabled;

  const PluginInfo({
    required this.plugin,
    required this.status,
    this.errorMessage,
    this.lastUpdated,
    this.isEnabled = false,
  });

  PluginInfo copyWith({
    IPlugin? plugin,
    PluginStatus? status,
    String? errorMessage,
    DateTime? lastUpdated,
    bool? isEnabled,
  }) {
    return PluginInfo(
      plugin: plugin ?? this.plugin,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }
}

/// 插件管理器
class PluginManager extends ChangeNotifier {
  final Map<String, PluginInfo> _plugins = {};
  final Map<String, List<String>> _dependencies = {};
  final Set<String> _enabledPlugins = {};

  /// 获取所有插件
  Map<String, PluginInfo> get plugins => Map.unmodifiable(_plugins);

  /// 获取已启用的插件
  List<IPlugin> get enabledPlugins {
    return _plugins.values
        .where((info) => _enabledPlugins.contains(info.plugin.metadata.id))
        .map((info) => info.plugin)
        .toList();
  }

  /// 获取已启用的插件
  List<IPlugin> getEnabledPlugins() {
    return enabledPlugins;
  }
  
  List<PluginInfo> getAllPlugins() {
    return _plugins.values.map((info) => PluginInfo(
      plugin: info.plugin,
      status: info.status,
      errorMessage: info.errorMessage,
      lastUpdated: info.lastUpdated,
      isEnabled: _enabledPlugins.contains(info.plugin.metadata.id),
    )).toList();
  }

  /// 注册插件
  Future<bool> registerPlugin(IPlugin plugin) async {
    try {
      final id = plugin.metadata.id;
      
      // 检查插件是否已存在
      if (_plugins.containsKey(id)) {
        debugPrint('Plugin $id already registered');
        return false;
      }

      // 检查依赖
      if (!await _checkDependencies(plugin)) {
        debugPrint('Plugin $id dependencies not satisfied');
        return false;
      }

      // 更新插件状态为加载中
      _plugins[id] = PluginInfo(
        plugin: plugin,
        status: PluginStatus.loading,
        lastUpdated: DateTime.now(),
      );
      notifyListeners();

      // 初始化插件
      await plugin.initialize();

      // 更新状态为已加载
      _plugins[id] = _plugins[id]!.copyWith(
        status: PluginStatus.loaded,
        lastUpdated: DateTime.now(),
      );

      // 如果插件默认启用，则启用它
      if (plugin.metadata.enabled) {
        await enablePlugin(id);
      }

      notifyListeners();
      debugPrint('Plugin $id registered successfully');
      return true;
    } catch (e) {
      _plugins[plugin.metadata.id] = PluginInfo(
        plugin: plugin,
        status: PluginStatus.error,
        errorMessage: e.toString(),
        lastUpdated: DateTime.now(),
      );
      notifyListeners();
      debugPrint('Failed to register plugin ${plugin.metadata.id}: $e');
      return false;
    }
  }

  /// 启用插件
  Future<bool> enablePlugin(String pluginId) async {
    final pluginInfo = _plugins[pluginId];
    if (pluginInfo == null) return false;

    try {
      await pluginInfo.plugin.onEnable();
      _enabledPlugins.add(pluginId);
      _plugins[pluginId] = pluginInfo.copyWith(
        status: PluginStatus.enabled,
        lastUpdated: DateTime.now(),
        isEnabled: true,
      );
      notifyListeners();
      return true;
    } catch (e) {
      _plugins[pluginId] = pluginInfo.copyWith(
        status: PluginStatus.error,
        errorMessage: e.toString(),
        lastUpdated: DateTime.now(),
      );
      notifyListeners();
      return false;
    }
  }

  /// 禁用插件
  Future<bool> disablePlugin(String pluginId) async {
    final pluginInfo = _plugins[pluginId];
    if (pluginInfo == null) return false;

    try {
      await pluginInfo.plugin.onDisable();
      _enabledPlugins.remove(pluginId);
      _plugins[pluginId] = pluginInfo.copyWith(
        status: PluginStatus.disabled,
        lastUpdated: DateTime.now(),
        isEnabled: false,
      );
      notifyListeners();
      return true;
    } catch (e) {
      _plugins[pluginId] = pluginInfo.copyWith(
        status: PluginStatus.error,
        errorMessage: e.toString(),
        lastUpdated: DateTime.now(),
      );
      notifyListeners();
      return false;
    }
  }

  /// 卸载插件
  Future<bool> unregisterPlugin(String pluginId) async {
    final pluginInfo = _plugins[pluginId];
    if (pluginInfo == null) return false;

    try {
      // 先禁用插件
      if (pluginInfo.status == PluginStatus.enabled) {
        await disablePlugin(pluginId);
      }

      // 销毁插件
      await pluginInfo.plugin.dispose();

      // 移除插件
      _plugins.remove(pluginId);
      _dependencies.remove(pluginId);
      _enabledPlugins.remove(pluginId);

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Failed to unregister plugin $pluginId: $e');
      return false;
    }
  }

  /// 获取所有路由
  List<RouteBase> getAllRoutes() {
    final routes = <RouteBase>[];
    for (final plugin in enabledPlugins) {
      routes.addAll(plugin.routes);
    }
    return routes;
  }

  /// 获取所有菜单项
  List<PluginMenuItem> getAllMenuItems() {
    final menuItems = <PluginMenuItem>[];
    for (final plugin in enabledPlugins) {
      menuItems.addAll(plugin.menuItems);
    }
    return menuItems;
  }

  /// 检查插件依赖
  Future<bool> _checkDependencies(IPlugin plugin) async {
    for (final dependency in plugin.metadata.dependencies) {
      final depPlugin = _plugins[dependency];
      if (depPlugin == null || depPlugin.status != PluginStatus.enabled) {
        return false;
      }
    }
    return true;
  }

  /// 健康检查
  Future<Map<String, bool>> healthCheck() async {
    final results = <String, bool>{};
    for (final entry in _plugins.entries) {
      if (entry.value.status == PluginStatus.enabled) {
        results[entry.key] = await entry.value.plugin.healthCheck();
      }
    }
    return results;
  }
}

/// 插件管理器提供者
final pluginManagerProvider = ChangeNotifierProvider<PluginManager>((ref) {
  return PluginManager();
});