import 'dart:io';
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
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(0, 0.3),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.92, end: 1.0).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                ),
                child: child,
              ),
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  static const double _miniPlayerHeight = 64;
  static const double _miniPlayerMargin = 8;

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final navBarHeight = kBottomNavigationBarHeight + bottomPadding;
    final miniPlayerOffset = navBarHeight + _miniPlayerMargin;

    return Consumer<AppState>(
      builder: (context, appState, _) {
        return Stack(
          children: [
            _buildBackground(appState),
            Scaffold(
              backgroundColor: Colors.transparent,
              body: _buildBody(
                appState,
                miniPlayerOffset + _miniPlayerHeight + _miniPlayerMargin,
              ),
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
              bottom: miniPlayerOffset,
              child: RepaintBoundary(
                child: MiniPlayer(onTap: () => _openPlayer(context)),
              ),
            ),
            if (appState.isScanning) _buildScanOverlay(appState),
          ],
        );
      },
    );
  }

  Widget _buildBackground(AppState appState) {
    if (appState.backgroundImagePath != null) {
      final file = File(appState.backgroundImagePath!);
      if (file.existsSync()) {
        return Positioned.fill(
          child: Image.file(
            file,
            fit: BoxFit.cover,
            color: Colors.black.withValues(alpha: 0.3),
            colorBlendMode: BlendMode.darken,
          ),
        );
      }
    }
    return const SizedBox.shrink();
  }

  Widget _buildBody(AppState appState, double bottomPadding) {
    return RepaintBoundary(
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.only(bottom: bottomPadding),
          child: IndexedStack(
            index: appState.currentPageIndex,
            children: const [
              TracksPage(),
              CategoriesPage(),
              FilesPage(),
              SettingsPage(),
            ],
          ),
        ),
      ),
    );
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
            currentFile: appState.currentProcessingFile,
            recentFiles: appState.recentProcessedFiles,
          ),
        ),
      ),
    );
  }
}
