import 'dart:io';
import 'dart:isolate';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import '../config/constants.dart';
import '../models/track.dart';
import 'database_service.dart';

bool _isAudioFile(String filePath) {
  final ext = p.extension(filePath).toLowerCase();
  return AppConstants.audioExtensions.contains(ext);
}

String _computeMd5Sync(File file) {
  final bytes = file.readAsBytesSync();
  return md5.convert(bytes).toString();
}

bool _hasId3v2(List<int> bytes) {
  if (bytes.length < 10) return false;
  return bytes[0] == 0x49 && bytes[1] == 0x44 && bytes[2] == 0x33;
}

bool _hasId3v1(List<int> bytes) {
  if (bytes.length < 128) return false;
  final offset = bytes.length - 128;
  return bytes[offset] == 0x54 &&
      bytes[offset + 1] == 0x41 &&
      bytes[offset + 2] == 0x47;
}

String _readLatin1(List<int> bytes) {
  return String.fromCharCodes(bytes.where((b) => b != 0));
}

String _readUtf16LE(List<int> bytes, int start) {
  final chars = <int>[];
  for (int i = start; i < bytes.length - 1; i += 2) {
    final c = bytes[i] | (bytes[i + 1] << 8);
    if (c == 0) break;
    chars.add(c);
  }
  return String.fromCharCodes(chars);
}

String _readUtf16BE(List<int> bytes, int start) {
  final chars = <int>[];
  for (int i = start; i < bytes.length - 1; i += 2) {
    final c = (bytes[i] << 8) | bytes[i + 1];
    if (c == 0) break;
    chars.add(c);
  }
  return String.fromCharCodes(chars);
}

Map<String, String> _parseId3v2(List<int> bytes) {
  final result = <String, String>{};
  int offset = 0;

  if (bytes.length < 10) return result;
  offset = 10;

  while (offset < bytes.length - 10) {
    final frameId = String.fromCharCodes(bytes.sublist(offset, offset + 4));
    offset += 4;

    if (offset + 4 > bytes.length) break;

    int size = 0;
    for (int i = 0; i < 4; i++) {
      size = (size << 7) | (bytes[offset + i] & 0x7F);
    }
    offset += 4;

    if (offset + 2 > bytes.length) break;
    offset += 2;

    if (size <= 0 || offset + size > bytes.length) break;

    final encoding = offset < bytes.length ? bytes[offset] : 0;
    final contentBytes = bytes.sublist(offset + 1, offset + size);

    String content;
    if (encoding == 0x01 && contentBytes.length >= 2) {
      final bom = (contentBytes[0] << 8) | contentBytes[1];
      if (bom == 0xFFFE) {
        content = _readUtf16LE(contentBytes, 2);
      } else if (bom == 0xFEFF) {
        content = _readUtf16BE(contentBytes, 2);
      } else {
        content = _readLatin1(contentBytes);
      }
    } else {
      content = _readLatin1(contentBytes);
    }

    content = content.replaceAll(RegExp(r'\x00+$'), '').trim();

    switch (frameId) {
      case 'TIT2':
        result['title'] = content;
        break;
      case 'TPE1':
        result['artist'] = content;
        break;
      case 'TALB':
        result['album'] = content;
        break;
      case 'TYER':
        result['year'] = content;
        break;
      case 'TDRC':
        if (!result.containsKey('year') || result['year']!.length < 4) {
          result['year'] = content.length >= 4
              ? content.substring(0, 4)
              : content;
        }
        break;
    }

    offset += size;
  }

  return result;
}

Map<String, String> _parseId3v1(List<int> bytes) {
  final result = <String, String>{};
  final offset = bytes.length - 128;

  String readField(int start, int length) {
    final chars = bytes.sublist(offset + start, offset + start + length);
    return String.fromCharCodes(chars.where((b) => b != 0)).trim();
  }

  final title = readField(3, 30);
  final artist = readField(33, 30);
  final album = readField(63, 30);
  final year = readField(93, 4);

  if (title.isNotEmpty) result['title'] = title;
  if (artist.isNotEmpty) result['artist'] = artist;
  if (album.isNotEmpty) result['album'] = album;
  if (year.isNotEmpty) result['year'] = year;

  return result;
}

