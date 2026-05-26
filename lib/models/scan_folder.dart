class ScanFolder {
  final int? id;
  final String path;

  ScanFolder({this.id, required this.path});

  Map<String, dynamic> toMap() {
    return {'id': id, 'path': path};
  }

  factory ScanFolder.fromMap(Map<String, dynamic> map) {
    return ScanFolder(
      id: map['id'] as int?,
      path: (map['path'] as String?) ?? '',
    );
  }
}
