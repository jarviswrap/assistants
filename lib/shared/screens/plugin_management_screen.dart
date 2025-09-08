import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/plugins/plugin_manager.dart';
import '../../core/plugins/plugin_interface.dart';
import '../widgets/sidebar_navigation.dart';

class PluginManagementScreen extends ConsumerWidget {
  const PluginManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pluginManager = ref.watch(pluginManagerProvider);
    final plugins = pluginManager.getAllPlugins();

    return Scaffold(
      body: Row(
        children: [
          const SidebarNavigation(),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.extension, size: 32, color: Theme.of(context).primaryColor),
                      const SizedBox(width: 12),
                      Text(
                        '插件管理',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: _buildPluginList(context, ref, plugins),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPluginList(BuildContext context, WidgetRef ref, List<PluginInfo> plugins) {
    if (plugins.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.extension_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('暂无插件', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: plugins.length,
      itemBuilder: (context, index) {
        final pluginInfo = plugins[index];
        return _buildPluginCard(context, ref, pluginInfo);
      },
    );
  }

  Widget _buildPluginCard(BuildContext context, WidgetRef ref, PluginInfo pluginInfo) {
    final plugin = pluginInfo.plugin;
    final metadata = plugin.metadata;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(metadata.icon, size: 32, color: Theme.of(context).primaryColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        metadata.name,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(
                        metadata.description,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusChip(context, pluginInfo.status),
                const SizedBox(width: 12),
                Switch(
                  value: pluginInfo.isEnabled,
                  onChanged: (value) => _togglePlugin(ref, metadata.id, value),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildInfoChip(context, '版本', metadata.version),
                _buildInfoChip(context, '分类', metadata.category),
                if (plugin.requiredPermissions.isNotEmpty) ...
                  plugin.requiredPermissions.map(
                    (permission) => _buildPermissionChip(context, permission),
                  ),
              ],
            ),
            if (pluginInfo.errorMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error, color: Colors.red.shade600, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        pluginInfo.errorMessage!,
                        style: TextStyle(color: Colors.red.shade700, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context, PluginStatus status) {
    Color color;
    String label;
    IconData icon;

    switch (status) {
      case PluginStatus.unloaded:
        color = Colors.grey;
        label = '未加载';
        icon = Icons.circle;
        break;
      case PluginStatus.loading:
        color = Colors.orange;
        label = '加载中';
        icon = Icons.hourglass_empty;
        break;
      case PluginStatus.loaded:
        color = Colors.blue;
        label = '已加载';
        icon = Icons.check_circle_outline;
        break;
      case PluginStatus.enabled:
        color = Colors.green;
        label = '已启用';
        icon = Icons.check_circle;
        break;
      case PluginStatus.disabled:
        color = Colors.grey;
        label = '已禁用';
        icon = Icons.cancel;
        break;
      case PluginStatus.error:
        color = Colors.red;
        label = '错误';
        icon = Icons.error;
        break;
    }

    return Chip(
      avatar: Icon(icon, size: 16, color: color),
      label: Text(label, style: TextStyle(color: color, fontSize: 12)),
      backgroundColor: color.withOpacity(0.1),
      side: BorderSide(color: color.withOpacity(0.3)),
    );
  }

  Widget _buildInfoChip(BuildContext context, String label, String value) {
    return Chip(
      label: Text('$label: $value', style: const TextStyle(fontSize: 12)),
      backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
    );
  }

  Widget _buildPermissionChip(BuildContext context, PluginPermission permission) {
    return Chip(
      avatar: const Icon(Icons.security, size: 16),
      label: Text(_getPermissionName(permission), style: const TextStyle(fontSize: 12)),
      backgroundColor: Colors.amber[50],
      side: BorderSide(color: Colors.amber[200]!),
    );
  }

  String _getPermissionName(PluginPermission permission) {
    switch (permission) {
      case PluginPermission.fileSystem:
        return '文件系统';
      case PluginPermission.network:
        return '网络访问';
      case PluginPermission.storage:
        return '存储访问';
      case PluginPermission.notifications:
        return '通知';
      case PluginPermission.systemInfo:
        return '系统信息';
    }
  }

  void _togglePlugin(WidgetRef ref, String pluginId, bool enabled) {
    final pluginManager = ref.read(pluginManagerProvider);
    if (enabled) {
      pluginManager.enablePlugin(pluginId);
    } else {
      pluginManager.disablePlugin(pluginId);
    }
  }
}