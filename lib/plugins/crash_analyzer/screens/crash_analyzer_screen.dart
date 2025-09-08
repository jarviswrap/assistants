import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import '../services/addr2line_service.dart';

class CrashAnalyzerScreen extends StatefulWidget {
  const CrashAnalyzerScreen({super.key});

  @override
  State<CrashAnalyzerScreen> createState() => _CrashAnalyzerScreenState();
}

class _CrashAnalyzerScreenState extends State<CrashAnalyzerScreen> {
  final _stackTraceController = TextEditingController();
  final _sdkPathController = TextEditingController();
  final _symbolFileController = TextEditingController();
  
  List<SymbolizedFrame> _symbolizedFrames = [];
  bool _isAnalyzing = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadConfiguration();
  }

  Future<void> _loadConfiguration() async {
    final service = Addr2LineService.instance;
    setState(() {
      _sdkPathController.text = service.androidSdkPath ?? '';
      _symbolFileController.text = service.symbolFilePath ?? '';
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
    );
    
    if (result != null && result.files.single.path != null) {
      final path = result.files.single.path!;
      setState(() {
        _symbolFileController.text = path;
      });
      await Addr2LineService.instance.setSymbolFilePath(path);
    }
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crash分析器'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 配置区域
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '配置',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _sdkPathController,
                            decoration: const InputDecoration(
                              labelText: 'Android SDK路径',
                              border: OutlineInputBorder(),
                            ),
                            readOnly: true,
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _selectSdkPath,
                          child: const Text('选择'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _symbolFileController,
                            decoration: const InputDecoration(
                              labelText: '符号文件路径(.so)',
                              border: OutlineInputBorder(),
                            ),
                            readOnly: true,
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _selectSymbolFile,
                          child: const Text('选择'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // 输入区域
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '崩溃堆栈',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        ElevatedButton(
                          onPressed: _isAnalyzing ? null : _analyzeStack,
                          child: _isAnalyzing
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('分析'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _stackTraceController,
                      decoration: const InputDecoration(
                        hintText: '粘贴Android native crash堆栈...',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 8,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // 结果区域
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '分析结果',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          if (_symbolizedFrames.isNotEmpty)
                            ElevatedButton(
                              onPressed: _copyResult,
                              child: const Text('复制结果'),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      if (_errorMessage != null)
                        Container(
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
                        )
                      else if (_symbolizedFrames.isEmpty)
                        const Center(
                          child: Text('输入崩溃堆栈并点击分析按钮开始'),
                        )
                      else
                        Expanded(
                          child: ListView.builder(
                            itemCount: _symbolizedFrames.length,
                            itemBuilder: (context, index) {
                              final frame = _symbolizedFrames[index];
                              return _buildFrameItem(frame);
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
    _symbolFileController.dispose();
    super.dispose();
  }
}