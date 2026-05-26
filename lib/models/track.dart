class Track {
  final int? id;
  final String title;
  final String artist;
  final String album;
  final String year;
  final String filePath;
  final String md5;
  final int playCount;
  final int exlrc;

  Track({
    this.id,
    required this.title,
    required this.artist,
    required this.album,
    required this.year,
    required this.filePath,
    required this.md5,
    this.playCount = 0,
    this.exlrc = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'album': album,
      'year': year,
      'file_path': filePath,
      'md5': md5,
      'play_count': playCount,
      'exlrc': exlrc,
    };
  }

  factory Track.fromMap(Map<String, dynamic> map) {
    return Track(
      id: map['id'] as int?,
      title: (map['title'] as String?) ?? '',
      artist: (map['artist'] as String?) ?? '',
      album: (map['album'] as String?) ?? '',
      year: (map['year'] as String?) ?? '',
      filePath: (map['file_path'] as String?) ?? '',
      md5: (map['md5'] as String?) ?? '',
      playCount: (map['play_count'] as int?) ?? 0,
      exlrc: (map['exlrc'] as int?) ?? 0,
    );
  }

  Track copyWith({
    int? id,
    String? title,
    String? artist,
    String? album,
    String? year,
    String? filePath,
    String? md5,
    int? playCount,
    int? exlrc,
  }) {
    return Track(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      year: year ?? this.year,
      filePath: filePath ?? this.filePath,
      md5: md5 ?? this.md5,
      playCount: playCount ?? this.playCount,
      exlrc: exlrc ?? this.exlrc,
    );
  }
}
