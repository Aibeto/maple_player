import 'dart:async';
import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import '../config/theme.dart';
import '../models/track.dart';
import '../services/player_service.dart';
import '../utils/lrc_utils.dart';

class MiniPlayer extends StatefulWidget {
  final VoidCallback onTap;

  const MiniPlayer({super.key, required this.onTap});

  @override
  State<MiniPlayer> createState() => _MiniPlayerState();
}

class _MiniPlayerState extends State<MiniPlayer>
    with SingleTickerProviderStateMixin {
  final PlayerService _playerService = PlayerService();
  StreamSubscription<Track?>? _trackSub;
  StreamSubscription<bool>? _playingSub;
  StreamSubscription<Duration>? _positionSub;
  Track? _track;
  bool _isPlaying = false;
  List<LrcLine> _lrcLines = [];
  String _currentLyric = '';

  @override
  void initState() {
    super.initState();
    _track = _playerService.currentTrack;
    _isPlaying = _playerService.isPlaying;

    _trackSub = _playerService.onTrackChanged.listen((track) {
      if (mounted) {
        setState(() => _track = track);
        _loadLrcForTrack(track);
      }
    });
    _playingSub = _playerService.onPlayingChanged.listen((playing) {
      if (mounted) setState(() => _isPlaying = playing);
    });
    _positionSub = _playerService.onPositionChanged.listen((position) {
      if (mounted && _lrcLines.isNotEmpty) {
        final lyric = getCurrentLyric(_lrcLines, position);
        if (lyric != _currentLyric) {
          setState(() => _currentLyric = lyric);
        }
      }
    });

    if (_track != null) {
      _loadLrcForTrack(_track);
    }
  }

  Future<void> _loadLrcForTrack(Track? track) async {
    _lrcLines = [];
    _currentLyric = '';
    if (track == null || track.exlrc == 0) {
      if (mounted) setState(() {});
      return;
    }
    final lines = await loadLrc(track.filePath);
    if (mounted) {
      setState(() => _lrcLines = lines);
    }
  }

  @override
  void dispose() {
    _trackSub?.cancel();
    _playingSub?.cancel();
    _positionSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_track == null) return const SizedBox.shrink();

    return GestureDetector(
      onTap: widget.onTap,
      child: GlassContainer(
        height: 64,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        shape: LiquidRoundedSuperellipse(borderRadius: 20),
        quality: GlassQuality.standard,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              _buildCover(),
              const SizedBox(width: 12),
              Expanded(child: _buildTrackInfo()),
              _buildControls(),
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
        width: 44,
        height: 44,
        color: Colors.white.withValues(alpha: 0.15),
        child: const Icon(Icons.music_note, color: Colors.white70, size: 24),
      ),
    );
  }

  Widget _buildTrackInfo() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _track!.title.isNotEmpty ? _track!.title : '未知曲目',
          style: AppTheme.textStyle(fontSize: 13, fontWeight: FontWeight.w600),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 1),
        if (_currentLyric.isNotEmpty)
          Text(
            _currentLyric,
            style: AppTheme.textStyle(
              fontSize: 11,
              color: Colors.white.withValues(alpha: 0.5),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          )
        else
          _buildProgressBar(),
      ],
    );
  }

  Widget _buildProgressBar() {
    return StreamBuilder<Duration>(
      stream: _playerService.onPositionChanged,
      initialData: _playerService.position,
      builder: (context, snapshot) {
        final position = snapshot.data ?? Duration.zero;
        final duration = _playerService.duration;
        final progress = duration.inMilliseconds > 0
            ? position.inMilliseconds / duration.inMilliseconds
            : 0.0;

        return Container(
          height: 2,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(1),
            color: Colors.white.withValues(alpha: 0.15),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progress.clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(1),
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildControls() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () => _playerService.previous(),
          child: const Padding(
            padding: EdgeInsets.all(6),
            child: Icon(
              Icons.skip_previous_rounded,
              color: Colors.white,
              size: 26,
            ),
          ),
        ),
        GestureDetector(
          onTap: () => _playerService.playPause(),
          child: GlassContainer(
            width: 40,
            height: 40,
            shape: LiquidRoundedSuperellipse(borderRadius: 20),
            quality: GlassQuality.premium,
            child: Icon(
              _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
        GestureDetector(
          onTap: () => _playerService.next(),
          child: const Padding(
            padding: EdgeInsets.all(6),
            child: Icon(Icons.skip_next_rounded, color: Colors.white, size: 26),
          ),
        ),
      ],
    );
  }
}