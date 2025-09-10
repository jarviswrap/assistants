import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import '../services/addr2line_service.dart';

class CrashAnalyzerScreen extends StatefulWidget {
  const CrashAnalyzerScreen({super.key});

  @override
  State<CrashAnalyzerScreen> createState() => _CrashAnalyzerScreenState();
}

class ClickAction {
  final String label;
  final IconData? icon;
  final VoidCallback onPressed;
  final bool isOutlined;

  const ClickAction({
    required this.label,
    this.icon,
    required this.onPressed,
    this.isOutlined = false,
  });
}

class _CrashAnalyzerScreenState extends State<CrashAnalyzerScreen> {
  final _stackTraceController = TextEditingController();
  final _sdkPathController = TextEditingController();
  final _symbolDirectoryController = TextEditingController();  // 新增符号目录控制器
  
  List<SymbolizedFrame> _symbolizedFrames = [];
  bool _isAnalyzing = false;
  String? _errorMessage;
  List<String> _symbolFilePaths = [];
  List<String> _foundSoFiles = [];  // 自动找到的.so文件列表

  @override
  void initState() {
    super.initState();
    _loadConfiguration();
    
    // 设置权限错误回调
    Addr2LineService.instance.onPermissionError = _handlePermissionError;
  }
  
  /// 处理权限错误
  void _handlePermissionError(String message) {
    if (mounted) {
      // 检查是否是SDK路径权限错误
      if (message.contains('SDK')) {
        final currentSdkPath = Addr2LineService.instance.androidSdkPath;
        
        if (currentSdkPath != null && currentSdkPath.isNotEmpty) {
          // 重新授权SDK目录
          _reauthorizeSdkDirectory(currentSdkPath, message);
        } else {
          // 如果没有SDK路径配置，显示错误提示并引导选择
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.warning, color: Colors.orange),
                  const SizedBox(width: 8),
                  Expanded(child: Text(message)),
                ],
              ),
              backgroundColor: Colors.orange.shade100,
              duration: const Duration(seconds: 4),
              action: SnackBarAction(
                label: '选择SDK路径',
                onPressed: _selectSdkPath,
              ),
            ),
          );
        }
      } else {
        // 原有的符号目录权限错误处理逻辑
        final currentSymbolDir = Addr2LineService.instance.symbolDirectoryPath;
        
        if (currentSymbolDir != null && currentSymbolDir.isNotEmpty) {
          // 直接使用FilePicker重新授权当前目录
          _reauthorizeCurrentDirectory(currentSymbolDir);
        } else {
          // 如果没有符号目录配置，显示错误提示并引导选择
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.warning, color: Colors.orange),
                  const SizedBox(width: 8),
                  Expanded(child: Text(message)),
                ],
              ),
              backgroundColor: Colors.orange.shade100,
              duration: const Duration(seconds: 4),
              action: SnackBarAction(
                label: '选择目录',
                onPressed: _selectSymbolDirectory,
              ),
            ),
          );
        }
      }
    }
  }

  /// 重新授权SDK目录
  Future<void> _reauthorizeSdkDirectory(String currentSdkPath, String message) async {
    try {
      // 显示正在重新授权的提示
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 8),
                Text('检测到SDK目录未授权，正在重新授权目录访问权限...'),
              ],
            ),
            duration: Duration(seconds: 2),
          ),
        );
      }
      
      // 使用FilePicker打开当前SDK目录，让用户重新授权
      final String? selectedDirectory = await FilePicker.platform.getDirectoryPath(
        dialogTitle: '请重新选择Android SDK路径以获取访问权限',
        initialDirectory: currentSdkPath,
      );
      
      if (selectedDirectory != null) {
        // 更新SDK路径
        await Addr2LineService.instance.setAndroidSdkPath(selectedDirectory);
        setState(() {
          _sdkPathController.text = selectedDirectory;
        });
        
        if (mounted) {
          // 检查是否是相同目录
          final isSameDirectory = selectedDirectory == currentSdkPath;
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(
                    isSameDirectory ? Icons.check_circle : Icons.info,
                    color: isSameDirectory ? Colors.green : Colors.blue,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isSameDirectory 
                        ? 'SDK目录访问权限已重新授权'
                        : 'SDK路径已更新: ${selectedDirectory.split('/').last}',
                    ),
                  ),
                ],
              ),
              backgroundColor: isSameDirectory 
                ? Colors.green.shade100 
                : Colors.blue.shade100,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } else {
        // 用户取消了选择，显示原始错误信息
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.warning, color: Colors.orange),
                  const SizedBox(width: 8),
                  Expanded(child: Text(message)),
                ],
              ),
              backgroundColor: Colors.orange.shade100,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      print('重新授权SDK目录时出错: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.red),
                const SizedBox(width: 8),
                Expanded(child: Text('重新授权失败: $e')),
              ],
            ),
            backgroundColor: Colors.red.shade100,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  /// 重新授权当前目录
  Future<void> _reauthorizeCurrentDirectory(String currentDir) async {
    try {
      // 显示正在重新授权的提示
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 8),
                Text('检测到当前符号目录未授权，正在重新授权目录访问权限...'),
              ],
            ),
            duration: Duration(seconds: 2),
          ),
        );
      }
      
      // 使用FilePicker打开当前目录，让用户重新授权
      final String? selectedDirectory = await FilePicker.platform.getDirectoryPath(
        dialogTitle: '请重新选择符号目录以获取访问权限',
        initialDirectory: currentDir,
      );
      
      if (selectedDirectory != null) {
        // 更新符号目录路径
        await Addr2LineService.instance.setSymbolDirectoryPath(selectedDirectory);
        setState(() {
          _symbolDirectoryController.text = selectedDirectory;
        });
        
        if (mounted) {
          // 检查是否是相同目录
          final isSameDirectory = selectedDirectory == currentDir;
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isSameDirectory 
                        ? '目录权限已重新授权' 
                        : '已选择新的符号目录',
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.green.shade100,
              duration: const Duration(seconds: 2),
            ),
          );
          
          // 自动重新尝试查找符号文件
          _autoFindSymbolFiles();
        }
      } else {
        // 用户取消了选择
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.info, color: Colors.blue),
                  SizedBox(width: 8),
                  Text('已取消目录选择'),
                ],
              ),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.red),
                const SizedBox(width: 8),
                Expanded(child: Text('重新授权失败: ${e.toString()}')),
              ],
            ),
            backgroundColor: Colors.red.shade100,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _loadConfiguration() async {
    final service = Addr2LineService.instance;
    setState(() {
      _sdkPathController.text = service.androidSdkPath ?? '';
      _symbolDirectoryController.text = service.symbolDirectoryPath ?? '';  // 添加这行
      _symbolFilePaths = List.from(service.symbolSoFiles); // 加载所有符号文件
    });
  }

  Future<void> _selectSdkPath() async {
    print('调试信息: _selectSdkPath 方法被调用');
    
    final result = await FilePicker.platform.getDirectoryPath(
      dialogTitle: '选择Android SDK路径',
      lockParentWindow: true,
    );
    
    if (result != null) {
      print('调试信息: 用户选择了SDK路径: $result');
      setState(() {
        _sdkPathController.text = result;
      });
      await Addr2LineService.instance.setAndroidSdkPath(result);
      print('调试信息: SDK路径已保存到服务');
    } else {
      print('调试信息: 用户取消了SDK路径选择');
    }
  }

  /// 选择符号目录
  Future<void> _selectSymbolDirectory() async {
    print('调试信息: _selectSymbolDirectory 方法被调用');
    
    final result = await FilePicker.platform.getDirectoryPath(
      dialogTitle: '选择符号文件(.so)所在目录',
      lockParentWindow: true,
    );

    if (result != null) {
      print('调试信息: 用户选择了符号目录: $result');
      setState(() {
        _symbolDirectoryController.text = result;
      });
      await Addr2LineService.instance.setSymbolDirectoryPath(result);
      print('调试信息: 符号目录已保存到服务');
      
      // 如果已有堆栈内容，立即触发自动查找
      if (_stackTraceController.text.trim().isNotEmpty) {
        await _autoFindSymbolFiles();
      }
    } else {
      print('调试信息: 用户取消了符号目录选择');
    }
  }

  /// 自动查找符号文件
  Future<void> _autoFindSymbolFiles() async {
    if (_stackTraceController.text.trim().isEmpty) return;
    
    try {
      final foundFiles = await Addr2LineService.instance.autoFindSymbolFiles(_stackTraceController.text);
      
      setState(() {
        _foundSoFiles = foundFiles;
        _symbolFilePaths = foundFiles;
      });
      
      if (mounted) {
        if (foundFiles.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('自动找到 ${foundFiles.length} 个符号文件'),
              duration: const Duration(seconds: 2),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.info, color: Colors.blue),
                  SizedBox(width: 8),
                  Expanded(child: Text('未找到匹配的符号文件，请检查符号目录设置')),
                ],
              ),
              backgroundColor: Colors.blue.shade100,
              duration: const Duration(seconds: 3),
              action: SnackBarAction(
                label: '选择目录',
                onPressed: _selectSymbolDirectory,
              ),
            ),
          );
        }
      }
    } catch (e) {
      print('自动查找符号文件时出错: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.red),
                const SizedBox(width: 8),
                Expanded(child: Text('查找符号文件失败: ${e.toString()}')),
              ],
            ),
            backgroundColor: Colors.red.shade100,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Future<void> _analyzeStack() async {
    if (_stackTraceController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = '请输入崩溃堆栈';
      });
      return;
    }
    print(" 分析堆栈 _analyzeStack");
    // 先自动查找符号文件
    await _autoFindSymbolFiles();
    print(" 分析堆栈 _analyzeStack 1" );
    setState(() {
      _isAnalyzing = true;
      _errorMessage = null;
      _symbolizedFrames = [];
    });

    try {
      final service = Addr2LineService.instance;
      print(" 分析堆栈 _analyzeStack 2");
      // 验证配置
      final isValid = await service.validateConfiguration();
      print(" 分析堆栈 _analyzeStack 3");
      if (!isValid) {
        throw Exception('配置无效：请检查Android SDK路径和符号目录路径');
      }

      final frames = await service.symbolizeStack(_stackTraceController.text);
      setState(() {
        _symbolizedFrames = frames;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isAnalyzing = false;
      });
    }
  }

  void _copyResult() {
    final result = _symbolizedFrames.map((frame) {
      if (frame.isSymbolized) {
        return '${frame.originalLine} -> ${frame.symbolizedInfo}';
      } else if (frame.hasError) {
        return '${frame.originalLine} (解析失败: ${frame.error})';
      } else {
        return frame.originalLine;
      }
    }).join('\n');
    
    Clipboard.setData(ClipboardData(text: result));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('结果已复制到剪贴板')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.end, // 改为下边对齐
              children: [
                Text( // 标题
                  'Crash分析器',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(width: 10), // 添加16的间距
                Text( // 提示字符
                  'Android native crash堆栈符号化工具',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.normal,
                  ),    
                ),
              ],
            ),
          // 标题
         
          const SizedBox(height: 10),
          
          // 紧凑的配置区域
          Card(
            child: Padding(
              padding: const EdgeInsets.all(10.0), // 减少内边距
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // SDK路径
                  _buildListView(
                    context: context, 
                    items: _sdkPathController.text.isEmpty ? [] : [_sdkPathController.text],
                    emptyMessage: '未选择Android SDK路径',
                    icon: Icons.folder,
                    onItemTap: (item) {
                      _selectSdkPath();
                    },
                  ),
                  const SizedBox(height: 12),
                  // 添加符号目录显示
                  _buildListView(
                    context: context, 
                    items: _symbolDirectoryController.text.isEmpty ? [] : [_symbolDirectoryController.text],
                    emptyMessage: '未选择符号目录',
                    icon: Icons.folder_open,
                    onItemTap: (item) {
                      _selectSymbolDirectory();
                    },
                  ),
                  Row(
                    children: [
                      // 左边的"+"文本
                      const Text(
                        '+',
                        style: TextStyle(fontSize: 16),
                      ),
                      const SizedBox(width: 4),
                      // 右边的符号文件列表
                      Expanded(
                        child: _buildListView(
                          context: context, 
                          items: _symbolFilePaths.map((filePath) {
                            // 获取符号目录路径
                            final symbolDir = _symbolDirectoryController.text;
                            if (symbolDir.isNotEmpty && filePath.startsWith(symbolDir)) {
                              // 去掉符号目录前缀，显示相对路径
                              String relativePath = filePath.substring(symbolDir.length);
                              // 去掉开头的路径分隔符
                              if (relativePath.startsWith('/')) {
                                relativePath = relativePath.substring(1);
                              }
                              return relativePath;
                            }
                            // 如果不在符号目录下，显示完整路径
                            return filePath;
                          }).toList(),
                          emptyMessage: '粘贴Android native crash堆栈后，自动搜索符号目录下的符号文件',
                          icon: Icons.insert_drive_file,
                          onRemoveItem: (item) {
                            // 获取符号目录路径
                            final symbolDir = _symbolDirectoryController.text;
                            String fullPath = item;
                            
                            // 如果显示的是相对路径，需要还原为完整路径
                            if (symbolDir.isNotEmpty && !item.startsWith('/')) {
                              fullPath = '$symbolDir/$item';
                            }
                            
                            // 从service中删除符号文件
                            Addr2LineService.instance.removeSymbolFile(fullPath);
                            
                            setState(() {
                              // 从UI列表中移除
                              _symbolFilePaths.remove(fullPath);
                            });
                          },
                          onItemTap: (item) {
                            // 获取符号目录路径
                            final symbolDir = _symbolDirectoryController.text;
                            String fullPath = item;
                            
                            // 如果显示的是相对路径，需要还原为完整路径
                            if (symbolDir.isNotEmpty && !item.startsWith('/')) {
                              fullPath = '$symbolDir/$item';
                            }
                            
                            // 复制完整路径到粘贴板
                            Clipboard.setData(ClipboardData(text: fullPath));
                            
                            // 显示复制成功提示
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('已复制路径: $fullPath'),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          
          // 左右布局：输入区域和结果区域
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 左侧：输入区域
                _buildSectionCard(
                  context: context,
                  flex: 1,
                  title: '崩溃堆栈',
                  actionButton: ElevatedButton(
                    onPressed: _isAnalyzing ? null : _analyzeStack,
                    child: _isAnalyzing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('分析'),
                  ),
                  content: TextField(
                    controller: _stackTraceController,
                    style: const TextStyle(
                      fontSize: 12,
                    ),
                    decoration: InputDecoration(
                      hintText: '粘贴Android native crash堆栈...',
                      hintStyle: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.6),
                        fontSize: 12,
                      ),
                      border: const OutlineInputBorder(),
                    ),
                    maxLines: null,
                    expands: true,
                    textAlignVertical: TextAlignVertical.top,
                    onChanged: (text) {
                      // 当堆栈内容改变时，如果已选择符号目录，自动查找符号文件
                      if (text.trim().isNotEmpty && _symbolDirectoryController.text.isNotEmpty) {
                        // 延迟执行，避免频繁触发
                        Future.delayed(const Duration(milliseconds: 500), () {
                          if (_stackTraceController.text == text) {
                            _autoFindSymbolFiles();
                          }
                        });
                      }
                    },
                  ),
                ),

                const SizedBox(width: 10),
                
                // 右侧：结果区域
                _buildSectionCard(
                  context: context,
                  flex: 1,
                  title: '分析结果',
                  actionButton: _symbolizedFrames.isNotEmpty
                      ? ElevatedButton(
                          onPressed: _copyResult,
                          child: const Text('复制结果'),
                        )
                      : null,
                  content: _buildResultContent(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultContent() {
    if (_errorMessage != null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              Icons.error,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _errorMessage!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ),
          ],
        ),
      );
    } else if (_symbolizedFrames.isEmpty) {
      return const Center(
        child: Text('输入崩溃堆栈并点击分析按钮开始'),
      );
    } else {
      return ListView.builder(
        itemCount: _symbolizedFrames.length,
        itemBuilder: (context, index) {
          final frame = _symbolizedFrames[index];
          return _buildFrameItem(frame);
        },
      );
    }
  }

  Widget _buildFrameItem(SymbolizedFrame frame) {
    if (frame.address == null) {
      // 非堆栈帧行
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Text(
          frame.originalLine,
          style: TextStyle(
            fontFamily: 'monospace',
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(
          color: frame.hasError
              ? Theme.of(context).colorScheme.error.withOpacity(0.3)
              : frame.isSymbolized
                  ? Theme.of(context).colorScheme.primary.withOpacity(0.3)
                  : Theme.of(context).colorScheme.outline.withOpacity(0.3),
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            frame.originalLine,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
            ),
          ),
          if (frame.isSymbolized) ...[
            const SizedBox(height: 4),
            Text(
              '→ ${frame.symbolizedInfo}',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ] else if (frame.hasError) ...[
            const SizedBox(height: 4),
            Text(
              '✗ ${frame.error}',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  void dispose() {
    Addr2LineService.instance.onPermissionError = null;
    _stackTraceController.dispose();
    _sdkPathController.dispose();
    super.dispose();
  }

  // 计算符号文件路径的公共前缀
  String _getCommonPrefix(List<String> paths) {
    if (paths.isEmpty) return '';
    if (paths.length == 1) return '';
    
    String commonPrefix = paths.first;
    for (int i = 1; i < paths.length; i++) {
      int j = 0;
      while (j < commonPrefix.length && 
             j < paths[i].length && 
             commonPrefix[j] == paths[i][j]) {
        j++;
      }
      commonPrefix = commonPrefix.substring(0, j);
    }
    
    // 找到最后一个路径分隔符
    int lastSlash = commonPrefix.lastIndexOf('/');
    if (lastSlash > 0) {
      return commonPrefix.substring(0, lastSlash + 1);
    }
    return '';
  }

  // 获取相对于公共前缀的路径
  String _getRelativePath(String fullPath, String commonPrefix) {
    if (commonPrefix.isEmpty) return fullPath;
    return fullPath.substring(commonPrefix.length);
  }
}

Widget _buildSectionCard({
  required BuildContext context,
  required int flex,
  required String title,
  Widget? actionButton,
  required Widget content,
}) {
  return Expanded(
    flex: flex,
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (actionButton != null) actionButton,
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: content,
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _buildListView({
  required BuildContext context,
  required List<String> items,
  required String emptyMessage,
  String? title,
  IconData? icon,
  ClickAction? primaryAction,
  ClickAction? secondAction,
  Function(String)? onRemoveItem,
  Function(String)? onItemTap,
}) {
  // 检查是否有标题内容
  final bool hasAnyTitleContent = (title?.isNotEmpty == true) || 
                                 (primaryAction != null) || 
                                 (secondAction != null);
  
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _buildListTitle(title: title, primaryAction: primaryAction, secondAction: secondAction),
      if (hasAnyTitleContent) const SizedBox(height: 4),  // 只有当有标题内容时才显示间距
      // 文件列表显示区域
      Container(
        constraints: const BoxConstraints(maxHeight: 120),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).colorScheme.outline),
          borderRadius: BorderRadius.circular(4),
        ),
        child: _buildListContent(
          context: context,
          items: items,
          emptyMessage: emptyMessage,
          icon: icon,
          onRemoveItem: onRemoveItem,
          onItemTap: onItemTap,
        ),
      ),
    ],
  );
}

Widget _buildClickTitle({ClickAction? clickAction}) {
  if (clickAction != null) {
    return SizedBox(
                height: 28,
                child: clickAction.isOutlined?
                 OutlinedButton(
                          onPressed: clickAction.onPressed,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                          child: Text(clickAction.label, style: const TextStyle(fontSize: 12)),
                        ):
                        clickAction.icon != null
                        ? ElevatedButton.icon(
                            onPressed: clickAction.onPressed,
                            icon: Icon(clickAction.icon, size: 14),
                            label: Text(clickAction.label, style: const TextStyle(fontSize: 12)),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                            ),
                          )
                        : ElevatedButton(
                            onPressed: clickAction.onPressed,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                            ),
                            child: Text(clickAction.label, style: const TextStyle(fontSize: 12)),
                          ),
              );
  }
  return const SizedBox(width: 6);
} 

Widget _buildListTitle({
  String? title,
  ClickAction? primaryAction,
  ClickAction? secondAction}) {
  // 创建变量存储三个参数中是否有任意不为空
  final bool hasAnyContent = (title?.isNotEmpty == true) || 
                            (primaryAction != null) || 
                            (secondAction != null);
  if (hasAnyContent) {
    return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          title?.isNotEmpty == true? Text(
            title!,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ):const SizedBox(width: 6),
          Row(
            children: [
              _buildClickTitle(clickAction: primaryAction),
              _buildClickTitle(clickAction: secondAction),
            ],
          ),
        ],
      );
  }
  // 如果所有参数都为空，返回空容器
  return const SizedBox.shrink();
}

Widget _buildListContent({
  required BuildContext context,
  required List<String> items,
  required String emptyMessage,
  IconData? icon,
  Function(String)? onRemoveItem,
  Function(String)? onItemTap, // 新增：列表项点击回调
}) {
  // 如果为空，创建一个包含提示信息的列表项
  final displayItems = items.isEmpty ? [''] : items;

  return ListView.separated(
    shrinkWrap: true,
    itemCount: displayItems.length,
    separatorBuilder: (context, index) => const SizedBox(height: 2),
    itemBuilder: (context, index) {
      final item = displayItems[index];
      final isEmpty = item.isEmpty;
        
      return InkWell(
        onTap: () {
          if (onItemTap != null) {
            onItemTap(item);
          }
        },
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              Icon(
                isEmpty ? Icons.info_outline : icon,
                size: 14,
                color: isEmpty 
                    ? Colors.grey 
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isEmpty ? emptyMessage : item,
                  style: TextStyle(
                    fontSize: 13,
                    color: isEmpty ? Colors.grey : null,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // 只有在非空状态时才显示删除按钮
              if (!isEmpty && onRemoveItem != null)
                IconButton(
                  onPressed: () => onRemoveItem(item),
                  icon: const Icon(Icons.close, size: 14),
                  constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                  padding: EdgeInsets.zero,
                ),
            ],
          ),
        ),
      );
    },
  );
}