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
  
  List<SymbolizedFrame> _symbolizedFrames = [];
  bool _isAnalyzing = false;
  String? _errorMessage;
  List<String> _symbolFilePaths = []; // 添加符号文件路径列表

  @override
  void initState() {
    super.initState();
    _loadConfiguration();
  }

  Future<void> _loadConfiguration() async {
    final service = Addr2LineService.instance;
    setState(() {
      _sdkPathController.text = service.androidSdkPath ?? '';
      _symbolFilePaths = List.from(service.symbolFilePaths); // 加载所有符号文件
    });
  }

  Future<void> _selectSdkPath() async {
    final result = await FilePicker.platform.getDirectoryPath(
      dialogTitle: '选择Android SDK路径',
    );
    
    if (result != null) {
      setState(() {
        _sdkPathController.text = result;
      });
      await Addr2LineService.instance.setAndroidSdkPath(result);
    }
  }

  Future<void> _selectSymbolFile() async {
    final result = await FilePicker.platform.pickFiles(
      dialogTitle: '选择符号文件(.so)',
      type: FileType.custom,
      allowedExtensions: ['so'],
      allowMultiple: true, // 允许选择多个文件
    );
    
    if (result != null && result.files.isNotEmpty) {
      for (final file in result.files) {
        if (file.path != null) {
          await Addr2LineService.instance.addSymbolFilePath(file.path!);
        }
      }
      await _loadConfiguration(); // 重新加载配置
    }
  }

  Future<void> _removeSymbolFile(String path) async {
    await Addr2LineService.instance.removeSymbolFilePath(path);
    await _loadConfiguration();
  }

  Future<void> _clearAllSymbolFiles() async {
    await Addr2LineService.instance.clearSymbolFilePaths();
    await _loadConfiguration();
  }

  Future<void> _analyzeStack() async {
    if (_stackTraceController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = '请输入崩溃堆栈';
      });
      return;
    }

    setState(() {
      _isAnalyzing = true;
      _errorMessage = null;
      _symbolizedFrames = [];
    });

    try {
      final service = Addr2LineService.instance;
      
      // 验证配置
      final isValid = await service.validateConfiguration();
      if (!isValid) {
        throw Exception('配置无效：请检查Android SDK路径和符号文件路径');
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
                    onRemoveItem: (item) {
                      _sdkPathController.clear();
                      setState(() {});
                    },
                    onItemTap: (item) {
                      _selectSdkPath();
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildListView(
                    context: context, 
                    items: _symbolFilePaths,
                    emptyMessage: '未选择符号文件',
                    // title: '符号文件选择',
                    icon: Icons.insert_drive_file,
                    // primaryAction: ClickAction(
                    //   label: '添加',
                    //   icon: Icons.add,
                    //   onPressed: _selectSymbolFile,
                    // ),
                    // secondAction: _symbolFilePaths.isNotEmpty ? ClickAction(
                    //   label: '清空',
                    //   onPressed: _clearAllSymbolFiles,
                    //   isOutlined: true,
                    // ) : null,
                    onRemoveItem: _removeSymbolFile,
                    onItemTap: (item) {
                      _selectSymbolFile();
                    },
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
                    decoration: const InputDecoration(
                      hintText: '粘贴Android native crash堆栈...',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: null,
                    expands: true,
                    textAlignVertical: TextAlignVertical.top,
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
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _buildListTitle(title: title, primaryAction: primaryAction, secondAction: secondAction),
      const SizedBox(height: 4),
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