Map<String, String> _extractMetadataSync(File file) {
  final result = <String, String>{};

  try {
    final bytes = file.readAsBytesSync();

    if (_hasId3v2(bytes)) {
      result.addAll(_parseId3v2(bytes));
    }

    if (_hasId3v1(bytes)) {
      final tagData = _parseId3v1(bytes);
      for (final key in tagData.keys) {
        result.putIfAbsent(key, () => tagData[key]!);
      }
    }
  } catch (e) {
    // metadata extraction failed, use filename
  }

  return result;
}

bool _checkLrcExists(String audioFilePath) {
  final dir = p.dirname(audioFilePath);
  final baseName = p.basenameWithoutExtension(audioFilePath);
  final lrcPath = p.join(dir, '$baseName.lrc');
  return File(lrcPath).existsSync();
}

Future<List<Map<String, dynamic>>> _processBatchInIsolate(
  List<String> paths,
) async {
  final results = <Map<String, dynamic>>[];

  for (final filePath in paths) {
    try {
      final file = File(filePath);
      if (!file.existsSync()) continue;

      final md5Hash = _computeMd5Sync(file);
      final metadata = _extractMetadataSync(file);
      final fileName = p.basenameWithoutExtension(filePath);
      final lrcExists = _checkLrcExists(filePath);

      results.add({
        'title': metadata['title'] ?? fileName,
        'artist': metadata['artist'] ?? '',
        'album': metadata['album'] ?? '',
        'year': metadata['year'] ?? '',
        'file_path': filePath,
        'md5': md5Hash,
        'play_count': 0,
        'exlrc': lrcExists ? 1 : 0,
      });
    } catch (e) {
      // skip files that can't be processed
    }
  }

  return results;
}

class ScannerService {
  static Future<int> scanAndProcess(
    List<String> folderPaths,
    void Function(String filePath) onFileFound,
    void Function(String fileName, int processed, int total) onProgress,
  ) async {
    int newCount = 0;
    final allFilePaths = <String>[];
    final visited = <String>{};

    for (final folderPath in folderPaths) {
      final stack = <String>[folderPath];

      while (stack.isNotEmpty) {
        final dirPath = stack.removeLast();
        if (visited.contains(dirPath)) continue;
        visited.add(dirPath);

        Directory dir;
        try {
          dir = Directory(dirPath);
          if (!await dir.exists()) continue;
        } catch (e) {
          continue;
        }

        try {
          await for (final entity in dir.list()) {
            if (entity is File && _isAudioFile(entity.path)) {
              allFilePaths.add(entity.path);
              onFileFound(entity.path);
            } else if (entity is Directory) {
              stack.add(entity.path);
            }
          }
        } catch (e) {
          continue;
        }
      }
    }

    final total = allFilePaths.length;

    if (allFilePaths.isEmpty) {
      await _buildCategoriesInternal();
      return 0;
    }

    final cpuCount = Platform.numberOfProcessors;
    final batchSize = (total / cpuCount).ceil().clamp(1, 50);

    final batches = <List<String>>[];
    for (int i = 0; i < total; i += batchSize) {
      final end = (i + batchSize).clamp(0, total);
      batches.add(allFilePaths.sublist(i, end));
    }

    int processed = 0;

    final futures = batches.map((batch) async {
      final results = await Isolate.run(() => _processBatchInIsolate(batch));
      return results;
    });

    final allResults = await Future.wait(futures);

    for (final batchResults in allResults) {
      for (final map in batchResults) {
        try {
          final track = Track(
            title: map['title'] as String,
            artist: map['artist'] as String,
            album: map['album'] as String,
            year: map['year'] as String,
            filePath: map['file_path'] as String,
            md5: map['md5'] as String,
            playCount: map['play_count'] as int,
            exlrc: map['exlrc'] as int,
          );

          await DatabaseService.insertTrack(track);
          newCount++;

          final fileName = p.basename(track.filePath);
          processed++;
          onProgress(fileName, processed, total);
        } catch (e) {
          processed++;
          onProgress('', processed, total);
        }
      }
    }

    await _buildCategoriesInternal();
    return newCount;
  }

