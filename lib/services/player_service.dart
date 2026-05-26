import 'dart:async';
import 'dart:io';
import 'dart:ui' show Color;
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import '../models/track.dart';
import '../services/database_service.dart';
import 'audio_handler.dart';

class PlayerService {
  static final PlayerService _instance = PlayerService._internal();
  factory PlayerService() => _instance;
  PlayerService._internal();

  MapleAudioHandler? _audioHandler;
  AudioPlayer? _directPlayer;
  bool _useAudioService = false;

  final StreamController<Track?> _trackController =
      StreamController<Track?>.broadcast();
  final StreamController<Duration> _positionController =
      StreamController<Duration>.broadcast();
  final StreamController<Duration> _durationController =
      StreamController<Duration>.broadcast();
  final StreamController<bool> _playingController =
      StreamController<bool>.broadcast();
  final StreamController<List<Track>> _queueController =
      StreamController<List<Track>>.broadcast();

  Stream<Track?> get onTrackChanged => _trackController.stream;
  Stream<Duration> get onPositionChanged => _positionController.stream;
  Stream<Duration> get onDurationChanged => _durationController.stream;
  Stream<bool> get onPlayingChanged => _playingController.stream;
  Stream<List<Track>> get onQueueChanged => _queueController.stream;

  Track? get currentTrack {
    if (_useAudioService) {
      return _audioHandler?.currentTrack;
    }
    return _currentTrackDirect;
  }

  Track? _currentTrackDirect;
  final List<Track> _directQueue = [];
  int _directQueueIndex = -1;

  Duration get position {
    final player = _activePlayer;
    return player?.position ?? Duration.zero;
  }

  Duration get duration {
    final player = _activePlayer;
    return player?.duration ?? Duration.zero;
  }

  bool get isPlaying {
    final player = _activePlayer;
    return player?.playing ?? false;
  }

  List<Track> get queue {
    if (_useAudioService) {
      return _audioHandler?.trackQueue ?? const [];
    }
    return List.unmodifiable(_directQueue);
  }

  AudioPlayer? get _activePlayer {
    if (_useAudioService) {
      return _audioHandler?.audioPlayer;
    }
    return _directPlayer;
  }

  Timer? _positionTimer;

  Future<void> init() async {
    final isDesktop = Platform.isWindows || Platform.isLinux;

    if (!isDesktop) {
      try {
        _audioHandler = await AudioService.init(
          builder: () => MapleAudioHandler(),
          config: const AudioServiceConfig(
            androidNotificationChannelId: 'top.raincrat.maple.player',
            androidNotificationChannelName: 'Maple Player',
            androidNotificationOngoing: true,
            androidShowNotificationBadge: true,
            notificationColor: Color(0xFF1C1C1E),
          ),
        );
        _useAudioService = true;

        _audioHandler!.audioPlayer.playerStateStream.listen((state) {
          _playingController.add(state.playing);
          if (state.processingState == ProcessingState.ready) {
            _durationController.add(
              _audioHandler!.audioPlayer.duration ?? Duration.zero,
            );
          }
        });

        startPositionTimer();
        return;
      } catch (e) {
        _useAudioService = false;
      }
    }

    await _initDirectPlayer();
  }

