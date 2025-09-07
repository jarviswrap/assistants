class GitRepository {
  final String name;
  final String path;
  final String? currentBranch;
  final List<String> branches;
  final GitStatus status;
  final String? remoteUrl;
  final DateTime lastModified;
  final int? commitCount;

  const GitRepository({
    required this.name,
    required this.path,
    this.currentBranch,
    this.branches = const [],
    required this.status,
    this.remoteUrl,
    required this.lastModified,
    this.commitCount,
  });

  GitRepository copyWith({
    String? name,
    String? path,
    String? currentBranch,
    List<String>? branches,
    GitStatus? status,
    String? remoteUrl,
    DateTime? lastModified,
    int? commitCount,
  }) {
    return GitRepository(
      name: name ?? this.name,
      path: path ?? this.path,
      currentBranch: currentBranch ?? this.currentBranch,
      branches: branches ?? this.branches,
      status: status ?? this.status,
      remoteUrl: remoteUrl ?? this.remoteUrl,
      lastModified: lastModified ?? this.lastModified,
      commitCount: commitCount ?? this.commitCount,
    );
  }
}

class GitStatus {
  final List<GitFileStatus> staged;
  final List<GitFileStatus> unstaged;
  final List<GitFileStatus> untracked;
  final int aheadCount;
  final int behindCount;

  const GitStatus({
    this.staged = const [],
    this.unstaged = const [],
    this.untracked = const [],
    this.aheadCount = 0,
    this.behindCount = 0,
  });

  bool get isClean => staged.isEmpty && unstaged.isEmpty && untracked.isEmpty;
  int get totalChanges => staged.length + unstaged.length + untracked.length;
}

class GitFileStatus {
  final String filePath;
  final String fileName;
  final GitFileStatusType status;
  final String? oldPath;

  const GitFileStatus({
    required this.filePath,
    required this.fileName,
    required this.status,
    this.oldPath,
  });
}

enum GitFileStatusType {
  added,
  modified,
  deleted,
  renamed,
  copied,
  untracked,
  ignored,
  unmodified,
}

class GitCommit {
  final String hash;
  final String shortHash;
  final String message;
  final String author;
  final String email;
  final DateTime date;
  final List<String> parents;
  final List<GitFileStatus> files;

  const GitCommit({
    required this.hash,
    required this.shortHash,
    required this.message,
    required this.author,
    required this.email,
    required this.date,
    this.parents = const [],
    this.files = const [],
  });
}

class GitBranch {
  final String name;
  final String fullName;
  final bool isRemote;
  final bool isCurrent;
  final String? upstream;
  final GitCommit? lastCommit;

  const GitBranch({
    required this.name,
    required this.fullName,
    this.isRemote = false,
    this.isCurrent = false,
    this.upstream,
    this.lastCommit,
  });
}

class GitRemote {
  final String name;
  final String url;
  final GitRemoteType type;

  const GitRemote({
    required this.name,
    required this.url,
    required this.type,
  });
}

enum GitRemoteType {
  fetch,
  push,
}

class GitFile {
  final String filePath;
  final String fileName;
  final GitFileStatusType status;
  final bool isStaged;
  final String? oldPath;

  const GitFile({
    required this.filePath,
    required this.fileName,
    required this.status,
    required this.isStaged,
    this.oldPath,
  });

  GitFile copyWith({
    String? filePath,
    String? fileName,
    GitFileStatusType? status,
    bool? isStaged,
    String? oldPath,
  }) {
    return GitFile(
      filePath: filePath ?? this.filePath,
      fileName: fileName ?? this.fileName,
      status: status ?? this.status,
      isStaged: isStaged ?? this.isStaged,
      oldPath: oldPath ?? this.oldPath,
    );
  }
}