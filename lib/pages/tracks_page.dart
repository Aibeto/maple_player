import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../models/track.dart';
import '../providers/app_state.dart';
import '../widgets/alphabet_nav.dart';
import '../widgets/track_list_item.dart';

class TracksPage extends StatefulWidget {
  const TracksPage({super.key});

  @override
  State<TracksPage> createState() => _TracksPageState();
}

class _TracksPageState extends State<TracksPage> {
  String? _selectedLetter;
  final Map<String, int> _letterIndices = {};
  final ScrollController _scrollController = ScrollController();

  static final _chineseRegex = RegExp(r'^[\u4e00-\u9fff]');
  static final _japaneseRegex = RegExp(r'^[\u3040-\u309f\u30a0-\u30ff]');
  static final _alphaRegex = RegExp(r'^[a-zA-Z]');

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  List<String> _getAllLetters(List<Track> tracks) {
    final letters = <String>{};
    for (final track in tracks) {
      final fl = _getFirstLetter(track);
      letters.add(fl);
    }

    final sorted = letters.toList()
      ..sort((a, b) {
        if (a == '#') return 1;
        if (b == '#') return -1;
        return a.compareTo(b);
      });

    return sorted;
  }

  String _getFirstLetter(Track track) {
    final name = track.title.isNotEmpty
        ? track.title
        : track.filePath.split('/').last.split('\\').last;
    if (name.isEmpty) return '#';

    final first = name[0];

    if (_chineseRegex.hasMatch(first)) {
      final code = first.codeUnitAt(0);
      if (code >= 0x4e00 && code <= 0x9fff) {
        return String.fromCharCode(
          'A'.codeUnitAt(0) + ((code - 0x4e00) / 500).floor().clamp(0, 25),
        );
      }
      return 'A';
    } else if (_alphaRegex.hasMatch(first)) {
      return first.toUpperCase();
    } else if (_japaneseRegex.hasMatch(first)) {
      final code = first.codeUnitAt(0);
      if (code >= 0x3040 && code <= 0x309f) {
        return String.fromCharCode(
          'A'.codeUnitAt(0) + ((code - 0x3040) / 4).floor().clamp(0, 25),
        );
      } else {
        return String.fromCharCode(
          'A'.codeUnitAt(0) + ((code - 0x30a0) / 4).floor().clamp(0, 25),
        );
      }
    }

    return '#';
  }

  List<Track> _sortTracks(List<Track> tracks) {
    final sorted = List<Track>.from(tracks);
    sorted.sort((a, b) {
      final nameA = a.title.isNotEmpty
          ? a.title
          : a.filePath.split('/').last.split('\\').last;
      final nameB = b.title.isNotEmpty
          ? b.title
          : b.filePath.split('/').last.split('\\').last;

      final flA = _getFirstLetter(a);
      final flB = _getFirstLetter(b);

      if (flA == '#' && flB != '#') return 1;
      if (flA != '#' && flB == '#') return -1;
      if (flA != flB) return flA.compareTo(flB);

      return nameA.compareTo(nameB);
    });
    return sorted;
  }

  void _buildLetterIndices(List<Track> tracks) {
    _letterIndices.clear();
    for (int i = 0; i < tracks.length; i++) {
      final letter = _getFirstLetter(tracks[i]);
      _letterIndices.putIfAbsent(letter, () => i);
    }
  }

  void _scrollToLetter(String letter) {
    setState(() => _selectedLetter = letter);
    final index = _letterIndices[letter];
    if (index != null && _scrollController.hasClients) {
      _scrollController.animateTo(
        index * 73.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, _) {
        final tracks = _sortTracks(appState.tracks);
        _buildLetterIndices(tracks);
        final letters = _getAllLetters(tracks);

        if (tracks.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.music_note, size: 64, color: Colors.white30),
                const SizedBox(height: 16),
                Text(
                  '暂无曲目',
                  style: AppTheme.textStyle(
                    fontSize: 16,
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '在设置中扫描音乐文件',
                  style: AppTheme.textStyle(
                    fontSize: 13,
                    color: Colors.white30,
                  ),
                ),
              ],
            ),
          );
        }

        return Stack(
          children: [
            ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.only(top: 8, bottom: 80, right: 28),
              itemCount: tracks.length,
              itemBuilder: (context, index) {
                return TrackListItem(track: tracks[index], onMoreTap: () {});
              },
            ),
            if (letters.length > 1)
              AlphabetNav(
                letters: letters,
                selectedLetter: _selectedLetter,
                onLetterTap: _scrollToLetter,
              ),
          ],
        );
      },
    );
  }
}
