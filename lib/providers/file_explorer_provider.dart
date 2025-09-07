import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/file_service.dart';
import 'repository_provider.dart';

class FileExplorerState {
  final List<FileSystemEntity> files;
  final String? currentPath;
  final bool isLoading;
  final String? error;
  final Set<String> expandedDirectories;
  final String? selectedFile;

  const FileExplorerState({
    this.files = const [],
    this.currentPath,
    this.isLoading = false,
    this.error,
    this.expandedDirectories = const {},
    this.selectedFile,
  });

  FileExplorerState copyWith({
    List<FileSystemEntity>? files,
    String? currentPath,
    bool? isLoading,
    String? error,
    Set<String>? expandedDirectories,
    String? selectedFile,
  }) {
    return FileExplorerState(
      files: files ?? this.files,
      currentPath: currentPath ?? this.currentPath,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      expandedDirectories: expandedDirectories ?? this.expandedDirectories,
      selectedFile: selectedFile ?? this.selectedFile,
    );
  }
}

class FileExplorerNotifier extends StateNotifier<FileExplorerState> {
  FileExplorerNotifier(this.ref) : super(const FileExplorerState()) {
    // 监听当前仓库变化
    ref.listen(repositoryProvider, (previous, next) {
      if (next.currentRepository?.path != previous?.currentRepository?.path) {
        if (next.currentRepository != null) {
          loadFiles(next.currentRepository!.path);
        } else {
          state = const FileExplorerState();
        }
      }
    });
  }
  
  final Ref ref;

  // 加载文件列表
  Future<void> loadFiles(String path) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final files = await FileService.getDirectoryContents(path);
      state = state.copyWith(
        files: files,
        currentPath: path,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: '加载文件失败: $e',
      );
    }
  }

  // 展开/折叠目录
  void toggleDirectory(String directoryPath) {
    final expanded = Set<String>.from(state.expandedDirectories);
    if (expanded.contains(directoryPath)) {
      expanded.remove(directoryPath);
    } else {
      expanded.add(directoryPath);
    }
    state = state.copyWith(expandedDirectories: expanded);
  }

  // 选择文件
  void selectFile(String? filePath) {
    state = state.copyWith(selectedFile: filePath);
  }

  // 刷新当前目录
  Future<void> refresh() async {
    if (state.currentPath != null) {
      await loadFiles(state.currentPath!);
    }
  }

  // 导航到父目录
  Future<void> navigateUp() async {
    if (state.currentPath != null) {
      final parentPath = Directory(state.currentPath!).parent.path;
      await loadFiles(parentPath);
    }
  }

  // 导航到子目录
  Future<void> navigateToDirectory(String directoryPath) async {
    await loadFiles(directoryPath);
  }

  // 清除错误
  void clearError() {
    state = state.copyWith(error: null);
  }
}

final fileExplorerProvider = StateNotifierProvider<FileExplorerNotifier, FileExplorerState>(
  (ref) => FileExplorerNotifier(ref),
);