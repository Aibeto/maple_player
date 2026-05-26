class AppConstants {
  static const String dbName = 'maple_player.db';
  static const String tracksTable = 'tracks';
  static const String albumsTable = 'albums';
  static const String artistsTable = 'artists';
  static const String scanFoldersTable = 'scan_folders';
  static const String albumTracksTable = 'album_tracks';
  static const String artistTracksTable = 'artist_tracks';
  static const String settingsTable = 'settings';

  static const List<String> audioExtensions = [
    '.mp3',
    '.flac',
    '.wav',
    '.ogg',
    '.aac',
    '.m4a',
    '.wma',
    '.opus',
  ];
}
