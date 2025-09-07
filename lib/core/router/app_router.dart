import 'package:flutter/material.dart';
import '../../modules/git_manager/screens/home_screen.dart';
import '../../modules/git_manager/screens/repository_screen.dart';
import '../../modules/git_manager/screens/commit_history_screen.dart';
import '../../shared/screens/settings_screen.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// 创建GoRouter配置
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/repository',
        builder: (context, state) => const RepositoryScreen(),
      ),
      GoRoute(
        path: '/commit-history',
        builder: (context, state) => const CommitHistoryScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
  );
});
class AppRouter {
  static const String home = '/';
  static const String repository = '/repository';
  static const String commitHistory = '/commit-history';
  static const String settings = '/settings';
  
  static Route<dynamic> generateRoute(RouteSettings routeSettings) {
    switch (routeSettings.name) {
      case home:
        return MaterialPageRoute(
          builder: (_) => const HomeScreen(),
          settings: routeSettings,
        );
      
      case repository:
        return MaterialPageRoute(
          builder: (_) => const RepositoryScreen(),
          settings: routeSettings,
        );
      
      case commitHistory:
        return MaterialPageRoute(
          builder: (_) => const CommitHistoryScreen(),
          settings: routeSettings,
        );
      
      case settings:
        return MaterialPageRoute(
          builder: (_) => const SettingsScreen(),
          settings: routeSettings,
        );
      
      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(
              child: Text('Page not found'),
            ),
          ),
        );
    }
  }
  
  static void navigateTo(BuildContext context, String routeName, {Object? arguments}) {
    Navigator.pushNamed(context, routeName, arguments: arguments);
  }
  
  static void navigateAndReplace(BuildContext context, String routeName, {Object? arguments}) {
    Navigator.pushReplacementNamed(context, routeName, arguments: arguments);
  }
  
  static void navigateAndClearStack(BuildContext context, String routeName, {Object? arguments}) {
    Navigator.pushNamedAndRemoveUntil(
      context,
      routeName,
      (route) => false,
      arguments: arguments,
    );
  }
  
  static void goBack(BuildContext context) {
    Navigator.pop(context);
  }
}