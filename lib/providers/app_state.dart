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
  bool _isProcessingMetadata = false;
  bool _isBuildingCategories = false;
  int _currentPageIndex = 0;
  int _scanProgress = 0;
  int _scanTotal = 0;
  String _scanStatus = '';

  List<Track> _tracks = [];
  List<Album> _albums = [];
  List<Artist> _artists = [];
  List<ScanFolder> _scanFolders = [];

  bool get isFirstLaunch => _isFirstLaunch;
  bool get isScanning => _isScanning;
  bool get isProcessingMetadata => _isProcessingMetadata;
  bool get isBuildingCategories => _isBuildingCategories;
  int get currentPageIndex => _currentPageIndex;
  int get scanProgress => _scanProgress;
  int get scanTotal => _scanTotal;
  String get scanStatus => _scanStatus;
  List<Track> get tracks => _tracks;
  List<Album> get albums => _albums;
  List<Artist> get artists => _artists;
  List<ScanFolder> get scanFolders => _scanFolders;

  Future<void> init() async {
    _isFirstLaunch = await DatabaseService.isFirstLaunch();
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

  Future<void> startScan(List<String> folderPaths) async {
    _isScanning = true;
    _scanProgress = 0;
    _scanTotal = 0;
    _scanStatus = '正在清空旧数据...';
    notifyListeners();

    try {
      await DatabaseService.clearCategories();
      await DatabaseService.clearTracks();
      _tracks = [];
      _albums = [];
      _artists = [];

      _scanStatus = '正在扫描文件夹...';
      notifyListeners();

      final files = await ScannerService.scanFiles(folderPaths, (found) {
        _scanProgress = found;
        _scanStatus = '已找到 $_scanProgress 个文件';
        notifyListeners();
      });

      if (files.isEmpty) {
        _isScanning = false;
        notifyListeners();
        return;
      }

      _isScanning = false;
      notifyListeners();

      await _processMetadata(files);
    } catch (e) {
      _isScanning = false;
      notifyListeners();
    }
  }

  Future<void> _processMetadata(List<String> files) async {
    _isProcessingMetadata = true;
    _scanProgress = 0;
    _scanTotal = files.length;
    _scanStatus = '正在扫描标签信息...';
    notifyListeners();

    try {
      await ScannerService.processMetadata(files, (processed, total) {
        _scanProgress = processed;
        _scanTotal = total;
        _scanStatus = '处理标签: $processed / $total';
        notifyListeners();
      });

      _isProcessingMetadata = false;
      notifyListeners();

      await _buildCategories();
    } catch (e) {
      _isProcessingMetadata = false;
      notifyListeners();
    }
  }

  Future<void> _buildCategories() async {
    _isBuildingCategories = true;
    _scanStatus = '正在构建归类信息...';
    notifyListeners();

    try {
      await ScannerService.buildCategories((status) {
        _scanStatus = status;
        notifyListeners();
      });

      _isBuildingCategories = false;
      notifyListeners();

      await loadData();
    } catch (e) {
      _isBuildingCategories = false;
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
