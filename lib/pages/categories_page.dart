import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../models/album.dart';
import '../models/artist.dart';
import '../providers/app_state.dart';

class CategoriesPage extends StatefulWidget {
  const CategoriesPage({super.key});

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() => _selectedTabIndex = _tabController.index);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: GlassTabBar(
            selectedIndex: _selectedTabIndex,
            onTabSelected: (index) => _tabController.animateTo(index),
            tabs: const [
              GlassTab(label: '专辑'),
              GlassTab(label: '艺术家'),
            ],
          ),
        ),
        Expanded(
          child: Consumer<AppState>(
            builder: (context, appState, _) {
              return TabBarView(
                controller: _tabController,
                children: [
                  _buildAlbumsList(appState.albums),
                  _buildArtistsList(appState.artists),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAlbumsList(List<Album> albums) {
    if (albums.isEmpty) {
      return Center(
        child: Text(
          '暂无专辑',
          style: AppTheme.textStyle(
            fontSize: 15,
            color: Colors.white.withValues(alpha: 0.5),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: albums.length,
      itemBuilder: (context, index) {
        final album = albums[index];
        return GlassContainer(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          shape: LiquidRoundedSuperellipse(borderRadius: 14),
          quality: GlassQuality.standard,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 48,
                    height: 48,
                    color: Colors.white.withValues(alpha: 0.12),
                    child: const Icon(
                      Icons.album,
                      color: Colors.white54,
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        album.name,
                        style: AppTheme.textStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${album.artist.isNotEmpty ? album.artist + ' · ' : ''}${album.trackTitles.length}首',
                        style: AppTheme.textStyle(
                          fontSize: 12,
                          color: Colors.white60,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.white30),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildArtistsList(List<Artist> artists) {
    if (artists.isEmpty) {
      return Center(
        child: Text(
          '暂无艺术家',
          style: AppTheme.textStyle(
            fontSize: 15,
            color: Colors.white.withValues(alpha: 0.5),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: artists.length,
      itemBuilder: (context, index) {
        final artist = artists[index];
        return GlassContainer(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          shape: LiquidRoundedSuperellipse(borderRadius: 14),
          quality: GlassQuality.standard,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    width: 48,
                    height: 48,
                    color: Colors.white.withValues(alpha: 0.12),
                    child: const Icon(
                      Icons.person,
                      color: Colors.white54,
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        artist.name,
                        style: AppTheme.textStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${artist.trackTitles.length}首',
                        style: AppTheme.textStyle(
                          fontSize: 12,
                          color: Colors.white60,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.white30),
              ],
            ),
          ),
        );
      },
    );
  }
}