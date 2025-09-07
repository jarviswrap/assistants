class AppConstants {
  // 应用信息
  static const String appName = 'Git Manager';
  static const String appVersion = '1.0.0';
  
  // 窗口设置
  static const double minWindowWidth = 800;
  static const double minWindowHeight = 600;
  static const double defaultWindowWidth = 1200;
  static const double defaultWindowHeight = 800;
  
  // Git 命令
  static const String gitCommand = 'git';
  
  // 文件过滤
  static const List<String> ignoredExtensions = [
    '.DS_Store',
    '.gitignore',
    'Thumbs.db',
  ];
  
  static const List<String> ignoredDirectories = [
    '.git',
    'node_modules',
    '.dart_tool',
    'build',
    '.idea',
    '.vscode',
  ];
  
  // UI 常量
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  
  static const double defaultBorderRadius = 8.0;
  static const double smallBorderRadius = 4.0;
  static const double largeBorderRadius = 12.0;
  
  // 动画时长
  static const Duration shortAnimationDuration = Duration(milliseconds: 200);
  static const Duration mediumAnimationDuration = Duration(milliseconds: 300);
  static const Duration longAnimationDuration = Duration(milliseconds: 500);
  
  // 颜色
  static const int primaryColorValue = 0xFF2196F3;
  static const int accentColorValue = 0xFF03DAC6;
  
  // 字体大小
  static const double smallFontSize = 12.0;
  static const double normalFontSize = 14.0;
  static const double largeFontSize = 16.0;
  static const double titleFontSize = 18.0;
  static const double headingFontSize = 20.0;
  
  // 设置键
  static const String settingsThemeMode = 'theme_mode';
  static const String settingsLastRepository = 'last_repository';
  static const String settingsWindowSize = 'window_size';
  static const String settingsWindowPosition = 'window_position';
  
  // 错误消息
  static const String errorNoRepository = 'No repository selected';
  static const String errorInvalidRepository = 'Invalid repository path';
  static const String errorGitNotFound = 'Git command not found';
  static const String errorPermissionDenied = 'Permission denied';
  static const String errorNetworkError = 'Network error';
}