  Future<void> _initDirectPlayer() async {
    _directPlayer = AudioPlayer();

    _directPlayer!.playerStateStream.listen((state) {
      _playingController.add(state.playing);
      if (state.processingState == ProcessingState.ready) {
        _durationController.add(_directPlayer!.duration ?? Duration.zero);
      }
    });

    _directPlayer!.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        _handleDirectCompletion();
      }
    });

    startPositionTimer();
  }

  void _handleDirectCompletion() {
    if (_directQueue.isEmpty) return;
    _directQueueIndex = (_directQueueIndex + 1) % _directQueue.length;
    _playDirectAtIndex(_directQueueIndex);
  }

  Future<void> _playDirectAtIndex(int index) async {
    if (index < 0 || index >= _directQueue.length || _directPlayer == null) {
      return;
    }

    final track = _directQueue[index];
    _currentTrackDirect = track;
    _trackController.add(track);

    try {
      await _directPlayer!.setFilePath(track.filePath);
      await _directPlayer!.play();
    } catch (e) {
      _currentTrackDirect = null;
      _trackController.add(null);
    }
  }

  void startPositionTimer() {
    _positionTimer?.cancel();
    _positionTimer = Timer.periodic(const Duration(milliseconds: 200), (_) {
      final player = _activePlayer;
      if (player != null) {
        _positionController.add(player.position);
      }
    });
  }

  void stopPositionTimer() {
    _positionTimer?.cancel();
    _positionTimer = null;
  }

  Future<void> playTrack(Track track) async {
    if (_useAudioService && _audioHandler != null) {
      _trackController.add(track);
      await _audioHandler!.setTrack(track);
      _queueController.add(queue);
    } else {
      final index = _directQueue.indexWhere(
        (t) => t.filePath == track.filePath,
      );
      if (index >= 0) {
        _directQueueIndex = index;
      } else {
        _directQueue.add(track);
        _directQueueIndex = _directQueue.length - 1;
      }
      await _playDirectAtIndex(_directQueueIndex);
      _queueController.add(queue);
    }

    await DatabaseService.updateExlrc(track.filePath, track.exlrc);
  }

  Future<void> playQueue(List<Track> tracks, int startIndex) async {
    if (_useAudioService && _audioHandler != null) {
      final track = tracks[startIndex.clamp(0, tracks.length - 1)];
      _trackController.add(track);
      await _audioHandler!.setQueue(tracks, startIndex);
      _queueController.add(queue);
    } else {
      _directQueue.clear();
      _directQueue.addAll(tracks);
      _directQueueIndex = startIndex.clamp(0, _directQueue.length - 1);
      await _playDirectAtIndex(_directQueueIndex);
      _queueController.add(queue);
    }
  }

  Future<void> playPause() async {
    final player = _activePlayer;
    if (player == null) return;

    if (isPlaying) {
      if (_useAudioService && _audioHandler != null) {
        await _audioHandler!.pause();
      } else {
        await player.pause();
      }
      stopPositionTimer();
    } else {
      if (_useAudioService && _audioHandler != null) {
        await _audioHandler!.play();
      } else {
        await player.play();
      }
      startPositionTimer();
    }
  }

  Future<void> seekTo(Duration position) async {
    final player = _activePlayer;
    if (player == null) return;
    await player.seek(position);
  }

  Future<void> next() async {
    if (_useAudioService && _audioHandler != null) {
      await _audioHandler!.skipToNext();
      _trackController.add(_audioHandler!.currentTrack);
    } else {
      if (_directQueue.isEmpty) return;
      _directQueueIndex = (_directQueueIndex + 1) % _directQueue.length;
      await _playDirectAtIndex(_directQueueIndex);
    }
  }

  Future<void> previous() async {
    final player = _activePlayer;
    if (player == null) return;

    if (position.inSeconds > 3) {
      await player.seek(Duration.zero);
    } else {
      if (_useAudioService && _audioHandler != null) {
        await _audioHandler!.skipToPrevious();
        _trackController.add(_audioHandler!.currentTrack);
      } else {
        if (_directQueue.isEmpty) return;
        _directQueueIndex =
            (_directQueueIndex - 1 + _directQueue.length) % _directQueue.length;
        await _playDirectAtIndex(_directQueueIndex);
      }
    }
  }

  Future<void> stop() async {
    stopPositionTimer();
    final player = _activePlayer;
    if (player != null) {
      await player.stop();
    }
    if (_useAudioService && _audioHandler != null) {
      await _audioHandler!.stop();
    }
    _currentTrackDirect = null;
    _trackController.add(null);
  }

  void dispose() {
    stopPositionTimer();
    _directPlayer?.dispose();
    _trackController.close();
    _positionController.close();
    _durationController.close();
    _playingController.close();
    _queueController.close();
  }
}
