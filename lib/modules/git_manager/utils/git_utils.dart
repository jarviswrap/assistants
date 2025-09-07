import 'dart:io';
import '../models/git_models.dart';

class GitUtils {
  /// 检查目录是否为Git仓库
  static bool isGitRepository(String path) {
    final gitDir = Directory('$path/.git');
    return gitDir.existsSync();
  }

  /// 获取Git仓库根目录
  static String? getGitRoot(String path) {
    Directory current = Directory(path);
    
    while (current.path != current.parent.path) {
      if (isGitRepository(current.path)) {
        return current.path;
      }
      current = current.parent;
    }
    
    return null;
  }

  /// 解析Git状态输出
  static List<GitFile> parseGitStatus(String output) {
    final files = <GitFile>[];
    final lines = output.split('\n');
    
    for (final line in lines) {
      if (line.trim().isEmpty) continue;
      
      if (line.length >= 3) {
        final statusCode = line.substring(0, 2);
        final filePath = line.substring(3);
        final status = _parseStatusCode(statusCode);
        
        files.add(GitFile(
          path: filePath,
          name: filePath.split('/').last,
          status: status,
          isDirectory: false,
        ));
      }
    }
    
    return files;
  }

  /// 解析Git分支输出
  static List<GitBranch> parseGitBranches(String output) {
    final branches = <GitBranch>[];
    final lines = output.split('\n');
    
    for (final line in lines) {
      if (line.trim().isEmpty) continue;
      
      final trimmed = line.trim();
      final isCurrent = trimmed.startsWith('*');
      final branchName = isCurrent ? trimmed.substring(2) : trimmed;
      final isRemote = branchName.contains('remotes/');
      
      branches.add(GitBranch(
        name: isRemote ? branchName.split('/').last : branchName,
        isCurrent: isCurrent,
        isRemote: isRemote,
      ));
    }
    
    return branches;
  }

  /// 解析Git提交历史输出
  static List<GitCommit> parseGitLog(String output) {
    final commits = <GitCommit>[];
    final entries = output.split('\n\n');
    
    for (final entry in entries) {
      if (entry.trim().isEmpty) continue;
      
      final lines = entry.split('\n');
      if (lines.length >= 3) {
        final hash = lines[0].replaceFirst('commit ', '');
        final author = lines[1].replaceFirst('Author: ', '');
        final dateStr = lines[2].replaceFirst('Date: ', '');
        final message = lines.length > 4 ? lines[4].trim() : '';
        
        try {
          final date = DateTime.parse(dateStr);
          commits.add(GitCommit(
            hash: hash,
            message: message,
            author: author,
            date: date,
          ));
        } catch (e) {
          // Skip invalid date entries
          continue;
        }
      }
    }
    
    return commits;
  }

  /// 解析状态代码
  static GitFileStatus _parseStatusCode(String code) {
    switch (code) {
      case 'A ':
      case ' A':
        return GitFileStatus.added;
      case 'M ':
      case ' M':
      case 'MM':
        return GitFileStatus.modified;
      case 'D ':
      case ' D':
        return GitFileStatus.deleted;
      case '??':
        return GitFileStatus.untracked;
      default:
        return GitFileStatus.unmodified;
    }
  }

  /// 格式化文件大小
  static String formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }

  /// 验证提交消息
  static bool isValidCommitMessage(String message) {
    return message.trim().isNotEmpty && message.trim().length >= 3;
  }

  /// 获取文件扩展名对应的图标
  static String getFileIcon(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    
    switch (extension) {
      case 'dart':
        return '🎯';
      case 'js':
      case 'ts':
        return '📜';
      case 'html':
        return '🌐';
      case 'css':
        return '🎨';
      case 'json':
        return '📋';
      case 'md':
        return '📝';
      case 'png':
      case 'jpg':
      case 'jpeg':
      case 'gif':
        return '🖼️';
      case 'pdf':
        return '📄';
      default:
        return '📄';
    }
  }
}