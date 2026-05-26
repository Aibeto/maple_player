import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../widgets/mini_player.dart';
import '../widgets/scan_dialogs.dart';
import 'tracks_page.dart';
import 'categories_page.dart';
import 'files_page.dart';
import 'settings_page.dart';
import 'player_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  static const _tabs = [
    ('曲目', Icons.music_note),
    ('分类', Icons.category),
    ('文件', Icons.folder),
    ('设置', Icons.settings),
  ];

  void _openPlayer(BuildContext context) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const PlayerPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
                .animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                ),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, _) {
        return Stack(
          children: [
            Scaffold(
              backgroundColor: Colors.transparent,
              body: _buildBody(appState),
              bottomNavigationBar: GlassBottomBar(
                selectedIndex: appState.currentPageIndex,
                onTabSelected: (index) => appState.setPageIndex(index),
                tabs: [
                  for (final tab in _tabs)
                    GlassBottomBarTab(label: tab.$1, icon: Icon(tab.$2)),
                ],
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: kBottomNavigationBarHeight + 4,
              child: MiniPlayer(onTap: () => _openPlayer(context)),
            ),
            if (appState.isScanning ||
                appState.isProcessingMetadata ||
                appState.isBuildingCategories)
              _buildScanOverlay(appState),
          ],
        );
      },
    );
  }

  Widget _buildBody(AppState appState) {
    switch (appState.currentPageIndex) {
      case 0:
        return const TracksPage();
      case 1:
        return const CategoriesPage();
      case 2:
        return const FilesPage();
      case 3:
        return const SettingsPage();
      default:
        return const TracksPage();
    }
  }

  Widget _buildScanOverlay(AppState appState) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.5),
        child: Center(
          child: ScanProgressDialog(
            status: appState.scanStatus,
            progress: appState.scanProgress,
            total: appState.scanTotal,
          ),
        ),
      ),
    );
  }
}
