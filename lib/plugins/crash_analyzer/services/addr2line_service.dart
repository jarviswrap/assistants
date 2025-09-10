import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Addr2LineService {
  static final Addr2LineService _instance = Addr2LineService._internal();
  static Addr2LineService get instance => _instance;
  Addr2LineService._internal();

  String? _androidSdkPath;
  String? _symbolDirectoryPath;
  List<String> _symbolSoFilePaths = [];
  
  // 添加权限问题回调
  Function(String message)? onPermissionError;
  
  static const String _sdkPathKey = 'android_sdk_path';
  static const String _symbolDirectoryPathKey = 'symbol_directory_path';

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

  /// 验证SDK目录是否可访问
  Future<bool> _validateSdkDirectoryAccess() async {
    if (_androidSdkPath == null) return false;
    
    final directory = Directory(_androidSdkPath!);
    if (!directory.existsSync()) return false;
    
    try {
      // 尝试列出目录内容来验证访问权限
      await directory.list(recursive: false).take(1).toList();
      
      // 特别检查NDK目录的访问权限
      final ndkPath = Directory('$_androidSdkPath/ndk');
      if (ndkPath.existsSync()) {
        await ndkPath.list(recursive: false).take(1).toList();
      }
      
      return true;
    } catch (e) {
      print('SDK目录访问验证失败: $e');
      if (e.toString().contains('Operation not permitted') || 
          e.toString().contains('Permission denied')) {
        onPermissionError?.call('无法访问Android SDK目录，请重新选择有权限的SDK路径');
      }
      return false;
    }
  }

  /// 验证符号目录是否可访问
  Future<bool> _validateSymbolDirectoryAccess() async {
    if (_symbolDirectoryPath == null) return false;
    
    final directory = Directory(_symbolDirectoryPath!);
    if (!directory.existsSync()) return false;
    
    try {
      // 尝试列出目录内容来验证访问权限
      await directory.list(recursive: false).take(1).toList();
      return true;
    } catch (e) {
      print('符号目录访问验证失败: $e');
      return false;
    }
  }

  /// 在符号目录中查找指定的.so文件
  Future<List<String>> _findSoFilesInDirectory(List<String> soNames) async {
    if (_symbolDirectoryPath == null || soNames.isEmpty) return [];
    
    final foundFilesMap = <String, List<File>>{};
    final directory = Directory(_symbolDirectoryPath!);
    
    try {
      if (!directory.existsSync()) {
        onPermissionError?.call('符号目录不存在，请重新选择目录');
        return [];
      }
      
      // 尝试访问目录
      await directory.list(recursive: false).take(1).toList();
      
      // 递归遍历目录查找.so文件
      await for (final entity in directory.list(recursive: true)) {
        if (entity is File && entity.path.endsWith('.so')) {
          final fileName = entity.path.split('/').last;
          
          // 检查是否是我们需要的.so文件
          for (final soName in soNames) {
            if (fileName == soName || fileName.contains(soName)) {
              foundFilesMap.putIfAbsent(soName, () => []).add(entity);
            }
          }
        }
      }
      
      // 对每个文件名的文件列表进行排序，选择最优的文件
      final result = <String>[];
      for (final entry in foundFilesMap.entries) {
        final files = entry.value;
        if (files.isNotEmpty) {
          
          // 首先按修改时间排序（最新的优先）
          files.sort((a, b) {
            final aStats = a.statSync();
            final bStats = b.statSync();
            return bStats.modified.compareTo(aStats.modified);
          });
          
          // 找到最新的时间戳
          final latestTime = files.first.statSync().modified;
          
          // 筛选出与最新时间戳相差在1秒内的文件
          final candidateFiles = files.where((file) {
            final fileTime = file.statSync().modified;
            final timeDifference = latestTime.difference(fileTime).inMilliseconds.abs();
            return timeDifference <= 10000; // 1秒 = 1000毫秒
          }).toList();
          
          if (candidateFiles.length == 1) {
            // 如果只有一个候选文件，直接使用
            result.add(candidateFiles.first.path);
          } else {
            // 在候选文件中按文件大小排序（大的优先）
            candidateFiles.sort((a, b) {
              final aSize = a.statSync().size;
              final bSize = b.statSync().size;
              return bSize.compareTo(aSize);
            });
            
            // 找到最大的文件大小
            final maxSize = candidateFiles.first.statSync().size;
            
            // 找出所有具有最大文件大小的文件
            final maxSizeFiles = candidateFiles.where((file) {
              return file.statSync().size == maxSize;
            }).toList();
            
            // 将所有最大体积的文件都添加到结果中
            result.addAll(maxSizeFiles.map((file) => file.path));
          }
        }
      }
      
      return result;
      
    } catch (e) {
      if (e.toString().contains('Operation not permitted') || 
          e.toString().contains('Permission denied')) {
        onPermissionError?.call('无法访问符号目录，请重新选择有权限的目录');
      } else {
        print('扫描符号目录时出错: $e');
        onPermissionError?.call('扫描符号目录时出错，请重新选择目录');
      }
      return [];
    }
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

    try {
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
    } catch (e) {
      if (e.toString().contains('Operation not permitted') || 
          e.toString().contains('Permission denied')) {
        onPermissionError?.call('无法访问Android SDK目录，请重新选择有权限的SDK路径');
      } else {
        print('访问SDK目录时出错: $e');
      }
      return null;
    }
  }

  /// 符号化单个地址
  Future<String?> symbolizeAddress(String address) async {
    print('开始符号化地址: $address');
    
    if (_symbolSoFilePaths.isEmpty) {
      print('错误: 符号文件路径未设置');
      throw Exception('符号文件路径未设置');
    }

    final is64Bit = _is64BitAddress(address);
    print('检测到地址架构: ${is64Bit ? "64位" : "32位"}');
    
    final addr2linePath = _findAddr2LineTool(is64Bit);
    print('使用的addr2line工具路径: $addr2linePath');
    
    if (addr2linePath == null) {
      print('错误: 未找到对应架构的addr2line工具');
      throw Exception('未找到对应架构的addr2line工具');
    }

    print('可用的符号文件数量: ${_symbolSoFilePaths.length}');
    
    // 尝试每个符号文件，直到找到有效的符号化结果
    for (int i = 0; i < _symbolSoFilePaths.length; i++) {
      final symbolFilePath = _symbolSoFilePaths[i];
      print('尝试符号文件 ${i + 1}/${_symbolSoFilePaths.length}: ${symbolFilePath.split('/').last}');
      
      if (!File(symbolFilePath).existsSync()) {
        print('  文件不存在，跳过');
        continue;
      }

      try {
        print('  执行命令: $addr2linePath -e $symbolFilePath -f -C $address');
        
        final result = await Process.run(
          addr2linePath,
          ['-e', symbolFilePath, '-f', '-C', address],
          stdoutEncoding: utf8,
          stderrEncoding: utf8,
        );

        print('  命令退出码: ${result.exitCode}');
        print('  标准输出: ${result.stdout.toString().trim()}');
        if (result.stderr.toString().isNotEmpty) {
          print('  标准错误: ${result.stderr.toString().trim()}');
        }

        if (result.exitCode == 0) {
          final output = result.stdout.toString().trim();
          final lines = output.split('\n');
          if (lines.length >= 2) {
            final functionName = lines[0];
            final location = lines[1];
            print('  解析结果 - 函数名: $functionName, 位置: $location');
            
            // 检查是否是有效的符号化结果（不是??:0这样的无效结果）
            if (!functionName.startsWith('??') && !location.contains('??:0')) {
              final result = '$functionName at $location (${symbolFilePath.split('/').last})';
              print('  符号化成功: $result');
              return result;
            } else {
              print('  符号化结果无效（包含??），继续尝试下一个文件');
            }
          } else {
            print('  输出行数不足，继续尝试下一个文件');
          }
        } else {
          print('  命令执行失败，继续尝试下一个文件');
        }
      } catch (e) {
        print('  使用符号文件时出错: $e');
        debugPrint('使用符号文件 $symbolFilePath 时出错: $e');
        continue;
      }
    }

    print('所有符号文件都尝试完毕，未找到有效的符号化结果');
    return null;
  }

  /// 符号化整个堆栈
  Future<List<SymbolizedFrame>> symbolizeStack(String stackTrace) async {
    print('开始符号化堆栈，总行数: ${stackTrace.split('\n').length}');
    
    final frames = <SymbolizedFrame>[];
    final lines = stackTrace.split('\n');
    
    // 正则表达式匹配堆栈帧格式
    final frameRegex = RegExp(r'#\d+\s+pc\s+([0-9a-fA-F]+)\s+(.+)');
    
    int frameCount = 0;
    int successCount = 0;
    int errorCount = 0;
    
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      print('处理第${i + 1}行: ${line.trim()}');
      
      final match = frameRegex.firstMatch(line.trim());
      if (match != null) {
        frameCount++;
        final address = '0x${match.group(1)}';
        final library = match.group(2) ?? '';
        
        print('  匹配到堆栈帧 #$frameCount - 地址: $address, 库: $library');
        
        try {
          final symbolized = await symbolizeAddress(address);
          if (symbolized != null) {
            successCount++;
            print('  符号化成功: $symbolized');
          } else {
            print('  符号化失败: 未找到符号信息');
          }
          
          frames.add(SymbolizedFrame(
            originalLine: line,
            address: address,
            library: library,
            symbolizedInfo: symbolized,
          ));
        } catch (e) {
          errorCount++;
          print('  符号化出错: $e');
          
          frames.add(SymbolizedFrame(
            originalLine: line,
            address: address,
            library: library,
            symbolizedInfo: null,
            error: e.toString(),
          ));
        }
      } else {
        print('  非堆栈帧行，直接保留');
        // 非堆栈帧行，直接保留
        frames.add(SymbolizedFrame(
          originalLine: line,
          address: null,
          library: null,
          symbolizedInfo: null,
        ));
      }
    }
    
    print('堆栈符号化完成统计:');
    print('  总行数: ${lines.length}');
    print('  堆栈帧数: $frameCount');
    print('  符号化成功: $successCount');
    print('  符号化出错: $errorCount');
    print('  成功率: ${frameCount > 0 ? (successCount / frameCount * 100).toStringAsFixed(1) : 0}%');
    
    return frames;
  }

  /// 验证配置是否有效
  Future<bool> validateConfiguration() async {
    print('开始验证配置...');
    
    print('检查基本路径配置:');
    print('  Android SDK路径: $_androidSdkPath');
    print('  符号目录路径: $_symbolDirectoryPath');
    
    if (_androidSdkPath == null || _symbolDirectoryPath == null) {
      print('  配置验证失败: 基本路径未设置');
      return false;
    }

    // 检查SDK路径
    print('检查目录是否存在:');
    final sdkExists = Directory(_androidSdkPath!).existsSync();
    final symbolDirExists = Directory(_symbolDirectoryPath!).existsSync();
    
    print('  Android SDK目录存在: $sdkExists');
    print('  符号目录存在: $symbolDirExists');
    
    if (!sdkExists || !symbolDirExists) {
      print('  配置验证失败: 目录不存在');
      return false;
    }

    // 验证SDK目录访问权限
    print('验证SDK目录访问权限:');
    final sdkAccessible = await _validateSdkDirectoryAccess();
    print('  SDK目录可访问: $sdkAccessible');
    
    if (!sdkAccessible) {
      print('  配置验证失败: SDK目录无访问权限');
      return false;
    }

    // 检查至少有一个有效的符号文件
    print('检查符号文件:');
    print('  符号文件总数: ${_symbolSoFilePaths.length}');
    
    bool hasValidSymbolFile = false;
    int validFileCount = 0;
    
    for (int i = 0; i < _symbolSoFilePaths.length; i++) {
      final path = _symbolSoFilePaths[i];
      final exists = File(path).existsSync();
      print('  文件${i + 1}: ${path.split('/').last} - 存在: $exists');
      
      if (exists) {
        hasValidSymbolFile = true;
        validFileCount++;
      }
    }
    
    print('  有效符号文件数量: $validFileCount');
    
    if (!hasValidSymbolFile) {
      print('  配置验证失败: 没有有效的符号文件');
      return false;
    }

    // 尝试查找addr2line工具
    print('检查addr2line工具:');
    final tool32Path = _findAddr2LineTool(false);
    final tool64Path = _findAddr2LineTool(true);
    
    final has32BitTool = tool32Path != null;
    final has64BitTool = tool64Path != null;
    
    print('  32位工具路径: ${tool32Path ?? "未找到"}');
    print('  64位工具路径: ${tool64Path ?? "未找到"}');
    print('  32位工具可用: $has32BitTool');
    print('  64位工具可用: $has64BitTool');
    
    final isValid = has32BitTool || has64BitTool;
    
    if (isValid) {
      print('配置验证成功 ✓');
    } else {
      print('配置验证失败: 未找到可用的addr2line工具');
    }
    
    return isValid;
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

  