import 'dart:io';
import 'package:path/path.dart' as path;
import '../models/git_models.dart';

class GitService {
  static const String _gitCommand = 'git';

  // 检查目录是否为Git仓库
  static Future<bool> isGitRepository(String directoryPath) async {
    try {
      final result = await Process.run(
        _gitCommand,
        ['rev-parse', '--git-dir'],
        workingDirectory: directoryPath,
      );
      return result.exitCode == 0;
    } catch (e) {
      return false;
    }
  }

  // 获取仓库信息
  static Future<GitRepository?> getRepositoryInfo(String repoPath) async {
    try {
      if (!await isGitRepository(repoPath)) return null;

      final name = path.basename(repoPath);
      final currentBranch = await getCurrentBranch(repoPath);
      final branches = await getBranches(repoPath);
      final status = await getStatus(repoPath);
      final remoteUrl = await getRemoteUrl(repoPath);
      final lastModified = Directory(repoPath).statSync().modified;

      return GitRepository(
        name: name,
        path: repoPath,
        currentBranch: currentBranch,
        branches: branches,
        status: status,
        remoteUrl: remoteUrl,
        lastModified: lastModified,
      );
    } catch (e) {
      print('Error getting repository info: $e');
      return null;
    }
  }

  // 获取当前分支
  static Future<String?> getCurrentBranch(String repoPath) async {
    try {
      final result = await Process.run(
        _gitCommand,
        ['branch', '--show-current'],
        workingDirectory: repoPath,
      );
      if (result.exitCode == 0) {
        return (result.stdout as String).trim();
      }
    } catch (e) {
      print('Error getting current branch: $e');
    }
    return null;
  }

  // 获取所有分支
  static Future<List<String>> getBranches(String repoPath) async {
    try {
      final result = await Process.run(
        _gitCommand,
        ['branch', '-a'],
        workingDirectory: repoPath,
      );
      if (result.exitCode == 0) {
        final output = result.stdout as String;
        return output
            .split('\n')
            .map((line) => line.trim())
            .where((line) => line.isNotEmpty)
            .map((line) => line.replaceFirst(RegExp(r'^[\*\s]+'), ''))
            .toList();
      }
    } catch (e) {
      print('Error getting branches: $e');
    }
    return [];
  }

  // 获取仓库状态
  static Future<GitStatus> getStatus(String repoPath) async {
    try {
      final result = await Process.run(
        _gitCommand,
        ['status', '--porcelain=v1'],
        workingDirectory: repoPath,
      );
      
      if (result.exitCode == 0) {
        return _parseStatusOutput(result.stdout as String);
      }
    } catch (e) {
      print('Error getting status: $e');
    }
    return const GitStatus();
  }

  // 解析状态输出
  static GitStatus _parseStatusOutput(String output) {
    final List<GitFileStatus> staged = [];
    final List<GitFileStatus> unstaged = [];
    final List<GitFileStatus> untracked = [];

    for (final line in output.split('\n')) {
      if (line.length < 3) continue;
      
      final statusCode = line.substring(0, 2);
      final filePath = line.substring(3);
      final fileName = path.basename(filePath);
      
      final fileStatus = GitFileStatus(
        filePath: filePath,
        fileName: fileName,
        status: _parseFileStatus(statusCode[1]),
      );
      
      if (statusCode[0] != ' ') {
        staged.add(fileStatus);
      } else if (statusCode[1] != ' ') {
        unstaged.add(fileStatus);
      } else if (statusCode == '??') {
        untracked.add(fileStatus);
      }
    }

    return GitStatus(
      staged: staged,
      unstaged: unstaged,
      untracked: untracked,
    );
  }

  // 解析文件状态
  static GitFileStatusType _parseFileStatus(String code) {
    switch (code) {
      case 'A':
        return GitFileStatusType.added;
      case 'M':
        return GitFileStatusType.modified;
      case 'D':
        return GitFileStatusType.deleted;
      case 'R':
        return GitFileStatusType.renamed;
      case 'C':
        return GitFileStatusType.copied;
      case '?':
        return GitFileStatusType.untracked;
      default:
        return GitFileStatusType.modified;
    }
  }

  // 获取远程URL
  static Future<String?> getRemoteUrl(String repoPath) async {
    try {
      final result = await Process.run(
        _gitCommand,
        ['remote', 'get-url', 'origin'],
        workingDirectory: repoPath,
      );
      if (result.exitCode == 0) {
        return (result.stdout as String).trim();
      }
    } catch (e) {
      print('Error getting remote URL: $e');
    }
    return null;
  }

