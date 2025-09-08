import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Addr2LineService {
  static final Addr2LineService _instance = Addr2LineService._internal();
  static Addr2LineService get instance => _instance;
  Addr2LineService._internal();

  String? _androidSdkPath;
  String? _symbolFilePath;
  
  static const String _sdkPathKey = 'android_sdk_path';
  static const String _symbolFilePathKey = 'symbol_file_path';

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _androidSdkPath = prefs.getString(_sdkPathKey);
    _symbolFilePath = prefs.getString(_symbolFilePathKey);
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

  /// 设置符号文件路径
  Future<void> setSymbolFilePath(String path) async {
    _symbolFilePath = path;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_symbolFilePathKey, path);
  }

  /// 获取当前配置的SDK路径
  String? get androidSdkPath => _androidSdkPath;

  /// 获取当前配置的符号文件路径
  String? get symbolFilePath => _symbolFilePath;

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
    if (_symbolFilePath == null || !File(_symbolFilePath!).existsSync()) {
      throw Exception('符号文件路径未设置或文件不存在');
    }

    final is64Bit = _is64BitAddress(address);
    final addr2linePath = _findAddr2LineTool(is64Bit);
    
    if (addr2linePath == null) {
      throw Exception('未找到对应架构的addr2line工具');
    }

    try {
      final result = await Process.run(
        addr2linePath,
        ['-e', _symbolFilePath!, '-f', '-C', address],
        stdoutEncoding: utf8,
        stderrEncoding: utf8,
      );

      if (result.exitCode == 0) {
        final output = result.stdout.toString().trim();
        final lines = output.split('\n');
        if (lines.length >= 2) {
          final functionName = lines[0];
          final location = lines[1];
          return '$functionName at $location';
        }
        return output;
      } else {
        debugPrint('addr2line error: ${result.stderr}');
        return null;
      }
    } catch (e) {
      debugPrint('执行addr2line时出错: $e');
      return null;
    }
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
    if (_androidSdkPath == null || _symbolFilePath == null) {
      return false;
    }

    // 检查SDK路径
    if (!Directory(_androidSdkPath!).existsSync()) {
      return false;
    }

    // 检查符号文件
    if (!File(_symbolFilePath!).existsSync()) {
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