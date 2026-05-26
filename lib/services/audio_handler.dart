import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import '../models/track.dart';

class MapleAudioHandler extends BaseAudioHandler with SeekHandler {
  final AudioPlayer _player = AudioPlayer();
  final List<Track> _trackQueue = [];
  int _queueIndex = -1;

  final StreamController<List<Track>> _queueController =
      StreamController<List<Track>>.broadcast();
  Stream<List<Track>> get onQueueChanged => _queueController.stream;

  Track? get currentTrack => _currentTrack;
  Track? _currentTrack;

  List<Track> get trackQueue => List.unmodifiable(_trackQueue);
  AudioPlayer get audioPlayer => _player;

  MapleAudioHandler() {
    _player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        _handleCompletion();
      }
    });

    _player.playbackEventStream.listen(_broadcastState);
  }

  Future<void> setTrack(Track track) async {
    final index = _trackQueue.indexWhere((t) => t.filePath == track.filePath);
    if (index >= 0) {
      _queueIndex = index;
    } else {
      _trackQueue.add(track);
      _queueIndex = _trackQueue.length - 1;
      _queueController.add(trackQueue);
    }

    await _playTrackAtIndex(_queueIndex);
  }

  Future<void> setQueue(List<Track> tracks, int startIndex) async {
    _trackQueue.clear();
    _trackQueue.addAll(tracks);
    _queueIndex = startIndex.clamp(0, _trackQueue.length - 1);
    _queueController.add(trackQueue);
    await _playTrackAtIndex(_queueIndex);
  }

  Future<void> _playTrackAtIndex(int index) async {
    if (index < 0 || index >= _trackQueue.length) return;

    final track = _trackQueue[index];
    _currentTrack = track;

    try {
      await _player.setFilePath(track.filePath);

      mediaItem.add(
        MediaItem(
          id: track.filePath,
          title: track.title.isNotEmpty ? track.title : '未知曲目',
          artist: track.artist.isNotEmpty ? track.artist : '未知艺术家',
          album: track.album.isNotEmpty ? track.album : null,
          duration: _player.duration,
        ),
      );

      await _player.play();
    } catch (e) {
      mediaItem.add(null);
    }
  }

  void _handleCompletion() {
    if (_trackQueue.isEmpty) return;
    _queueIndex = (_queueIndex + 1) % _trackQueue.length;
    _playTrackAtIndex(_queueIndex);
  }

  void _broadcastState(PlaybackEvent event) {
    final playing = _player.playing;
    final processingState = _mapProcessingState(_player.processingState);

    playbackState.add(
      PlaybackState(
        controls: [
          MediaControl.skipToPrevious,
          if (playing) MediaControl.pause else MediaControl.play,
          MediaControl.stop,
          MediaControl.skipToNext,
        ],
        systemActions: const {
          MediaAction.seek,
        },
        androidCompactActionIndices: const [0, 1, 3],
        processingState: processingState,
        playing: playing,
        updatePosition: _player.position,
        bufferedPosition: _player.bufferedPosition,
        speed: _player.speed,
      ),
    );
  }

  AudioProcessingState _mapProcessingState(ProcessingState state) {
    switch (state) {
      case ProcessingState.idle:
        return AudioProcessingState.idle;
      case ProcessingState.loading:
        return AudioProcessingState.loading;
      case ProcessingState.buffering:
        return AudioProcessingState.buffering;
      case ProcessingState.ready:
        return AudioProcessingState.ready;
      case ProcessingState.completed:
        return AudioProcessingState.completed;
    }
  }

  @override
  Future<void> play() async => _player.play();

  @override
  Future<void> pause() async => _player.pause();

  @override
  Future<void> stop() async {
    await _player.stop();
    mediaItem.add(null);
    _currentTrack = null;
  }

  @override
  Future<void> seek(Duration position) async => _player.seek(position);

  @override
  Future<void> skipToNext() async {
    if (_trackQueue.isEmpty) return;
    _queueIndex = (_queueIndex + 1) % _trackQueue.length;
    await _playTrackAtIndex(_queueIndex);
  }

  @override
  Future<void> skipToPrevious() async {
    if (_trackQueue.isEmpty) return;
    if (_player.position.inSeconds > 3) {
      await _player.seek(Duration.zero);
    } else {
      _queueIndex =
          (_queueIndex - 1 + _trackQueue.length) % _trackQueue.length;
      await _playTrackAtIndex(_queueIndex);
    }
  }

  @override
  Future<void> onTaskRemoved() async {
    await _player.stop();
  }
}