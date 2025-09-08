import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Addr2LineService {
  static final Addr2LineService _instance = Addr2LineService._internal();
  static Addr2LineService get instance => _instance;
  Addr2LineService._internal();

  String? _androidSdkPath;
  List<String> _symbolFilePaths = [];
  
  static const String _sdkPathKey = 'android_sdk_path';
  static const String _symbolFilePathsKey = 'symbol_file_paths';

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _androidSdkPath = prefs.getString(_sdkPathKey);
    _symbolFilePaths = prefs.getStringList(_symbolFilePathsKey) ?? [];
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

  /// 添加符号文件路径
  Future<void> addSymbolFilePath(String path) async {
    if (!_symbolFilePaths.contains(path)) {
      _symbolFilePaths.add(path);
      await _saveSymbolFilePaths();
    }
  }

  /// 移除符号文件路径
  Future<void> removeSymbolFilePath(String path) async {
    _symbolFilePaths.remove(path);
    await _saveSymbolFilePaths();
  }

  /// 清空所有符号文件路径
  Future<void> clearSymbolFilePaths() async {
    _symbolFilePaths.clear();
    await _saveSymbolFilePaths();
  }

  /// 保存符号文件路径列表
  Future<void> _saveSymbolFilePaths() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_symbolFilePathsKey, _symbolFilePaths);
  }

  /// 获取当前配置的SDK路径
  String? get androidSdkPath => _androidSdkPath;

  /// 获取当前配置的符号文件路径列表
  List<String> get symbolFilePaths => List.unmodifiable(_symbolFilePaths);

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
    if (_symbolFilePaths.isEmpty) {
      throw Exception('符号文件路径未设置');
    }

    final is64Bit = _is64BitAddress(address);
    final addr2linePath = _findAddr2LineTool(is64Bit);
    
    if (addr2linePath == null) {
      throw Exception('未找到对应架构的addr2line工具');
    }

    // 尝试每个符号文件，直到找到有效的符号化结果
    for (final symbolFilePath in _symbolFilePaths) {
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
    if (_androidSdkPath == null || _symbolFilePaths.isEmpty) {
      return false;
    }

    // 检查SDK路径
    if (!Directory(_androidSdkPath!).existsSync()) {
      return false;
    }

    // 检查至少有一个有效的符号文件
    bool hasValidSymbolFile = false;
    for (final path in _symbolFilePaths) {
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