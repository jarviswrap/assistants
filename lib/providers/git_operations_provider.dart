import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/git_models.dart';
import '../services/git_service.dart';
import 'repository_provider.dart';

class GitOperationsState {
  final bool isLoading;
  final String? error;
  final String? successMessage;
  final List<GitCommit> commits;
  final List<GitBranch> branches;
  final GitBranch? currentBranch; // 添加当前分支属性
  final List<GitFile> changedFiles;

  const GitOperationsState({
    this.isLoading = false,
    this.error,
    this.successMessage,
    this.commits = const [],
    this.branches = const [],
    this.currentBranch, // 添加参数
    this.changedFiles = const [],
  });

  GitOperationsState copyWith({
    bool? isLoading,
    String? error,
    String? successMessage,
    List<GitCommit>? commits,
    List<GitBranch>? branches,
    GitBranch? currentBranch, // 添加参数
    List<GitFile>? changedFiles,
  }) {
    return GitOperationsState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      successMessage: successMessage,
      commits: commits ?? this.commits,
      branches: branches ?? this.branches,
      currentBranch: currentBranch ?? this.currentBranch, // 添加赋值
      changedFiles: changedFiles ?? this.changedFiles,
    );
  }
}

class GitOperationsNotifier extends StateNotifier<GitOperationsState> {
  GitOperationsNotifier(this.ref) : super(const GitOperationsState());
  
  final Ref ref;

  String? get _currentRepoPath {
    return ref.read(repositoryProvider).currentRepository?.path;
  }

  // 暂存文件
  Future<void> stageFile(String filePath) async {
    final repoPath = _currentRepoPath;
    if (repoPath == null) return;

    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final success = await GitService.stageFile(repoPath, filePath);
      if (success) {
        state = state.copyWith(
          isLoading: false,
          successMessage: '文件已暂存',
        );
        // 刷新仓库状态
        await ref.read(repositoryProvider.notifier).refreshRepository(repoPath);
      } else {
        state = state.copyWith(
          isLoading: false,
          error: '暂存文件失败',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: '暂存文件失败: $e',
      );
    }
  }

  // 取消暂存文件
  Future<void> unstageFile(String filePath) async {
    final repoPath = _currentRepoPath;
    if (repoPath == null) return;

    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final success = await GitService.unstageFile(repoPath, filePath);
      if (success) {
        state = state.copyWith(
          isLoading: false,
          successMessage: '文件已取消暂存',
        );
        await ref.read(repositoryProvider.notifier).refreshRepository(repoPath);
      } else {
        state = state.copyWith(
          isLoading: false,
          error: '取消暂存失败',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: '取消暂存失败: $e',
      );
    }
  }

  // 提交更改
  Future<void> commit(String message, {bool amend = false}) async {
    final repoPath = _currentRepoPath;
    if (repoPath == null) return;
  
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final success = await GitService.commit(repoPath, message, amend: amend);
      if (success) {
        state = state.copyWith(
          isLoading: false,
          successMessage: '提交成功',
        );
        await ref.read(repositoryProvider.notifier).refreshRepository(repoPath);
        await loadCommitHistory();
      } else {
        state = state.copyWith(
          isLoading: false,
          error: '提交失败',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: '提交失败: $e',
      );
    }
  }

  // 创建分支
  Future<void> createBranch(String branchName) async {
    final repoPath = _currentRepoPath;
    if (repoPath == null) return;

    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final success = await GitService.createBranch(repoPath, branchName);
      if (success) {
        state = state.copyWith(
          isLoading: false,
          successMessage: '分支创建成功',
        );
        await ref.read(repositoryProvider.notifier).refreshRepository(repoPath);
      } else {
        state = state.copyWith(
          isLoading: false,
          error: '创建分支失败',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: '创建分支失败: $e',
      );
    }
  }

