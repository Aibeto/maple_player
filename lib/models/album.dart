class Album {
  final int? id;
  final String name;
  final String artist;
  final String year;
  final List<String> trackTitles;

  Album({
    this.id,
    required this.name,
    this.artist = '',
    this.year = '',
    this.trackTitles = const [],
  });

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name, 'artist': artist, 'year': year};
  }

  factory Album.fromMap(
    Map<String, dynamic> map, [
    List<String> tracks = const [],
  ]) {
    return Album(
      id: map['id'] as int?,
      name: (map['name'] as String?) ?? '',
      artist: (map['artist'] as String?) ?? '',
      year: (map['year'] as String?) ?? '',
      trackTitles: tracks,
    );
  }
}
