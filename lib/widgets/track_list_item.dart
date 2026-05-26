import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import '../config/theme.dart';
import '../models/track.dart';
import '../services/player_service.dart';

class TrackListItem extends StatelessWidget {
  final Track track;
  final VoidCallback? onMoreTap;

  const TrackListItem({super.key, required this.track, this.onMoreTap});

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      shape: LiquidRoundedSuperellipse(borderRadius: 14),
      quality: GlassQuality.standard,
      child: InkWell(
        onTap: () {
          PlayerService().playTrack(track);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              _buildCover(),
              const SizedBox(width: 12),
              Expanded(child: _buildInfo()),
              _buildMoreButton(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCover() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 48,
        height: 48,
        color: Colors.white.withValues(alpha: 0.12),
        child: const Icon(Icons.music_note, color: Colors.white54, size: 24),
      ),
    );
  }

  Widget _buildInfo() {
    final artist = track.artist.isNotEmpty ? track.artist : '-';
    final album = track.album.isNotEmpty ? track.album : '-';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          track.title.isNotEmpty
              ? track.title
              : (track.filePath
                    .split('/')
                    .last
                    .split('\\')
                    .last
                    .replaceAll(RegExp(r'\.[^.]+$'), '')),
          style: AppTheme.textStyle(fontSize: 15, fontWeight: FontWeight.w600),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 3),
        Text(
          '$artist · $album',
          style: AppTheme.textStyle(
            fontSize: 12,
            color: Colors.white.withValues(alpha: 0.6),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildMoreButton(BuildContext context) {
    return GestureDetector(
      onTap: () => _showMoreMenu(context),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Icon(
          Icons.more_horiz,
          color: Colors.white.withValues(alpha: 0.6),
          size: 22,
        ),
      ),
    );
  }

  void _showMoreMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => GlassCard(
        margin: const EdgeInsets.all(12),
        shape: LiquidRoundedSuperellipse(borderRadius: 20),
        quality: GlassQuality.standard,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    color: Colors.white30,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildMenuOption(
                ctx,
                icon: Icons.play_arrow,
                label: '播放',
                onTap: () {
                  Navigator.pop(ctx);
                  PlayerService().playTrack(track);
                },
              ),
              _buildMenuOption(
                ctx,
                icon: Icons.queue_music,
                label: '下一首播放',
                onTap: () {
                  Navigator.pop(ctx);
                },
              ),
              _buildMenuOption(
                ctx,
                icon: Icons.info_outline,
                label: '信息',
                onTap: () {
                  Navigator.pop(ctx);
                  _showTrackInfo(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuOption(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 22),
            const SizedBox(width: 14),
            Text(label, style: AppTheme.textStyle(fontSize: 15)),
          ],
        ),
      ),
    );
  }

  void _showTrackInfo(BuildContext context) {
    final file = track.filePath;
    final fileName = file.split('/').last.split('\\').last;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => GlassCard(
        margin: const EdgeInsets.all(12),
        shape: LiquidRoundedSuperellipse(borderRadius: 20),
        quality: GlassQuality.standard,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    color: Colors.white30,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '文件信息',
                style: AppTheme.textStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              _infoRow('文件名', fileName),
              _infoRow('标题', track.title.isNotEmpty ? track.title : '-'),
              _infoRow('艺术家', track.artist.isNotEmpty ? track.artist : '-'),
              _infoRow('专辑', track.album.isNotEmpty ? track.album : '-'),
              _infoRow('年份', track.year.isNotEmpty ? track.year : '-'),
              _infoRow('文件路径', file),
              _infoRow('MD5', track.md5),
              _infoRow('播放次数', '${track.playCount}'),
              _infoRow('外部歌词', track.exlrc == 1 ? '是' : '否'),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: AppTheme.textStyle(
                fontSize: 13,
                color: Colors.white.withValues(alpha: 0.5),
              ),
            ),
          ),
          Expanded(child: Text(value, style: AppTheme.textStyle(fontSize: 13))),
        ],
      ),
    );
  }
}