import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Addr2LineService {
  static final Addr2LineService _instance = Addr2LineService._internal();
  static Addr2LineService get instance => _instance;
  Addr2LineService._internal();

  String? _androidSdkPath;
  String? _symbolDirectoryPath;  // 改为符号目录路径
  List<String> _symbolSoFilePaths = [];
  
  static const String _sdkPathKey = 'android_sdk_path';
  static const String _symbolDirectoryPathKey = 'symbol_directory_path';  // 新的key

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _androidSdkPath = prefs.getString(_sdkPathKey);
    _symbolDirectoryPath = prefs.getString(_symbolDirectoryPathKey);
  }

  Future<void> dispose() async {
    // 清理资源
  }

  /// 设置Android SDK路径
  Future<void> setAndroidSdkPath(String path) async {
    _androidSdkPath = path;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sdkPathKey, path);
  }

  /// 设置符号目录路径
  Future<void> setSymbolDirectoryPath(String path) async {
    _symbolDirectoryPath = path;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_symbolDirectoryPathKey, path);
  }

  /// 从崩溃堆栈中解析出需要的.so文件名
  List<String> _extractSoNamesFromStack(String stackTrace) {
    final soNames = <String>{};
    final lines = stackTrace.split('\n');
    
    // 正则表达式匹配堆栈帧中的.so文件
    final frameRegex = RegExp(r'#\d+\s+pc\s+[0-9a-fA-F]+\s+(.+\.so)');
    final libRegex = RegExp(r'(/system/lib|/vendor/lib|/data/app).*/([^/]+\.so)');
    
    for (final line in lines) {
      final frameMatch = frameRegex.firstMatch(line.trim());
      if (frameMatch != null) {
        final libPath = frameMatch.group(1) ?? '';
        final libMatch = libRegex.firstMatch(libPath);
        if (libMatch != null) {
          soNames.add(libMatch.group(2)!);
        } else if (libPath.endsWith('.so')) {
          // 直接提取文件名
          final fileName = libPath.split('/').last;
          if (fileName.endsWith('.so')) {
            soNames.add(fileName);
          }
        }
      }
    }
    
    return soNames.toList();
  }

  /// 在符号目录中查找指定的.so文件
  Future<List<String>> _findSoFilesInDirectory(List<String> soNames) async {
    if (_symbolDirectoryPath == null || soNames.isEmpty) return [];
    
    final foundFilesMap = <String, List<File>>{}; // 按文件名分组
    final directory = Directory(_symbolDirectoryPath!);
    
    if (!directory.existsSync()) return [];
    
    try {
      await for (final entity in directory.list(recursive: true)) {
        if (entity is File && entity.path.endsWith('.so')) {
          final fileName = entity.path.split('/').last;
          if (soNames.contains(fileName)) {
            foundFilesMap.putIfAbsent(fileName, () => []).add(entity);
          }
        }
      }
    } catch (e) {
      print('扫描符号目录时出错: $e');
    }
    
    final selectedFiles = <String>[];
    
    // 对每个文件名的文件列表进行排序，选择最优的文件
    for (final entry in foundFilesMap.entries) {
      final files = entry.value;
      
      if (files.length == 1) {
        selectedFiles.add(files.first.path);
      } else {
        // 多个同名文件，按修改时间和文件大小排序
        files.sort((a, b) {
          final aStat = a.statSync();
          final bStat = b.statSync();
          
          // 首先按修改时间排序（最新的在前）
          final timeComparison = bStat.modified.compareTo(aStat.modified);
          if (timeComparison != 0) {
            return timeComparison;
          }
          
          // 修改时间相同时，按文件大小排序（最大的在前）
          return bStat.size.compareTo(aStat.size);
        });
        
        // 选择排序后的第一个文件（修改时间最新且文件最大的）
        selectedFiles.add(files.first.path);
        
        print('发现多个同名符号文件 ${entry.key}，选择: ${files.first.path}');
      }
    }
    
    return selectedFiles;
  }

  /// 自动查找并更新符号文件（基于堆栈内容）
  Future<List<String>> autoFindSymbolFiles(String stackTrace) async {
    // 第一步：从崩溃堆栈中解析出.so文件名
    final soNames = _extractSoNamesFromStack(stackTrace);
    print('从堆栈中解析出的.so文件: $soNames');
    
    // 第二步：在符号目录中查找这些.so文件
    final foundFiles = await _findSoFilesInDirectory(soNames);
    print('在符号目录中找到的文件: $foundFiles');
    
    // 更新符号文件列表
    _symbolSoFilePaths = foundFiles;
    
    return foundFiles;
  }

  String? get androidSdkPath => _androidSdkPath;

  /// 获取当前配置的符号文件路径列表
  List<String> get symbolSoFiles => List.unmodifiable(_symbolSoFilePaths);

