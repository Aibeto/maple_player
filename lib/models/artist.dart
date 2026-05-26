class Artist {
  final int? id;
  final String name;
  final List<String> trackTitles;

  Artist({this.id, required this.name, this.trackTitles = const []});

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name};
  }

  factory Artist.fromMap(
    Map<String, dynamic> map, [
    List<String> tracks = const [],
  ]) {
    return Artist(
      id: map['id'] as int?,
      name: (map['name'] as String?) ?? '',
      trackTitles: tracks,
    );
  }
}
