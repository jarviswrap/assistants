import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/plugins/plugin_manager.dart';
import '../../core/plugins/plugin_interface.dart';
import '../../core/services/sidebar_state.dart';

class SidebarNavigation extends ConsumerWidget {
  const SidebarNavigation({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pluginManager = ref.watch(pluginManagerProvider);
    final pluginMenuItems = pluginManager.getAllMenuItems();
    final currentLocation = GoRouterState.of(context).uri.toString();
    final isExpanded = ref.watch(sidebarExpandedProvider);

    return AnimatedContainer(
      duration: SidebarConstants.animationDuration,
      width: isExpanded ? SidebarConstants.expandedWidth : SidebarConstants.collapsedWidth,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          right: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          _buildHeader(context, ref, isExpanded),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                if (isExpanded) _buildSectionHeader(context, '核心功能'),
                _buildMenuItem(
                  context,
                  '首页',
                  Icons.home,
                  '/',
                  currentLocation,
                  isExpanded,
                ),
                _buildMenuItem(
                  context,
                  '设置',
                  Icons.settings,
                  '/settings',
                  currentLocation,
                  isExpanded,
                ),
                _buildMenuItem(
                  context,
                  '插件管理',
                  Icons.extension,
                  '/plugin-management',
                  currentLocation,
                  isExpanded,
                ),
                if (pluginMenuItems.isNotEmpty) ...[
                  if (isExpanded) _buildSectionHeader(context, '插件'),
                  ...pluginMenuItems.map(
                    (item) => _buildPluginMenuItem(context, item, currentLocation, isExpanded),
                  ),
                ],
              ],
            ),
          ),
          _buildFooter(context, isExpanded),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref, bool isExpanded) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              ref.read(sidebarExpandedProvider.notifier).state = !isExpanded;
            },
            child: Icon(
              Icons.assistant,
              size: 32,
              color: Theme.of(context).primaryColor,
            ),
          ),
          if (isExpanded) ...[
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Assistants',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            GestureDetector(
              onTap: () {
                ref.read(sidebarExpandedProvider.notifier).state = false;
              },
              child: Icon(
                Icons.chevron_left,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context,
    String title,
    IconData icon,
    String route,
    String currentLocation,
    bool isExpanded,
  ) {
    final isSelected = currentLocation == route;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Tooltip(
        message: isExpanded ? '' : title,
        child: InkWell(
          onTap: () => context.go(route),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            height: 48,
            padding: EdgeInsets.symmetric(
              horizontal: isExpanded ? 16 : 12,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: isSelected ? Theme.of(context).primaryColor.withOpacity(0.1) : null,
              borderRadius: BorderRadius.circular(8),
            ),
            child: isExpanded
                ? Row(
                    children: [
                      Icon(
                        icon,
                        size: 20,
                        color: isSelected ? Theme.of(context).primaryColor : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            color: isSelected ? Theme.of(context).primaryColor : null,
                            fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  )
                : Center(
                    child: Icon(
                      icon,
                      size: 20,
                      color: isSelected ? Theme.of(context).primaryColor : null,
                    ),
                  ),
        ),
      ),
    )
    );
  }

  Widget _buildPluginMenuItem(
    BuildContext context,
    PluginMenuItem item,
    String currentLocation,
    bool isExpanded,
  ) {
    if (!isExpanded) {
      // 收缩状态下，插件菜单项显示为简单图标
      return _buildMenuItem(
        context,
        item.label,
        item.icon,
        item.route,
        currentLocation,
        isExpanded,
      );
    }

    if (item.subItems != null && item.subItems!.isNotEmpty) {
      return ExpansionTile(
        leading: Icon(item.icon),
        title: Text(item.label),
        children: item.subItems!
            .map((subItem) => _buildSubMenuItem(context, subItem, currentLocation, isExpanded))
            .toList(),
      );
    }

    return _buildMenuItem(
      context,
      item.label,
      item.icon,
      item.route,
      currentLocation,
      isExpanded,
    );
  }

  Widget _buildSubMenuItem(
    BuildContext context,
    PluginMenuItem item,
    String currentLocation,
    bool isExpanded,
  ) {
    final isSelected = currentLocation == item.route;
    
    return Container(
      margin: const EdgeInsets.only(left: 16, right: 8, top: 2, bottom: 2),
      child: Tooltip(
        message: isExpanded ? '' : item.label,
        child: ListTile(
          leading: Icon(
            item.icon,
            size: 20,
            color: isSelected
                ? Theme.of(context).primaryColor
                : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          title: isExpanded ? Text(
            item.label,
            style: TextStyle(
              color: isSelected
                  ? Theme.of(context).primaryColor
                  : Theme.of(context).colorScheme.onSurface,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              fontSize: 14,
            ),
          ) : null,
          selected: isSelected,
          selectedTileColor: Theme.of(context).primaryColor.withOpacity(0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          contentPadding: isExpanded 
              ? const EdgeInsets.symmetric(horizontal: 16)
              : const EdgeInsets.symmetric(horizontal: 24),
          onTap: () => context.go(item.route),
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context, bool isExpanded) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: Theme.of(context).primaryColor,
            child: const Icon(
              Icons.person,
              color: Colors.white,
              size: 20,
            ),
          ),
          if (isExpanded) ...[
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '用户',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '在线',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}