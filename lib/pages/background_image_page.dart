import 'dart:io';
import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/app_state.dart';

class BackgroundImagePage extends StatelessWidget {
  const BackgroundImagePage({super.key});

  Future<void> _pickImage(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'webp', 'bmp'],
    );
    if (result != null && result.files.isNotEmpty) {
      final filePath = result.files.single.path;
      if (filePath != null && context.mounted) {
        context.read<AppState>().setBackgroundImagePath(filePath);
      }
    }
  }

  Future<void> _clearBackground(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1E),
        title: const Text('确认清除', style: TextStyle(color: Colors.white)),
        content: const Text(
          '确定要清除自定义背景图片吗？',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('确定', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (confirm == true && context.mounted) {
      context.read<AppState>().clearBackgroundImage();
    }
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
          '自定义背景',
          style: AppTheme.textStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
      ),
      body: Consumer<AppState>(
        builder: (context, appState, _) {
          final hasBg = appState.backgroundImagePath != null;
          return ListView(
            padding: const EdgeInsets.only(top: 12),
            children: [
              if (hasBg) _buildPreviewCard(context, appState),
              const SizedBox(height: 12),
              _buildSectionHeader('背景图片设置'),
              _buildActionCard(
                context,
                icon: Icons.add_photo_alternate_outlined,
                title: '选择背景图片',
                subtitle: hasBg ? '点击更换背景图片' : '从设备中选择一张图片作为背景',
                onTap: () => _pickImage(context),
              ),
              if (hasBg)
                _buildActionCard(
                  context,
                  icon: Icons.delete_outline,
                  title: '清除背景图片',
                  subtitle: '恢复为默认背景',
                  onTap: () => _clearBackground(context),
                  isDestructive: true,
                ),
              const SizedBox(height: 12),
              _buildSectionHeader('预览'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: _buildPreviewInfo(hasBg, appState),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPreviewCard(BuildContext context, AppState appState) {
    final file = File(appState.backgroundImagePath!);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: GlassContainer(
        height: 180,
        shape: LiquidRoundedSuperellipse(borderRadius: 16),
        quality: GlassQuality.standard,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (file.existsSync())
                Image.file(file, fit: BoxFit.cover),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.6),
                    ],
                  ),
                ),
              ),
              const Positioned(
                bottom: 12,
                left: 16,
                child: Text(
                  '当前背景',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Text(
        title,
        style: AppTheme.textStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Colors.white.withValues(alpha: 0.4),
        ),
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return GlassContainer(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      shape: LiquidRoundedSuperellipse(borderRadius: 14),
      quality: GlassQuality.standard,
      child: ListTile(
        leading: Icon(
          icon,
          color: isDestructive ? Colors.redAccent : Colors.white70,
          size: 22,
        ),
        title: Text(
          title,
          style: AppTheme.textStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isDestructive ? Colors.redAccent : Colors.white,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: AppTheme.textStyle(
            fontSize: 12,
            color: Colors.white.withValues(alpha: 0.5),
          ),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.white30),
        onTap: onTap,
      ),
    );
  }

  Widget _buildPreviewInfo(bool hasBg, AppState appState) {
    return GlassContainer(
      shape: LiquidRoundedSuperellipse(borderRadius: 14),
      quality: GlassQuality.standard,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  hasBg ? Icons.check_circle : Icons.info_outline,
                  color: hasBg ? Colors.greenAccent : Colors.white30,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  hasBg ? '已设置自定义背景' : '未设置自定义背景',
                  style: AppTheme.textStyle(fontSize: 13),
                ),
              ],
            ),
            if (hasBg) ...[
              const SizedBox(height: 8),
              Text(
                appState.backgroundImagePath!,
                style: AppTheme.textStyle(
                  fontSize: 11,
                  color: Colors.white.withValues(alpha: 0.4),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}