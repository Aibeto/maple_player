import 'package:flutter/material.dart';
import '../models/track.dart';
import '../models/album.dart';
import '../models/artist.dart';
import '../models/scan_folder.dart';
import '../services/database_service.dart';
import '../services/scanner_service.dart';
import '../services/player_service.dart';

class AppState extends ChangeNotifier {
  final PlayerService playerService = PlayerService();

  bool _isFirstLaunch = true;
  bool _isScanning = false;
  int _currentPageIndex = 0;
  int _scanProgress = 0;
  int _scanTotal = 0;
  String _scanStatus = '';
  String _currentProcessingFile = '';
  final List<String> _recentProcessedFiles = [];
  static const int _maxRecentFiles = 20;

  List<Track> _tracks = [];
  List<Album> _albums = [];
  List<Artist> _artists = [];
  List<ScanFolder> _scanFolders = [];

  bool get isFirstLaunch => _isFirstLaunch;
  bool get isScanning => _isScanning;
  int get currentPageIndex => _currentPageIndex;
  int get scanProgress => _scanProgress;
  int get scanTotal => _scanTotal;
  String get scanStatus => _scanStatus;
  String get currentProcessingFile => _currentProcessingFile;
  List<String> get recentProcessedFiles =>
      List.unmodifiable(_recentProcessedFiles);
  List<Track> get tracks => _tracks;
  List<Album> get albums => _albums;
  List<Artist> get artists => _artists;
  List<ScanFolder> get scanFolders => _scanFolders;

  String? _backgroundImagePath;
  String? get backgroundImagePath => _backgroundImagePath;

  Future<void> init() async {
    _isFirstLaunch = await DatabaseService.isFirstLaunch();
    _backgroundImagePath = await DatabaseService.getBackgroundImagePath();
    if (!_isFirstLaunch) {
      await loadData();
    }
    _scanFolders = await DatabaseService.getScanFolders();
    notifyListeners();
  }

  Future<void> loadData() async {
    _tracks = await DatabaseService.getAllTracks();
    _albums = await DatabaseService.getAllAlbums();
    _artists = await DatabaseService.getAllArtists();
    _scanFolders = await DatabaseService.getScanFolders();
    _isFirstLaunch = _tracks.isEmpty;
    notifyListeners();
  }

  void setPageIndex(int index) {
    _currentPageIndex = index;
    notifyListeners();
  }

  Future<void> setBackgroundImagePath(String? path) async {
    _backgroundImagePath = path;
    await DatabaseService.setBackgroundImagePath(path);
    notifyListeners();
  }

  Future<void> clearBackgroundImage() async {
    _backgroundImagePath = null;
    await DatabaseService.setBackgroundImagePath(null);
    notifyListeners();
  }

  Future<void> startScan(List<String> folderPaths) async {
    _isScanning = true;
    _scanProgress = 0;
    _scanTotal = 0;
    _scanStatus = '正在扫描文件夹...';
    _currentProcessingFile = '';
    _recentProcessedFiles.clear();
    notifyListeners();

    try {
      await DatabaseService.clearCategories();
      await DatabaseService.clearTracks();
      _tracks = [];
      _albums = [];
      _artists = [];

      await ScannerService.scanAndProcess(
        folderPaths,
        (filePath) {
          _currentProcessingFile = filePath.split('/').last.split('\\').last;
          notifyListeners();
        },
        (fileName, processed, total) {
          _scanProgress = processed;
          _scanTotal = total;
          _scanStatus = '处理标签: $processed / $total';
          if (fileName.isNotEmpty) {
            _recentProcessedFiles.add(fileName);
            if (_recentProcessedFiles.length > _maxRecentFiles) {
              _recentProcessedFiles.removeAt(0);
            }
          }
          notifyListeners();
        },
      );

      _scanStatus = '正在构建归类...';
      notifyListeners();

      _isScanning = false;
      notifyListeners();

      await loadData();
    } catch (e) {
      _isScanning = false;
      notifyListeners();
    }
  }

  Future<void> addScanFolder(String path) async {
    final folder = ScanFolder(path: path);
    await DatabaseService.insertScanFolder(folder);
    _scanFolders = await DatabaseService.getScanFolders();
    notifyListeners();
  }

  Future<void> removeScanFolder(String path) async {
    await DatabaseService.removeScanFolder(path);
    _scanFolders = await DatabaseService.getScanFolders();
    notifyListeners();
  }

  Future<void> rescanAll() async {
    if (_scanFolders.isEmpty) return;
    final paths = _scanFolders.map((f) => f.path).toList();
    await startScan(paths);
  }
}