import 'dart:io';

class LrcLine {
  final Duration timestamp;
  final String text;

  const LrcLine({required this.timestamp, required this.text});
}

List<LrcLine> parseLrc(String lrcContent) {
  final lines = <LrcLine>[];
  final regex = RegExp(r'\[(\d{2}):(\d{2})\.(\d{2,3})\](.*)');

  for (final line in lrcContent.split('\n')) {
    final match = regex.firstMatch(line);
    if (match != null) {
      final min = int.parse(match.group(1)!);
      final sec = int.parse(match.group(2)!);
      final msStr = match.group(3)!;
      final ms = int.parse(msStr.length == 2 ? '${msStr}0' : msStr);
      final text = match.group(4)?.trim() ?? '';

      lines.add(
        LrcLine(
          timestamp: Duration(minutes: min, seconds: sec, milliseconds: ms),
          text: text,
        ),
      );
    }
  }

  lines.sort((a, b) => a.timestamp.compareTo(b.timestamp));
  return lines;
}

Future<List<LrcLine>> loadLrc(String filePath) async {
  final lastSlash = filePath.lastIndexOf('/');
  final lastBackslash = filePath.lastIndexOf('\\');
  final separator = lastSlash > lastBackslash ? '/' : '\\';
  final idx = lastSlash > lastBackslash ? lastSlash : lastBackslash;

  final dir = filePath.substring(0, idx);
  final baseName = filePath.split(separator).last.split('.').first;
  final lrcPath = '$dir${separator}$baseName.lrc';

  try {
    final file = File(lrcPath);
    if (await file.exists()) {
      final content = await file.readAsString();
      return parseLrc(content);
    }
  } catch (e) {
    // LRC not found
  }

  return [];
}

String getCurrentLyric(List<LrcLine> lrcLines, Duration position) {
  if (lrcLines.isEmpty) return '';

  for (int i = lrcLines.length - 1; i >= 0; i--) {
    if (position >= lrcLines[i].timestamp) {
      return lrcLines[i].text;
    }
  }
  return '';
}

int getCurrentLyricIndex(List<LrcLine> lrcLines, Duration position) {
  if (lrcLines.isEmpty) return -1;

  for (int i = lrcLines.length - 1; i >= 0; i--) {
    if (position >= lrcLines[i].timestamp) {
      return i;
    }
  }
  return -1;
}