import '../modules/git_manager/git_manager_module.dart';

class ModuleRegistry {
  static final List<dynamic> modules = [
    GitManagerModule,
    // 未来添加其他模块
    // MusicPlayerModule,
    // DocumentManagerModule,
  ];
  
  static List<RouteBase> getAllRoutes() {
    final List<RouteBase> allRoutes = [];
    for (final module in modules) {
      allRoutes.addAll(module.routes);
    }
    return allRoutes;
  }
}