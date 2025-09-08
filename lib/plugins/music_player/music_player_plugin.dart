import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/plugins/base_plugin.dart';
import '../../core/plugins/plugin_interface.dart';
import 'screens/music_player_home_screen.dart';
import 'screens/playlist_screen.dart';
import 'screens/now_playing_screen.dart';

class MusicPlayerPlugin extends BasePlugin {
  @override
  PluginMetadata get metadata => const PluginMetadata(
    id: 'music_player',
    name: '音乐播放器',
    description: '本地音乐播放和管理工具',
    version: '1.0.0',
    icon: Icons.music_note,
  );

  @override
  List<PluginPermission> get requiredPermissions => [
    PluginPermission.fileSystem, 
    PluginPermission.storage
  ];

  @override
  List<GoRoute> get routes => [
    GoRoute(
      path: '/music-player',
      builder: (context, state) => const MusicPlayerHomeScreen(),
      routes: [
        GoRoute(
          path: '/playlist/:playlistId',
          builder: (context, state) => PlaylistScreen(
            playlistId: state.pathParameters['playlistId'] ?? '',
          ),
        ),
        GoRoute(
          path: '/now-playing',
          builder: (context, state) => const NowPlayingScreen(),
        ),
      ],
    ),
  ];

  @override
  List<PluginMenuItem> get menuItems => [
    PluginMenuItem(
      label: '音乐播放器',
      icon: Icons.music_note,
      route: '/music-player',
      subItems: [
        PluginMenuItem(
          label: '播放列表',
          icon: Icons.playlist_play,
          route: '/music-player/playlist/default',
        ),
        PluginMenuItem(
          label: '正在播放',
          icon: Icons.play_circle,
          route: '/music-player/now-playing',
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
          Text('音乐播放器设置', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          const Text('这里可以配置音乐播放器的相关设置'),
        ],
      ),
    ),
  );

  @override
  Future<void> onInitialize() async {
    // 初始化音乐播放器
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