  // 获取提交历史
  static Future<List<GitCommit>> getCommitHistory(
    String repoPath, {
    int limit = 50,
    String? branch,
  }) async {
    try {
      final args = [
        'log',
        '--pretty=format:%H|%h|%s|%an|%ae|%ad',
        '--date=iso',
        '-n',
        limit.toString(),
      ];
      
      if (branch != null) {
        args.add(branch);
      }
      
      final result = await Process.run(
        _gitCommand,
        args,
        workingDirectory: repoPath,
      );
      
      if (result.exitCode == 0) {
        return _parseCommitHistory(result.stdout as String);
      }
    } catch (e) {
      print('Error getting commit history: $e');
    }
    return [];
  }

  // 解析提交历史
  static List<GitCommit> _parseCommitHistory(String output) {
    final commits = <GitCommit>[];
    
    for (final line in output.split('\n')) {
      if (line.isEmpty) continue;
      
      final parts = line.split('|');
      if (parts.length >= 6) {
        commits.add(GitCommit(
          hash: parts[0],
          shortHash: parts[1],
          message: parts[2],
          author: parts[3],
          email: parts[4],
          date: DateTime.parse(parts[5]),
        ));
      }
    }
    
    return commits;
  }

  // Git操作方法
  static Future<bool> stageFile(String repoPath, String filePath) async {
    try {
      final result = await Process.run(
        _gitCommand,
        ['add', filePath],
        workingDirectory: repoPath,
      );
      return result.exitCode == 0;
    } catch (e) {
      print('Error staging file: $e');
      return false;
    }
  }

  static Future<bool> unstageFile(String repoPath, String filePath) async {
    try {
      final result = await Process.run(
        _gitCommand,
        ['reset', 'HEAD', filePath],
        workingDirectory: repoPath,
      );
      return result.exitCode == 0;
    } catch (e) {
      print('Error unstaging file: $e');
      return false;
    }
  }

  static Future<bool> commit(String repoPath, String message, {bool amend = false}) async {
    try {
      final args = ['commit', '-m', message];
      if (amend) {
        args.insert(1, '--amend');
      }
      
      final result = await Process.run(
        _gitCommand,
        args,
        workingDirectory: repoPath,
      );
      return result.exitCode == 0;
    } catch (e) {
      print('Error committing: $e');
      return false;
    }
  }

  static Future<bool> createBranch(String repoPath, String branchName) async {
    try {
      final result = await Process.run(
        _gitCommand,
        ['checkout', '-b', branchName],
        workingDirectory: repoPath,
      );
      return result.exitCode == 0;
    } catch (e) {
      print('Error creating branch: $e');
      return false;
    }
  }

  static Future<bool> switchBranch(String repoPath, String branchName) async {
    try {
      final result = await Process.run(
        _gitCommand,
        ['checkout', branchName],
        workingDirectory: repoPath,
      );
      return result.exitCode == 0;
    } catch (e) {
      print('Error switching branch: $e');
      return false;
    }
  }

  static Future<bool> pull(String repoPath) async {
    try {
      final result = await Process.run(
        _gitCommand,
        ['pull'],
        workingDirectory: repoPath,
      );
      return result.exitCode == 0;
    } catch (e) {
      print('Error pulling: $e');
      return false;
    }
  }

  static Future<bool> push(String repoPath) async {
    try {
      final result = await Process.run(
        _gitCommand,
        ['push'],
        workingDirectory: repoPath,
      );
      return result.exitCode == 0;
    } catch (e) {
      print('Error pushing: $e');
      return false;
    }
  }
  
  // 添加缺少的方法
  static Future<bool> stageAll(String repoPath) async {
    // 实现暂存所有文件的逻辑
    // 这里应该调用实际的git命令
    return true; // 临时返回
  }
  
  static Future<bool> discardFile(String repoPath, String filePath) async {
    // 实现丢弃单个文件更改的逻辑
    return true; // 临时返回
  }
  
  static Future<bool> discardAll(String repoPath) async {
    // 实现丢弃所有更改的逻辑
    return true; // 临时返回
  }
  
  static Future<List<GitFile>> getChangedFiles(String repoPath) async {
    // 实现获取更改文件列表的逻辑
    return []; // 临时返回空列表
  }
}