  // 切换分支
  Future<void> switchBranch(String branchName) async {
    final repoPath = _currentRepoPath;
    if (repoPath == null) return;

    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final success = await GitService.switchBranch(repoPath, branchName);
      if (success) {
        state = state.copyWith(
          isLoading: false,
          successMessage: '分支切换成功',
        );
        await ref.read(repositoryProvider.notifier).refreshRepository(repoPath);
        await loadCommitHistory();
      } else {
        state = state.copyWith(
          isLoading: false,
          error: '切换分支失败',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: '切换分支失败: $e',
      );
    }
  }

  // 拉取更新
  Future<void> pull() async {
    final repoPath = _currentRepoPath;
    if (repoPath == null) return;

    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final success = await GitService.pull(repoPath);
      if (success) {
        state = state.copyWith(
          isLoading: false,
          successMessage: '拉取成功',
        );
        await ref.read(repositoryProvider.notifier).refreshRepository(repoPath);
        await loadCommitHistory();
      } else {
        state = state.copyWith(
          isLoading: false,
          error: '拉取失败',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: '拉取失败: $e',
      );
    }
  }

  // 推送更新
  Future<void> push() async {
    final repoPath = _currentRepoPath;
    if (repoPath == null) return;

    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final success = await GitService.push(repoPath);
      if (success) {
        state = state.copyWith(
          isLoading: false,
          successMessage: '推送成功',
        );
        await ref.read(repositoryProvider.notifier).refreshRepository(repoPath);
      } else {
        state = state.copyWith(
          isLoading: false,
          error: '推送失败',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: '推送失败: $e',
      );
    }
  }

  // 加载提交历史
  Future<void> loadCommitHistory({int limit = 50}) async {
    final repoPath = _currentRepoPath;
    if (repoPath == null) return;

    try {
      final commits = await GitService.getCommitHistory(repoPath, limit: limit);
      state = state.copyWith(commits: commits);
    } catch (e) {
      state = state.copyWith(error: '加载提交历史失败: $e');
    }
  }

  // 清除消息
  void clearMessages() {
    state = state.copyWith(error: null, successMessage: null);
  }
  
  // 添加缺少的方法
  Future<void> stageAll() async {
    final repoPath = _currentRepoPath;
    if (repoPath == null) return;

    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final success = await GitService.stageAll(repoPath);
      if (success) {
        state = state.copyWith(
          isLoading: false,
          successMessage: '所有文件已暂存',
        );
        await ref.read(repositoryProvider.notifier).refreshRepository(repoPath);
        await loadStatus();
      } else {
        state = state.copyWith(
          isLoading: false,
          error: '暂存所有文件失败',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: '暂存所有文件失败: $e',
      );
    }
  }

  Future<void> discardFile(String filePath) async {
    final repoPath = _currentRepoPath;
    if (repoPath == null) return;

    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final success = await GitService.discardFile(repoPath, filePath);
      if (success) {
        state = state.copyWith(
          isLoading: false,
          successMessage: '文件更改已丢弃',
        );
        await ref.read(repositoryProvider.notifier).refreshRepository(repoPath);
        await loadStatus();
      } else {
        state = state.copyWith(
          isLoading: false,
          error: '丢弃文件更改失败',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: '丢弃文件更改失败: $e',
      );
    }
  }

  Future<void> discardAll() async {
    final repoPath = _currentRepoPath;
    if (repoPath == null) return;

    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final success = await GitService.discardAll(repoPath);
      if (success) {
        state = state.copyWith(
          isLoading: false,
          successMessage: '所有更改已丢弃',
        );
        await ref.read(repositoryProvider.notifier).refreshRepository(repoPath);
        await loadStatus();
      } else {
        state = state.copyWith(
          isLoading: false,
          error: '丢弃所有更改失败',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: '丢弃所有更改失败: $e',
      );
    }
  }

  Future<void> loadStatus() async {
    final repoPath = _currentRepoPath;
    if (repoPath == null) return;

    try {
      final files = await GitService.getChangedFiles(repoPath);
      state = state.copyWith(changedFiles: files);
    } catch (e) {
      state = state.copyWith(error: '加载文件状态失败: $e');
    }
  }
}

final gitOperationsProvider = StateNotifierProvider<GitOperationsNotifier, GitOperationsState>(
  (ref) => GitOperationsNotifier(ref),
);