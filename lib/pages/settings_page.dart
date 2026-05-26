import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/app_state.dart';
import 'scan_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, _) {
        return ListView(
          padding: const EdgeInsets.only(bottom: 80),
          children: [
            const SizedBox(height: 16),
            _buildSectionHeader('音乐库'),
            _buildSettingsItem(
              context,
              icon: Icons.folder_open,
              title: '扫描曲目',
              subtitle: '选择文件夹并扫描音乐文件',
              onTap: () => _navigateToScan(context),
            ),
            _buildSettingsItem(
              context,
              icon: Icons.refresh,
              title: '重新扫描',
              subtitle:
                  '${appState.scanFolders.length}个文件夹 · ${appState.tracks.length}首曲目',
              onTap: () {
                if (appState.scanFolders.isNotEmpty) {
                  appState.rescanAll();
                } else {
                  _navigateToScan(context);
                }
              },
            ),
            const SizedBox(height: 8),
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

  void _navigateToScan(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ScanPage()),
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