/// 获取当前配置的符号目录路径
  String? get symbolDirectoryPath => _symbolDirectoryPath;

  /// 检测地址是32位还是64位
  bool _is64BitAddress(String address) {
    // 移除0x前缀
    final cleanAddress = address.replaceFirst('0x', '');
    // 64位地址通常长度大于8个字符
    return cleanAddress.length > 8;
  }

  /// 查找对应架构的addr2line工具
  String? _findAddr2LineTool(bool is64Bit) {
    if (_androidSdkPath == null) return null;

    final ndkPath = Directory('$_androidSdkPath/ndk');
    if (!ndkPath.existsSync()) return null;

    // 查找最新的NDK版本
    final ndkVersions = ndkPath.listSync()
        .where((entity) => entity is Directory)
        .map((entity) => entity.path)
        .toList();
    
    if (ndkVersions.isEmpty) return null;
    
    // 使用最新版本的NDK
    ndkVersions.sort();
    final latestNdk = ndkVersions.last;

    // 根据架构查找addr2line
    final architecture = is64Bit ? 'aarch64' : 'arm';
    final toolchainPrefix = is64Bit 
        ? 'aarch64-linux-android'
        : 'arm-linux-androideabi';

    // 可能的工具链路径
    final possiblePaths = [
      '$latestNdk/toolchains/llvm/prebuilt/darwin-x86_64/bin/$toolchainPrefix-addr2line',
      '$latestNdk/toolchains/llvm/prebuilt/linux-x86_64/bin/$toolchainPrefix-addr2line',
      '$latestNdk/toolchains/llvm/prebuilt/windows-x86_64/bin/$toolchainPrefix-addr2line.exe',
      '$latestNdk/toolchains/$architecture-4.9/prebuilt/darwin-x86_64/bin/$toolchainPrefix-addr2line',
      '$latestNdk/toolchains/$architecture-4.9/prebuilt/linux-x86_64/bin/$toolchainPrefix-addr2line',
    ];

    for (final path in possiblePaths) {
      if (File(path).existsSync()) {
        return path;
      }
    }

    return null;
  }

  /// 符号化单个地址
  Future<String?> symbolizeAddress(String address) async {
    if (_symbolSoFilePaths.isEmpty) {
      throw Exception('符号文件路径未设置');
    }

    final is64Bit = _is64BitAddress(address);
    final addr2linePath = _findAddr2LineTool(is64Bit);
    
    if (addr2linePath == null) {
      throw Exception('未找到对应架构的addr2line工具');
    }

    // 尝试每个符号文件，直到找到有效的符号化结果
    for (final symbolFilePath in _symbolSoFilePaths) {
      if (!File(symbolFilePath).existsSync()) {
        continue;
      }

      try {
        final result = await Process.run(
          addr2linePath,
          ['-e', symbolFilePath, '-f', '-C', address],
          stdoutEncoding: utf8,
          stderrEncoding: utf8,
        );

        if (result.exitCode == 0) {
          final output = result.stdout.toString().trim();
          final lines = output.split('\n');
          if (lines.length >= 2) {
            final functionName = lines[0];
            final location = lines[1];
            // 检查是否是有效的符号化结果（不是??:0这样的无效结果）
            if (!functionName.startsWith('??') && !location.contains('??:0')) {
              return '$functionName at $location (${symbolFilePath.split('/').last})';
            }
          }
        }
      } catch (e) {
        debugPrint('使用符号文件 $symbolFilePath 时出错: $e');
        continue;
      }
    }

    return null;
  }

  /// 符号化整个堆栈
  Future<List<SymbolizedFrame>> symbolizeStack(String stackTrace) async {
    final frames = <SymbolizedFrame>[];
    final lines = stackTrace.split('\n');
    
    // 正则表达式匹配堆栈帧格式
    final frameRegex = RegExp(r'#\d+\s+pc\s+([0-9a-fA-F]+)\s+(.+)');
    
    for (final line in lines) {
      final match = frameRegex.firstMatch(line.trim());
      if (match != null) {
        final address = '0x${match.group(1)}';
        final library = match.group(2) ?? '';
        
        try {
          final symbolized = await symbolizeAddress(address);
          frames.add(SymbolizedFrame(
            originalLine: line,
            address: address,
            library: library,
            symbolizedInfo: symbolized,
          ));
        } catch (e) {
          frames.add(SymbolizedFrame(
            originalLine: line,
            address: address,
            library: library,
            symbolizedInfo: null,
            error: e.toString(),
          ));
        }
      } else {
        // 非堆栈帧行，直接保留
        frames.add(SymbolizedFrame(
          originalLine: line,
          address: null,
          library: null,
          symbolizedInfo: null,
        ));
      }
    }
    
    return frames;
  }

  /// 验证配置是否有效
  Future<bool> validateConfiguration() async {
    if (_androidSdkPath == null || _symbolDirectoryPath == null) {
      return false;
    }

    // 检查SDK路径
    if (!Directory(_androidSdkPath!).existsSync() || !Directory(_symbolDirectoryPath!).existsSync()) {
      return false;
    }

    // 检查至少有一个有效的符号文件
    bool hasValidSymbolFile = false;
    for (final path in _symbolSoFilePaths) {
      if (File(path).existsSync()) {
        hasValidSymbolFile = true;
        break;
      }
    }
    
    if (!hasValidSymbolFile) {
      return false;
    }

    // 尝试查找addr2line工具
    final has32BitTool = _findAddr2LineTool(false) != null;
    final has64BitTool = _findAddr2LineTool(true) != null;
    
    return has32BitTool || has64BitTool;
  }

  /// 删除指定的符号文件
  void removeSymbolFile(String filePath) {
    _symbolSoFilePaths.remove(filePath);
  }
  
  /// 清空所有符号文件
  void clearSymbolFiles() {
    _symbolSoFilePaths.clear();
  }
}

/// 符号化后的堆栈帧
class SymbolizedFrame {
  final String originalLine;
  final String? address;
  final String? library;
  final String? symbolizedInfo;
  final String? error;

  SymbolizedFrame({
    required this.originalLine,
    this.address,
    this.library,
    this.symbolizedInfo,
    this.error,
  });

  bool get isSymbolized => symbolizedInfo != null;
  bool get hasError => error != null;
}

  