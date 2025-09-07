import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/git_models.dart';
import '../services/git_service.dart';

class RepositoryState {
  final List<GitRepository> repositories;
  final GitRepository? currentRepository;
  final bool isLoading;
  final String? error;

  const RepositoryState({
    this.repositories = const [],
    this.currentRepository,
    this.isLoading = false,
    this.error,
  });

  RepositoryState copyWith({
    List<GitRepository>? repositories,
    GitRepository? currentRepository,
    bool? isLoading,
    String? error,
  }) {
    return RepositoryState(
      repositories: repositories ?? this.repositories,
      currentRepository: currentRepository ?? this.currentRepository,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class RepositoryNotifier extends StateNotifier<RepositoryState> {
  RepositoryNotifier() : super(const RepositoryState());

  // 添加仓库
  Future<void> addRepository(String path) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final repo = await GitService.getRepositoryInfo(path);
      if (repo != null) {
        final updatedRepos = [...state.repositories, repo];
        state = state.copyWith(
          repositories: updatedRepos,
          isLoading: false,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: '无效的Git仓库路径',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: '添加仓库失败: $e',
      );
    }
  }

  // 移除仓库
  void removeRepository(String path) {
    final updatedRepos = state.repositories
        .where((repo) => repo.path != path)
        .toList();
    
    GitRepository? newCurrentRepo = state.currentRepository;
    if (state.currentRepository?.path == path) {
      newCurrentRepo = updatedRepos.isNotEmpty ? updatedRepos.first : null;
    }
    
    state = state.copyWith(
      repositories: updatedRepos,
      currentRepository: newCurrentRepo,
    );
  }

  // 设置当前仓库
  void setCurrentRepository(GitRepository repository) {
    state = state.copyWith(currentRepository: repository);
  }

  // 刷新仓库信息
  Future<void> refreshRepository(String path) async {
    try {
      final repo = await GitService.getRepositoryInfo(path);
      if (repo != null) {
        final updatedRepos = state.repositories.map((r) {
          return r.path == path ? repo : r;
        }).toList();
        
        GitRepository? updatedCurrentRepo = state.currentRepository;
        if (state.currentRepository?.path == path) {
          updatedCurrentRepo = repo;
        }
        
        state = state.copyWith(
          repositories: updatedRepos,
          currentRepository: updatedCurrentRepo,
        );
      }
    } catch (e) {
      state = state.copyWith(error: '刷新仓库失败: $e');
    }
  }

  // 刷新所有仓库
  Future<void> refreshAllRepositories() async {
    state = state.copyWith(isLoading: true);
    
    try {
      final updatedRepos = <GitRepository>[];
      
      for (final repo in state.repositories) {
        final updatedRepo = await GitService.getRepositoryInfo(repo.path);
        if (updatedRepo != null) {
          updatedRepos.add(updatedRepo);
        }
      }
      
      GitRepository? updatedCurrentRepo;
      if (state.currentRepository != null) {
        try {
          updatedCurrentRepo = updatedRepos.firstWhere(
            (repo) => repo.path == state.currentRepository!.path,
          );
        } catch (e) {
          updatedCurrentRepo = updatedRepos.isNotEmpty ? updatedRepos.first : null;
        }
      }
      
      state = state.copyWith(
        repositories: updatedRepos,
        currentRepository: updatedCurrentRepo,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: '刷新仓库失败: $e',
      );
    }
  }

  // 清除错误
  void clearError() {
    state = state.copyWith(error: null);
  }
}

final repositoryProvider = StateNotifierProvider<RepositoryNotifier, RepositoryState>(
  (ref) => RepositoryNotifier(),
);