import 'dart:async';
import 'package:just_audio/just_audio.dart';
import '../models/track.dart';
import '../services/database_service.dart';

class PlayerService {
  static final PlayerService _instance = PlayerService._internal();
  factory PlayerService() => _instance;
  PlayerService._internal();

  final AudioPlayer _player = AudioPlayer();

  Track? _currentTrack;
  final List<Track> _queue = [];
  int _queueIndex = -1;

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

  Track? get currentTrack => _currentTrack;
  Duration get position => _player.position;
  Duration get duration => _player.duration ?? Duration.zero;
  bool get isPlaying => _player.playing;
  List<Track> get queue => List.unmodifiable(_queue);
  AudioPlayer get audioPlayer => _player;

  Timer? _positionTimer;

  void startPositionTimer() {
    _positionTimer?.cancel();
    _positionTimer = Timer.periodic(const Duration(milliseconds: 200), (_) {
      _positionController.add(_player.position);
    });
  }

  void stopPositionTimer() {
    _positionTimer?.cancel();
    _positionTimer = null;
  }

  Future<void> playTrack(Track track) async {
    final index = _queue.indexWhere((t) => t.filePath == track.filePath);
    if (index >= 0) {
      _queueIndex = index;
    } else {
      _queue.add(track);
      _queueIndex = _queue.length - 1;
      _queueController.add(queue);
    }

    await _playAtIndex(_queueIndex);
  }

  Future<void> playQueue(List<Track> tracks, int startIndex) async {
    _queue.clear();
    _queue.addAll(tracks);
    _queueIndex = startIndex.clamp(0, _queue.length - 1);
    _queueController.add(queue);

    await _playAtIndex(_queueIndex);
  }

  Future<void> _playAtIndex(int index) async {
    if (index < 0 || index >= _queue.length) return;

    final track = _queue[index];
    _currentTrack = track;
    _trackController.add(track);

    try {
      await _player.setFilePath(track.filePath);
      await _player.play();
      startPositionTimer();
      _playingController.add(true);

      await DatabaseService.updateExlrc(track.filePath, track.exlrc);
    } catch (e) {
      _trackController.add(null);
      _playingController.add(false);
    }
  }

  Future<void> playPause() async {
    if (_player.playing) {
      await _player.pause();
      stopPositionTimer();
      _playingController.add(false);
    } else {
      await _player.play();
      startPositionTimer();
      _playingController.add(true);
    }
  }

  Future<void> seekTo(Duration position) async {
    await _player.seek(position);
  }

  Future<void> next() async {
    if (_queue.isEmpty) return;

    _queueIndex = (_queueIndex + 1) % _queue.length;
    await _playAtIndex(_queueIndex);
  }

  Future<void> previous() async {
    if (_queue.isEmpty) return;

    if (_player.position.inSeconds > 3) {
      await _player.seek(Duration.zero);
    } else {
      _queueIndex = (_queueIndex - 1 + _queue.length) % _queue.length;
      await _playAtIndex(_queueIndex);
    }
  }

  Future<void> stop() async {
    stopPositionTimer();
    await _player.stop();
    _currentTrack = null;
    _trackController.add(null);
    _playingController.add(false);
  }

  void dispose() {
    stopPositionTimer();
    _player.dispose();
    _trackController.close();
    _positionController.close();
    _durationController.close();
    _playingController.close();
    _queueController.close();
  }
}
