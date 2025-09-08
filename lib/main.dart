import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';
import 'core/router/dynamic_router.dart';
import 'core/themes/app_theme.dart';
import 'core/plugins/plugin_manager.dart';
import 'plugins/git_manager/git_manager_plugin.dart';
import 'plugins/music_player/music_player_plugin.dart';
import 'plugins/daily_report/daily_report_plugin.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 配置桌面窗口
  await windowManager.ensureInitialized();
  
  const WindowOptions windowOptions = WindowOptions(
    size: Size(1200, 800),
    minimumSize: Size(800, 600),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.normal,
    title: 'Assistants',
  );
  
  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });
  
  runApp(const ProviderScope(child: AssistantsApp()));
}

class AssistantsApp extends ConsumerStatefulWidget {
  const AssistantsApp({super.key});

  @override
  ConsumerState<AssistantsApp> createState() => _AssistantsAppState();
}

class _AssistantsAppState extends ConsumerState<AssistantsApp> {
  @override
  void initState() {
    super.initState();
    _initializePlugins();
  }

  Future<void> _initializePlugins() async {
    final pluginManager = ref.read(pluginManagerProvider);
    
    try {
      // 注册所有插件
      await pluginManager.registerPlugin(GitManagerPlugin());
      await pluginManager.registerPlugin(MusicPlayerPlugin());
      await pluginManager.registerPlugin(DailyReportPlugin());
      
      debugPrint('All plugins registered successfully');
    } catch (e) {
      debugPrint('Failed to register plugins: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(dynamicRouterProvider);
    
    return MaterialApp.router(
      title: 'Assistants',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}