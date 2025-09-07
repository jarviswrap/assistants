import 'dart:io';
import 'package:path/path.dart' as path;

class FileUtils {
  /// 获取目录下的所有文件和文件夹
  static Future<List<FileSystemEntity>> getDirectoryContents(String dirPath) async {
    try {
      final directory = Directory(dirPath);
      if (!await directory.exists()) {
        return [];
      }
      
      final contents = await directory.list().toList();
      contents.sort((a, b) {
        // 文件夹排在前面
        if (a is Directory && b is File) return -1;
        if (a is File && b is Directory) return 1;
        return path.basename(a.path).toLowerCase()
            .compareTo(path.basename(b.path).toLowerCase());
      });
      
      return contents;
    } catch (e) {
      return [];
    }
  }

  /// 检查文件是否存在
  static Future<bool> fileExists(String filePath) async {
    return await File(filePath).exists();
  }

  /// 检查目录是否存在
  static Future<bool> directoryExists(String dirPath) async {
    return await Directory(dirPath).exists();
  }

  /// 创建目录
  static Future<bool> createDirectory(String dirPath) async {
    try {
      await Directory(dirPath).create(recursive: true);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// 读取文件内容
  static Future<String?> readFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        return await file.readAsString();
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// 写入文件内容
  static Future<bool> writeFile(String filePath, String content) async {
    try {
      final file = File(filePath);
      await file.writeAsString(content);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// 获取文件大小
  static Future<int> getFileSize(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        return await file.length();
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  /// 获取文件修改时间
  static Future<DateTime?> getFileModifiedTime(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        final stat = await file.stat();
        return stat.modified;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// 获取相对路径
  static String getRelativePath(String basePath, String targetPath) {
    return path.relative(targetPath, from: basePath);
  }

  /// 获取文件名（不含扩展名）
  static String getFileNameWithoutExtension(String filePath) {
    return path.basenameWithoutExtension(filePath);
  }

  /// 获取文件扩展名
  static String getFileExtension(String filePath) {
    return path.extension(filePath);
  }

  /// 检查路径是否为隐藏文件/文件夹
  static bool isHidden(String filePath) {
    final name = path.basename(filePath);
    return name.startsWith('.');
  }

  /// 过滤隐藏文件
  static List<FileSystemEntity> filterHidden(List<FileSystemEntity> entities) {
    return entities.where((entity) => !isHidden(entity.path)).toList();
  }
}