  static Future<void> _buildCategoriesInternal() async {
    await _buildAlbums();
    await _buildArtists();
  }

  static Future<void> _buildAlbums() async {
    final tracks = await DatabaseService.getAllTracks();
    final albumMap = <String, List<Track>>{};

    for (final track in tracks) {
      if (track.album.isEmpty) continue;
      albumMap.putIfAbsent(track.album, () => []).add(track);
    }

    await DatabaseService.clearCategories();

    for (final entry in albumMap.entries) {
      final albumName = entry.key;
      final albumTracks = entry.value;
      final titles = albumTracks.map((t) => t.title).toList();

      final artists = albumTracks
          .where((t) => t.artist.isNotEmpty)
          .map((t) => t.artist)
          .toSet();
      final years = albumTracks
          .where((t) => t.year.isNotEmpty)
          .map((t) => t.year)
          .toSet();

      final artist = artists.length == 1 ? artists.first : '';
      final year = years.length == 1 ? years.first : '';

      await DatabaseService.insertAlbum(albumName, artist, year, titles);
    }
  }

  static Future<void> _buildArtists() async {
    final tracks = await DatabaseService.getAllTracks();
    final artistMap = <String, Set<String>>{};

    for (final track in tracks) {
      if (track.artist.isEmpty) continue;
      artistMap.putIfAbsent(track.artist, () => {}).add(track.title);
    }

    for (final entry in artistMap.entries) {
      await DatabaseService.insertArtist(entry.key, entry.value.toList());
    }
  }

  static Future<List<String>> scanFiles(
    List<String> folderPaths,
    void Function(int found) onProgress,
  ) async {
    final allFiles = <String>[];
    final stack = folderPaths.toList();
    final visited = <String>{};

    while (stack.isNotEmpty) {
      final dirPath = stack.removeLast();
      if (visited.contains(dirPath)) continue;
      visited.add(dirPath);

      Directory dir;
      try {
        dir = Directory(dirPath);
        if (!await dir.exists()) continue;
      } catch (e) {
        continue;
      }

      try {
        await for (final entity in dir.list()) {
          if (entity is File) {
            if (_isAudioFile(entity.path)) {
              allFiles.add(entity.path);
              onProgress(allFiles.length);
            }
          } else if (entity is Directory) {
            stack.add(entity.path);
          }
        }
      } catch (e) {
        continue;
      }
    }

    return allFiles;
  }

  static Future<int> processMetadata(
    List<String> filePaths,
    void Function(int processed, int total) onProgress,
  ) async {
    if (filePaths.isEmpty) return 0;

    int newCount = 0;
    final cpuCount = Platform.numberOfProcessors;
    final batchSize = (filePaths.length / cpuCount).ceil().clamp(1, 100);

    final batches = <List<String>>[];
    for (int i = 0; i < filePaths.length; i += batchSize) {
      final end = (i + batchSize).clamp(0, filePaths.length);
      batches.add(filePaths.sublist(i, end));
    }

    int totalProcessed = 0;

    final futures = batches.map((batch) async {
      final results = await Isolate.run(() => _processBatchInIsolate(batch));
      return results;
    });

    final allBatchResults = await Future.wait(futures);

    for (final batchResults in allBatchResults) {
      for (final map in batchResults) {
        try {
          final track = Track(
            title: map['title'] as String,
            artist: map['artist'] as String,
            album: map['album'] as String,
            year: map['year'] as String,
            filePath: map['file_path'] as String,
            md5: map['md5'] as String,
            playCount: map['play_count'] as int,
            exlrc: map['exlrc'] as int,
          );

          final exists = await DatabaseService.md5Exists(track.md5);
          if (!exists) {
            await DatabaseService.insertTrack(track);
            newCount++;
          }
        } catch (e) {
          // skip invalid entries
        }
      }

      totalProcessed += batchResults.length;
      onProgress(totalProcessed, filePaths.length);
    }

    return newCount;
  }

  static Future<void> buildCategories(
    void Function(String status) onProgress,
  ) async {
    onProgress('构建专辑信息...');
    await _buildAlbums();

    onProgress('构建艺术家信息...');
    await _buildArtists();
  }
}
