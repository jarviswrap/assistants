import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/themes/app_theme.dart';
import 'core/router/dynamic_router.dart';

void main() {
  runApp(
    const ProviderScope(
      child: AssistantsApp(),
    ),
  );
}

class AssistantsApp extends ConsumerWidget {
  const AssistantsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pluginInitialization = ref.watch(pluginInitializationProvider);
    
    return pluginInitialization.when(
      data: (success) {
        final router = ref.watch(dynamicRouterProvider);
        return MaterialApp.router(
          title: 'Assistants',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.system,
          routerConfig: router,
          debugShowCheckedModeBanner: false,
        );
      },
      loading: () => MaterialApp(
        title: 'Assistants',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: const Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('正在初始化插件...'),
              ],
            ),
          ),
        ),
        debugShowCheckedModeBanner: false,
      ),
      error: (error, stack) => MaterialApp(
        title: 'Assistants',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error, color: Colors.red, size: 48),
                SizedBox(height: 16),
                Text('插件初始化失败: $error'),
              ],
            ),
          ),
        ),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}