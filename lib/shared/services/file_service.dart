import 'dart:io';
import 'package:path/path.dart' as path;

class FileService {
  // 获取目录下的所有文件和文件夹
  static Future<List<FileSystemEntity>> getDirectoryContents(
    String directoryPath, {
    bool recursive = false,
  }) async {
    try {
      final directory = Directory(directoryPath);
      if (!await directory.exists()) {
        return [];
      }

      final contents = <FileSystemEntity>[];
      
      if (recursive) {
        await for (final entity in directory.list(recursive: true)) {
          contents.add(entity);
        }
      } else {
        await for (final entity in directory.list()) {
          contents.add(entity);
        }
      }
      
      // 排序：文件夹在前，文件在后，按名称排序
      contents.sort((a, b) {
        final aIsDir = a is Directory;
        final bIsDir = b is Directory;
        
        if (aIsDir && !bIsDir) return -1;
        if (!aIsDir && bIsDir) return 1;
        
        return path.basename(a.path).compareTo(path.basename(b.path));
      });
      
      return contents;
    } catch (e) {
      print('Error getting directory contents: $e');
      return [];
    }
  }

  // 读取文件内容
  static Future<String?> readFileContent(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        return await file.readAsString();
      }
    } catch (e) {
      print('Error reading file: $e');
    }
    return null;
  }

  // 写入文件内容
  static Future<bool> writeFileContent(String filePath, String content) async {
    try {
      final file = File(filePath);
      await file.writeAsString(content);
      return true;
    } catch (e) {
      print('Error writing file: $e');
      return false;
    }
  }

  // 获取文件信息
  static Future<FileStat?> getFileStats(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        return await file.stat();
      }
    } catch (e) {
      print('Error getting file stats: $e');
    }
    return null;
  }

  // 检查路径是否存在
  static Future<bool> exists(String path) async {
    try {
      return await FileSystemEntity.isDirectory(path) ||
             await FileSystemEntity.isFile(path);
    } catch (e) {
      return false;
    }
  }

  // 获取文件扩展名
  static String getFileExtension(String filePath) {
    return path.extension(filePath).toLowerCase();
  }

  // 获取文件大小的可读格式
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  // 获取相对路径
  static String getRelativePath(String filePath, String basePath) {
    return path.relative(filePath, from: basePath);
  }

  // 检查文件是否为文本文件
  static bool isTextFile(String filePath) {
    final textExtensions = {
      '.txt', '.md', '.json', '.yaml', '.yml', '.xml', '.html', '.css',
      '.js', '.ts', '.dart', '.java', '.py', '.cpp', '.c', '.h',
      '.swift', '.kt', '.go', '.rs', '.php', '.rb', '.sh', '.bat',
      '.ps1', '.sql', '.r', '.scala', '.clj', '.hs', '.elm', '.vue',
      '.jsx', '.tsx', '.scss', '.less', '.styl', '.coffee', '.pug',
      '.ejs', '.hbs', '.mustache', '.twig', '.blade', '.erb', '.haml',
      '.slim', '.jade', '.stylus', '.sass', '.ini', '.cfg', '.conf',
      '.properties', '.env', '.gitignore', '.gitattributes', '.editorconfig',
      '.dockerignore', '.eslintrc', '.prettierrc', '.babelrc', '.npmrc',
      '.yarnrc', '.nvmrc', '.ruby-version', '.python-version', '.node-version',
    };
    
    final extension = getFileExtension(filePath);
    return textExtensions.contains(extension) || extension.isEmpty;
  }

  // 检查文件是否为图片
  static bool isImageFile(String filePath) {
    final imageExtensions = {
      '.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp', '.svg', '.ico',
      '.tiff', '.tif', '.psd', '.raw', '.cr2', '.nef', '.orf', '.sr2',
    };
    
    return imageExtensions.contains(getFileExtension(filePath));
  }

  // 创建目录
  static Future<bool> createDirectory(String directoryPath) async {
    try {
      final directory = Directory(directoryPath);
      await directory.create(recursive: true);
      return true;
    } catch (e) {
      print('Error creating directory: $e');
      return false;
    }
  }

  // 删除文件或目录
  static Future<bool> delete(String path) async {
    try {
      final entity = await FileSystemEntity.type(path);
      
      switch (entity) {
        case FileSystemEntityType.file:
          await File(path).delete();
          break;
        case FileSystemEntityType.directory:
          await Directory(path).delete(recursive: true);
          break;
        default:
          return false;
      }
      
      return true;
    } catch (e) {
      print('Error deleting: $e');
      return false;
    }
  }

  // 重命名文件或目录
  static Future<bool> rename(String oldPath, String newPath) async {
    try {
      final entity = await FileSystemEntity.type(oldPath);
      
      switch (entity) {
        case FileSystemEntityType.file:
          await File(oldPath).rename(newPath);
          break;
        case FileSystemEntityType.directory:
          await Directory(oldPath).rename(newPath);
          break;
        default:
          return false;
      }
      
      return true;
    } catch (e) {
      print('Error renaming: $e');
      return false;
    }
  }
}