import 'package:flutter_riverpod/flutter_riverpod.dart';

// 侧边栏状态提供者
final sidebarExpandedProvider = StateProvider<bool>((ref) => true);

// 侧边栏宽度常量
class SidebarConstants {
  static const double expandedWidth = 220.0;
  static const double collapsedWidth = 72.0;
  static const Duration animationDuration = Duration(milliseconds: 300);
}