import 'dart:io';
import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import '../config/theme.dart';

class FilesPage extends StatefulWidget {
  const FilesPage({super.key});

  @override
  State<FilesPage> createState() => _FilesPageState();
}

class _FilesPageState extends State<FilesPage> {
  String _currentPath = '/storage/emulated/0';
  List<FileSystemEntity> _items = [];
  List<String> _pathHistory = [];

  @override
  void initState() {
    super.initState();
    _browsePath(_currentPath);
  }

  Future<void> _browsePath(String path) async {
    try {
      final dir = Directory(path);
      if (!await dir.exists()) return;

      final list = await dir.list().toList();
      list.sort((a, b) {
        final aIsDir = a is Directory;
        final bIsDir = b is Directory;
        if (aIsDir && !bIsDir) return -1;
        if (!aIsDir && bIsDir) return 1;
        return a.path.compareTo(b.path);
      });

      setState(() {
        _currentPath = path;
        _items = list;
      });
    } catch (e) {
      // silently fail
    }
  }

  void _navigateTo(String path) {
    _pathHistory.add(_currentPath);
    _browsePath(path);
  }

  void _goBack() {
    if (_pathHistory.isNotEmpty) {
      final prevPath = _pathHistory.removeLast();
      _browsePath(prevPath);
    } else {
      final parent = Directory(_currentPath).parent.path;
      _browsePath(parent);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildBreadcrumb(),
        Expanded(child: _buildFileList()),
      ],
    );
  }

  Widget _buildBreadcrumb() {
    return GlassContainer(
      margin: const EdgeInsets.all(12),
      shape: LiquidRoundedSuperellipse(borderRadius: 14),
      quality: GlassQuality.standard,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            if (_currentPath != '/')
              GestureDetector(
                onTap: _goBack,
                child: const Icon(
                  Icons.arrow_back,
                  color: Colors.white70,
                  size: 20,
                ),
              ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _currentPath,
                style: AppTheme.textStyle(fontSize: 12, color: Colors.white60),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileList() {
    if (_items.isEmpty) {
      return Center(
        child: Text(
          '此目录为空',
          style: AppTheme.textStyle(
            fontSize: 15,
            color: Colors.white.withValues(alpha: 0.5),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: _items.length,
      itemBuilder: (context, index) {
        final item = _items[index];
        final isDir = item is Directory;
        final name = item.path.split('/').last.split('\\').last;

        return GlassContainer(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          shape: LiquidRoundedSuperellipse(borderRadius: 12),
          quality: GlassQuality.standard,
          child: ListTile(
            leading: Icon(
              isDir ? Icons.folder : Icons.music_note,
              color: isDir
                  ? Colors.amber.withValues(alpha: 0.8)
                  : Colors.white54,
              size: 24,
            ),
            title: Text(
              name,
              style: AppTheme.textStyle(fontSize: 14),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: const Icon(Icons.chevron_right, color: Colors.white30),
            onTap: () {
              if (isDir) {
                _navigateTo(item.path);
              }
            },
          ),
        );
      },
    );
  }
}
