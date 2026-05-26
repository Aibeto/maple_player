import 'dart:async';
import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import '../config/theme.dart';
import '../models/track.dart';
import '../services/player_service.dart';
import '../utils/lrc_utils.dart';

class PlayerPage extends StatefulWidget {
  const PlayerPage({super.key});

  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage>
    with SingleTickerProviderStateMixin {
  final PlayerService _playerService = PlayerService();
  final PageController _pageController = PageController();
  StreamSubscription<Duration>? _positionSub;

  double _sliderValue = 0.0;
  bool _isSeeking = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  Future<List<LrcLine>> _loadLrc(Track track) async {
    return loadLrc(track.filePath);
  }

  @override
  Widget build(BuildContext context) {
    return LiquidGlassLayer(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: StreamBuilder<Track?>(
          stream: _playerService.onTrackChanged,
          initialData: _playerService.currentTrack,
          builder: (context, trackSnapshot) {
            final track = trackSnapshot.data;
            if (track == null) {
              return Center(
                child: Text(
                  '未在播放',
                  style: AppTheme.textStyle(
                    fontSize: 16,
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                ),
              );
            }

            return FutureBuilder<List<LrcLine>>(
              future: _loadLrc(track),
              builder: (context, lrcSnapshot) {
                final lrcLines = lrcSnapshot.data ?? [];
                return _buildPlayerContent(track, lrcLines);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildPlayerContent(Track track, List<LrcLine> lrcLines) {
    final hasLrc = lrcLines.isNotEmpty;

    return PageView(
      controller: _pageController,
      children: [
        _buildMainPlayer(track),
        if (hasLrc) _buildLyricsView(track, lrcLines),
      ],
    );
  }

  Widget _buildMainPlayer(Track track) {
    return SafeArea(
      child: Column(
        children: [
          _buildAppBar(track),
          const Spacer(),
          _buildCoverArt(),
          const SizedBox(height: 32),
          _buildTrackTitle(track),
          const SizedBox(height: 8),
          _buildArtistAlbum(track),
          const SizedBox(height: 24),
          _buildProgressBar(),
          const SizedBox(height: 16),
          _buildPlayControls(),
          const Spacer(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildAppBar(Track track) {
    final hasLrc = track.exlrc == 1;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          GlassIconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.keyboard_arrow_down, size: 32),
          ),
          const Spacer(),
          if (hasLrc)
            GlassIconButton(
              onPressed: () {
                _pageController.animateToPage(
                  1,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                );
              },
              icon: const Icon(Icons.lyrics, size: 22),
            ),
        ],
      ),
    );
  }

  Widget _buildCoverArt() {
    return GlassContainer(
      width: 280,
      height: 280,
      shape: LiquidRoundedSuperellipse(borderRadius: 24),
      quality: GlassQuality.premium,
      child: const Center(
        child: Icon(Icons.music_note, color: Colors.white38, size: 80),
      ),
    );
  }

  Widget _buildTrackTitle(Track track) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Text(
        track.title.isNotEmpty ? track.title : '未知曲目',
        style: AppTheme.textStyle(fontSize: 20, fontWeight: FontWeight.w700),
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildArtistAlbum(Track track) {
    final artist = track.artist.isNotEmpty ? track.artist : '-';
    final album = track.album.isNotEmpty ? track.album : '-';
    return Text(
      '$artist · $album',
      style: AppTheme.textStyle(fontSize: 14, color: Colors.white60),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildProgressBar() {
    return StreamBuilder<Duration>(
      stream: _playerService.onPositionChanged,
      initialData: _playerService.position,
      builder: (context, positionSnapshot) {
        final position = positionSnapshot.data ?? Duration.zero;
        final duration = _playerService.duration;
        final totalMs = duration.inMilliseconds;

        if (!_isSeeking) {
          _sliderValue = totalMs > 0
              ? position.inMilliseconds.toDouble() / totalMs.toDouble()
              : 0.0;
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              GlassSlider(
                value: _sliderValue.clamp(0.0, 1.0),
                onChanged: (value) {
                  _isSeeking = true;
                  _sliderValue = value;
                  setState(() {});
                },
                onChangeEnd: (value) {
                  _isSeeking = false;
                  final seekPos = Duration(
                    milliseconds: (value * totalMs).round(),
                  );
                  _playerService.seekTo(seekPos);
                },
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatDuration(position),
                      style: AppTheme.textStyle(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                    Text(
                      _formatDuration(duration),
                      style: AppTheme.textStyle(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPlayControls() {
    return StreamBuilder<bool>(
      stream: _playerService.onPlayingChanged,
      initialData: _playerService.isPlaying,
      builder: (context, snapshot) {
        final isPlaying = snapshot.data ?? false;
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: () => _playerService.previous(),
              child: const Padding(
                padding: EdgeInsets.all(12),
                child: Icon(
                  Icons.skip_previous_rounded,
                  color: Colors.white,
                  size: 40,
                ),
              ),
            ),
            const SizedBox(width: 24),
            GlassContainer(
              width: 72,
              height: 72,
              shape: LiquidRoundedSuperellipse(borderRadius: 36),
              quality: GlassQuality.premium,
              child: GestureDetector(
                onTap: () => _playerService.playPause(),
                child: Icon(
                  isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 36,
                ),
              ),
            ),
            const SizedBox(width: 24),
            GestureDetector(
              onTap: () => _playerService.next(),
              child: const Padding(
                padding: EdgeInsets.all(12),
                child: Icon(
                  Icons.skip_next_rounded,
                  color: Colors.white,
                  size: 40,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLyricsView(Track track, List<LrcLine> lrcLines) {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                GlassIconButton(
                  onPressed: () {
                    _pageController.animateToPage(
                      0,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                    );
                  },
                  icon: const Icon(Icons.album, size: 22),
                ),
                const Spacer(),
                GlassIconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.keyboard_arrow_down, size: 32),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            track.title.isNotEmpty ? track.title : '未知曲目',
            style: AppTheme.textStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            track.artist.isNotEmpty ? track.artist : '-',
            style: AppTheme.textStyle(fontSize: 13, color: Colors.white60),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder<Duration>(
              stream: _playerService.onPositionChanged,
              initialData: _playerService.position,
              builder: (context, snapshot) {
                final position = snapshot.data ?? Duration.zero;
                return _buildLyricsList(lrcLines, position);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLyricsList(List<LrcLine> lrcLines, Duration position) {
    int currentIndex = -1;
    for (int i = 0; i < lrcLines.length; i++) {
      if (lrcLines[i].timestamp <= position) {
        currentIndex = i;
      } else {
        break;
      }
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 80),
      itemCount: lrcLines.length,
      itemBuilder: (context, index) {
        final isCurrent = index == currentIndex;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 24),
          child: Text(
            lrcLines[index].text,
            style: AppTheme.textStyle(
              fontSize: isCurrent ? 17 : 14,
              fontWeight: isCurrent ? FontWeight.w700 : FontWeight.normal,
              color: isCurrent
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.4),
            ),
            textAlign: TextAlign.center,
          ),
        );
      },
    );
  }

  String _formatDuration(Duration d) {
    final min = d.inMinutes.toString().padLeft(2, '0');
    final sec = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$min:$sec';
  }
}
