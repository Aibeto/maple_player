import 'dart:async';
import 'dart:ui' show Color;
import 'package:audio_service/audio_service.dart'
    show AudioService, AudioServiceConfig;
import 'package:just_audio/just_audio.dart';
import '../models/track.dart';
import '../services/database_service.dart';
import 'audio_handler.dart';

class PlayerService {
  static final PlayerService _instance = PlayerService._internal();
  factory PlayerService() => _instance;
  PlayerService._internal();

  MapleAudioHandler? _audioHandler;

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

  Track? get currentTrack => _audioHandler?.currentTrack;
  Duration get position => _audioHandler?.audioPlayer.position ?? Duration.zero;
  Duration get duration => _audioHandler?.audioPlayer.duration ?? Duration.zero;
  bool get isPlaying => _audioHandler?.audioPlayer.playing ?? false;
  List<Track> get queue => _audioHandler?.trackQueue ?? const [];

  Timer? _positionTimer;

  Future<void> init() async {
    _audioHandler = await AudioService.init(
      builder: () => MapleAudioHandler(),
      config: AudioServiceConfig(
        androidNotificationChannelId: 'top.raincrat.maple.player',
        androidNotificationChannelName: 'Maple Player',
        androidNotificationOngoing: true,
        androidShowNotificationBadge: true,
        notificationColor: const Color(0xFF1C1C1E),
      ),
    );

    _audioHandler!.audioPlayer.playerStateStream.listen((state) {
      _playingController.add(state.playing);
      if (state.processingState == ProcessingState.ready) {
        _durationController.add(
          _audioHandler!.audioPlayer.duration ?? Duration.zero,
        );
      }
    });

    startPositionTimer();
  }

  void startPositionTimer() {
    _positionTimer?.cancel();
    _positionTimer = Timer.periodic(const Duration(milliseconds: 200), (_) {
      if (_audioHandler != null) {
        _positionController.add(_audioHandler!.audioPlayer.position);
      }
    });
  }

  void stopPositionTimer() {
    _positionTimer?.cancel();
    _positionTimer = null;
  }

  Future<void> playTrack(Track track) async {
    if (_audioHandler == null) return;
    _trackController.add(track);
    await _audioHandler!.setTrack(track);
    _queueController.add(queue);

    await DatabaseService.updateExlrc(track.filePath, track.exlrc);
  }

  Future<void> playQueue(List<Track> tracks, int startIndex) async {
    if (_audioHandler == null) return;
    final track = tracks[startIndex.clamp(0, tracks.length - 1)];
    _trackController.add(track);
    await _audioHandler!.setQueue(tracks, startIndex);
    _queueController.add(queue);
  }

  Future<void> playPause() async {
    if (_audioHandler == null) return;
    if (isPlaying) {
      await _audioHandler!.pause();
      stopPositionTimer();
    } else {
      await _audioHandler!.play();
      startPositionTimer();
    }
  }

  Future<void> seekTo(Duration position) async {
    if (_audioHandler == null) return;
    await _audioHandler!.seek(position);
  }

  Future<void> next() async {
    if (_audioHandler == null) return;
    await _audioHandler!.skipToNext();
    _trackController.add(_audioHandler!.currentTrack);
  }

  Future<void> previous() async {
    if (_audioHandler == null) return;

    if (position.inSeconds > 3) {
      await _audioHandler!.audioPlayer.seek(Duration.zero);
    } else {
      await _audioHandler!.skipToPrevious();
      _trackController.add(_audioHandler!.currentTrack);
    }
  }

  Future<void> stop() async {
    if (_audioHandler == null) return;
    stopPositionTimer();
    await _audioHandler!.stop();
    _trackController.add(null);
  }

  void dispose() {
    stopPositionTimer();
    _trackController.close();
    _positionController.close();
    _durationController.close();
    _playingController.close();
    _queueController.close();
  }
}
