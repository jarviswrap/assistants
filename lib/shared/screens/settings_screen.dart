import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/sidebar_navigation.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Row(
        children: [
          // 侧边栏导航
          const SidebarNavigation(),
          
          // 主内容区域
          Expanded(
            child: Column(
              children: [
                // 顶部工具栏
                _buildTopBar(context),
                
                // 设置内容
                Expanded(
                  child: _buildSettingsContent(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.settings,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Text(
            '设置',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsContent(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSettingsSection(
            context,
            '外观',
            [
              ListTile(
                leading: const Icon(Icons.palette),
                title: const Text('主题模式'),
                subtitle: const Text('选择应用主题'),
                trailing: DropdownButton<String>(
                  value: '跟随系统',
                  items: const [
                    DropdownMenuItem(value: '跟随系统', child: Text('跟随系统')),
                    DropdownMenuItem(value: '浅色', child: Text('浅色')),
                    DropdownMenuItem(value: '深色', child: Text('深色')),
                  ],
                  onChanged: (value) {
                    // TODO: 实现主题切换
                  },
                ),
              ),
              const SwitchListTile(
                secondary: Icon(Icons.font_download),
                title: Text('使用等宽字体'),
                subtitle: Text('在代码显示中使用等宽字体'),
                value: true,
                onChanged: null, // TODO: 实现字体切换
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          _buildSettingsSection(
            context,
            'Git配置',
            [
              ListTile(
                leading: const Icon(Icons.person),
                title: const Text('用户名'),
                subtitle: const Text('Git提交时使用的用户名'),
                trailing: const Icon(Icons.edit),
                onTap: () {
                  // TODO: 编辑用户名
                },
              ),
              ListTile(
                leading: const Icon(Icons.email),
                title: const Text('邮箱'),
                subtitle: const Text('Git提交时使用的邮箱'),
                trailing: const Icon(Icons.edit),
                onTap: () {
                  // TODO: 编辑邮箱
                },
              ),
              const SwitchListTile(
                secondary: Icon(Icons.security),
                title: Text('自动签名提交'),
                subtitle: Text('使用GPG密钥自动签名提交'),
                value: false,
                onChanged: null, // TODO: 实现GPG签名
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          _buildSettingsSection(
            context,
            '编辑器',
            [
              ListTile(
                leading: const Icon(Icons.format_size),
                title: const Text('字体大小'),
                subtitle: const Text('代码编辑器字体大小'),
                trailing: DropdownButton<int>(
                  value: 14,
                  items: const [
                    DropdownMenuItem(value: 12, child: Text('12')),
                    DropdownMenuItem(value: 14, child: Text('14')),
                    DropdownMenuItem(value: 16, child: Text('16')),
                    DropdownMenuItem(value: 18, child: Text('18')),
                  ],
                  onChanged: (value) {
                    // TODO: 实现字体大小切换
                  },
                ),
              ),
              const SwitchListTile(
                secondary: Icon(Icons.wrap_text),
                title: Text('自动换行'),
                subtitle: Text('在编辑器中自动换行长行'),
                value: true,
                onChanged: null, // TODO: 实现自动换行
              ),
              const SwitchListTile(
                secondary: Icon(Icons.format_indent_increase),
                title: Text('显示空白字符'),
                subtitle: Text('显示空格和制表符'),
                value: false,
                onChanged: null, // TODO: 实现显示空白字符
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          _buildSettingsSection(
            context,
            '关于',
            [
              const ListTile(
                leading: Icon(Icons.info),
                title: Text('版本'),
                subtitle: Text('1.0.0'),
              ),
              ListTile(
                leading: const Icon(Icons.code),
                title: const Text('开源许可'),
                subtitle: const Text('MIT License'),
                onTap: () {
                  // TODO: 显示许可证
                },
              ),
              ListTile(
                leading: const Icon(Icons.bug_report),
                title: const Text('报告问题'),
                subtitle: const Text('在GitHub上报告问题'),
                onTap: () {
                  // TODO: 打开GitHub issues
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(
    BuildContext context,
    String title,
    List<Widget> children,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }
}