import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import '../config/theme.dart';
import '../models/track.dart';
import '../services/player_service.dart';
import '../utils/cover_utils.dart';
import '../utils/metadata_utils.dart';

class TrackListItem extends StatefulWidget {
  final Track track;
  final VoidCallback? onMoreTap;

  const TrackListItem({super.key, required this.track, this.onMoreTap});

  @override
  State<TrackListItem> createState() => _TrackListItemState();
}

class _TrackListItemState extends State<TrackListItem> {
  Uint8List? _coverData;

  @override
  void initState() {
    super.initState();
    _loadCover();
  }

  @override
  void didUpdateWidget(covariant TrackListItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.track.filePath != widget.track.filePath) {
      _coverData = null;
      _loadCover();
    }
  }

  Future<void> _loadCover() async {
    final data = extractCoverArtFromPath(widget.track.filePath);
    if (mounted) {
      setState(() {
        _coverData = data;
      });
    }
  }

  Track get track => widget.track;

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
        child: _coverData != null
            ? Image.memory(
                _coverData!,
                width: 48,
                height: 48,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.music_note,
                  color: Colors.white54,
                  size: 24,
                ),
              )
            : const Icon(Icons.music_note, color: Colors.white54, size: 24),
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
    final track = this.track;
    final file = File(track.filePath);
    final fileName = file.path.split('/').last.split('\\').last;

    Map<String, String> realMeta = {};
    int fileSize = 0;
    bool lrcExists = false;

    try {
      if (file.existsSync()) {
        fileSize = file.lengthSync();
        realMeta = extractMetadata(file);
        lrcExists = checkLrcExists(track.filePath);
      }
    } catch (_) {}

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
              _infoRow('文件大小', _formatFileSize(fileSize)),
              _infoRow('文件路径', track.filePath),
              const SizedBox(height: 8),
              Text(
                '实时读取标签',
                style: AppTheme.textStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(height: 8),
              _infoRow(
                '标题',
                realMeta['title']?.isNotEmpty == true
                    ? realMeta['title']!
                    : '-',
              ),
              _infoRow(
                '艺术家',
                realMeta['artist']?.isNotEmpty == true
                    ? realMeta['artist']!
                    : '-',
              ),
              _infoRow(
                '专辑',
                realMeta['album']?.isNotEmpty == true
                    ? realMeta['album']!
                    : '-',
              ),
              _infoRow(
                '年份',
                realMeta['year']?.isNotEmpty == true ? realMeta['year']! : '-',
              ),
              const SizedBox(height: 8),
              Text(
                '数据库记录',
                style: AppTheme.textStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(height: 8),
              _infoRow('MD5', track.md5),
              _infoRow('播放次数', '${track.playCount}'),
              _infoRow('外部歌词', lrcExists ? '是' : '否'),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
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
