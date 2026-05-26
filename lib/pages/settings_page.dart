import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/app_state.dart';
import 'scan_page.dart';
import 'background_image_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, _) {
        return ListView(
          padding: const EdgeInsets.only(top: 12),
          children: [
            _buildScanEntry(context, appState),
            const SizedBox(height: 12),
            _buildBackgroundEntry(context, appState),
            const SizedBox(height: 12),
            _buildSectionHeader('扫描文件夹'),
            ...appState.scanFolders.map((folder) {
              return _buildSettingsItem(
                context,
                icon: Icons.folder,
                title: folder.path.split('/').last.split('\\').last,
                subtitle: folder.path,
                trailing: IconButton(
                  icon: const Icon(
                    Icons.close,
                    color: Colors.white30,
                    size: 18,
                  ),
                  onPressed: () => appState.removeScanFolder(folder.path),
                ),
                onTap: () {},
              );
            }),
            if (appState.scanFolders.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Text(
                  '暂未添加扫描文件夹',
                  style: AppTheme.textStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.4),
                  ),
                ),
              ),
            const SizedBox(height: 16),
            _buildSectionHeader('关于'),
            _buildSettingsItem(
              context,
              icon: Icons.info_outline,
              title: 'Maple Player',
              subtitle: 'v0.1.0 · 跨平台音乐播放器',
              onTap: () {},
            ),
          ],
        );
      },
    );
  }

  Widget _buildScanEntry(BuildContext context, AppState appState) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: GestureDetector(
        onTap: () => _navigateToScan(context),
        child: GlassContainer(
          shape: LiquidRoundedSuperellipse(borderRadius: 16),
          quality: GlassQuality.standard,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                GlassContainer(
                  width: 48,
                  height: 48,
                  shape: LiquidRoundedSuperellipse(borderRadius: 14),
                  quality: GlassQuality.premium,
                  child: const Icon(
                    Icons.auto_awesome,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '进入曲目扫描',
                        style: AppTheme.textStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        appState.scanFolders.isEmpty
                            ? '选择文件夹，开始扫描音乐文件'
                            : '${appState.scanFolders.length}个文件夹 · ${appState.tracks.length}首曲目',
                        style: AppTheme.textStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.white30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToScan(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ScanPage()),
    );
  }

  Widget _buildBackgroundEntry(BuildContext context, AppState appState) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: GestureDetector(
        onTap: () => _navigateToBackground(context),
        child: GlassContainer(
          shape: LiquidRoundedSuperellipse(borderRadius: 16),
          quality: GlassQuality.standard,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                GlassContainer(
                  width: 48,
                  height: 48,
                  shape: LiquidRoundedSuperellipse(borderRadius: 14),
                  quality: GlassQuality.premium,
                  child: const Icon(
                    Icons.wallpaper,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '自定义背景',
                        style: AppTheme.textStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        appState.backgroundImagePath != null
                            ? '已设置自定义背景图片'
                            : '设置个性化背景图片',
                        style: AppTheme.textStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.white30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToBackground(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const BackgroundImagePage()),
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

  Widget _buildSettingsItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return GlassContainer(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      shape: LiquidRoundedSuperellipse(borderRadius: 14),
      quality: GlassQuality.standard,
      child: ListTile(
        leading: Icon(icon, color: Colors.white70, size: 22),
        title: Text(
          title,
          style: AppTheme.textStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          subtitle,
          style: AppTheme.textStyle(
            fontSize: 12,
            color: Colors.white.withValues(alpha: 0.5),
          ),
        ),
        trailing:
            trailing ?? const Icon(Icons.chevron_right, color: Colors.white30),
        onTap: onTap,
      ),
    );
  }
}
