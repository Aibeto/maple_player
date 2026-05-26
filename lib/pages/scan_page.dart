import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/app_state.dart';
import '../services/permission_service.dart';

class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  final List<String> _selectedFolders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFolders();
  }

  Future<void> _loadFolders() async {
    final appState = context.read<AppState>();
    setState(() {
      _selectedFolders.clear();
      _selectedFolders.addAll(appState.scanFolders.map((f) => f.path));
      _isLoading = false;
    });
  }

  Future<void> _pickFolder() async {
    final result = await FilePicker.platform.getDirectoryPath();
    if (result != null && result.isNotEmpty) {
      setState(() {
        if (!_selectedFolders.contains(result)) {
          _selectedFolders.add(result);
        }
      });
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1E),
        title: const Text('提示', style: TextStyle(color: Colors.white)),
        content: Text(message, style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  Future<void> _startScan() async {
    if (_selectedFolders.isEmpty) {
      _showError('请先选择至少一个文件夹');
      return;
    }

    final hasPermission = await PermissionService.requestStoragePermission();
    if (!hasPermission) {
      _showError('需要存储权限才能扫描文件');
      return;
    }

    if (mounted) {
      final appState = context.read<AppState>();
      Navigator.pop(context);

      for (final folder in _selectedFolders) {
        await appState.addScanFolder(folder);
      }

      await appState.startScan(_selectedFolders.toList());
    }
  }

  void _removeFolder(String path) {
    setState(() => _selectedFolders.remove(path));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
        ),
        title: Text(
          '扫描曲目',
          style: AppTheme.textStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton(
              onPressed: _startScan,
              child: const Text('扫描', style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _selectedFolders.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.folder_open,
                    size: 64,
                    color: Colors.white30,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '选择文件夹以扫描音乐',
                    style: AppTheme.textStyle(
                      fontSize: 15,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(height: 24),
                  OutlinedButton(
                    onPressed: _pickFolder,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white30),
                    ),
                    child: const Text('添加文件夹'),
                  ),
                ],
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '已选择 ${_selectedFolders.length} 个文件夹',
                        style: AppTheme.textStyle(
                          fontSize: 14,
                          color: Colors.white60,
                        ),
                      ),
                      GestureDetector(
                        onTap: _pickFolder,
                        child: const Icon(Icons.add_circle_outline,
                            color: Colors.white70, size: 24),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: _selectedFolders.length,
                    itemBuilder: (context, index) {
                      final folder = _selectedFolders[index];
                      return GlassContainer(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 3,
                        ),
                        shape: LiquidRoundedSuperellipse(borderRadius: 14),
                        quality: GlassQuality.standard,
                        child: ListTile(
                          leading: const Icon(
                            Icons.folder,
                            color: Colors.amber,
                            size: 24,
                          ),
                          title: Text(
                            folder.split('/').last.split('\\').last,
                            style: AppTheme.textStyle(fontSize: 14),
                          ),
                          subtitle: Text(
                            folder,
                            style: AppTheme.textStyle(
                              fontSize: 11,
                              color: Colors.white.withValues(alpha: 0.4),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: IconButton(
                            onPressed: () => _removeFolder(folder),
                            icon: Icon(
                              Icons.close,
                              color: Colors.white.withValues(alpha: 0.4),
                              size: 20,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _pickFolder,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white30),
                          ),
                          child: const Text('添加文件夹'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: _startScan,
                          style: FilledButton.styleFrom(
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('开始扫描'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}