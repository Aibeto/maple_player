import 'dart:io';
import 'package:path/path.dart' as p;
import '../config/constants.dart';

bool isAudioFile(String filePath) {
  final ext = p.extension(filePath).toLowerCase();
  return AppConstants.audioExtensions.contains(ext);
}

bool hasId3v2(List<int> bytes) {
  if (bytes.length < 10) return false;
  return bytes[0] == 0x49 && bytes[1] == 0x44 && bytes[2] == 0x33;
}

bool hasId3v1(List<int> bytes) {
  if (bytes.length < 128) return false;
  final offset = bytes.length - 128;
  return bytes[offset] == 0x54 &&
      bytes[offset + 1] == 0x41 &&
      bytes[offset + 2] == 0x47;
}

String readLatin1(List<int> bytes) {
  return String.fromCharCodes(bytes.where((b) => b != 0));
}

String readUtf16LE(List<int> bytes, int start) {
  final chars = <int>[];
  for (int i = start; i < bytes.length - 1; i += 2) {
    final c = bytes[i] | (bytes[i + 1] << 8);
    if (c == 0) break;
    chars.add(c);
  }
  return String.fromCharCodes(chars);
}

String readUtf16BE(List<int> bytes, int start) {
  final chars = <int>[];
  for (int i = start; i < bytes.length - 1; i += 2) {
    final c = (bytes[i] << 8) | bytes[i + 1];
    if (c == 0) break;
    chars.add(c);
  }
  return String.fromCharCodes(chars);
}

Map<String, String> parseId3v2(List<int> bytes) {
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
        content = readUtf16LE(contentBytes, 2);
      } else if (bom == 0xFEFF) {
        content = readUtf16BE(contentBytes, 2);
      } else {
        content = readLatin1(contentBytes);
      }
    } else {
      content = readLatin1(contentBytes);
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
          result['year'] =
              content.length >= 4 ? content.substring(0, 4) : content;
        }
        break;
    }

    offset += size;
  }

  return result;
}

Map<String, String> parseId3v1(List<int> bytes) {
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

Map<String, String> extractMetadata(File file) {
  final result = <String, String>{};

  try {
    final bytes = file.readAsBytesSync();

    if (hasId3v2(bytes)) {
      result.addAll(parseId3v2(bytes));
    }

    if (hasId3v1(bytes)) {
      final tagData = parseId3v1(bytes);
      for (final key in tagData.keys) {
        result.putIfAbsent(key, () => tagData[key]!);
      }
    }
  } catch (e) {
    // metadata extraction failed
  }

  return result;
}

bool checkLrcExists(String audioFilePath) {
  final dir = p.dirname(audioFilePath);
  final baseName = p.basenameWithoutExtension(audioFilePath);
  final lrcPath = p.join(dir, '$baseName.lrc');
  return File(lrcPath).existsSync();
}

List<String> getAudioExtensions() {
  return AppConstants.audioExtensions;
}