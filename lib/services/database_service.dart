import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import '../config/constants.dart';
import '../models/track.dart';
import '../models/album.dart';
import '../models/artist.dart';
import '../models/scan_folder.dart';

class DatabaseService {
  static Database? _database;

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, AppConstants.dbName);

    return await openDatabase(path, version: 1, onCreate: _createTables);
  }

  static Future<void> _createTables(Database db, int version) async {
    await db.execute('''
      CREATE TABLE ${AppConstants.tracksTable} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT,
        artist TEXT,
        album TEXT,
        year TEXT,
        file_path TEXT UNIQUE,
        md5 TEXT UNIQUE,
        play_count INTEGER DEFAULT 0,
        exlrc INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE ${AppConstants.albumsTable} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT UNIQUE,
        artist TEXT,
        year TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE ${AppConstants.albumTracksTable} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        album_id INTEGER,
        title TEXT,
        FOREIGN KEY (album_id) REFERENCES ${AppConstants.albumsTable}(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE ${AppConstants.artistsTable} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT UNIQUE
      )
    ''');

    await db.execute('''
      CREATE TABLE ${AppConstants.artistTracksTable} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        artist_id INTEGER,
        title TEXT,
        FOREIGN KEY (artist_id) REFERENCES ${AppConstants.artistsTable}(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE ${AppConstants.scanFoldersTable} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        path TEXT UNIQUE
      )
    ''');
  }

  static Future<bool> isFirstLaunch() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM ${AppConstants.tracksTable}',
    );
    return (result.first['count'] as int) == 0;
  }

  static Future<bool> md5Exists(String md5) async {
    final db = await database;
    final result = await db.query(
      AppConstants.tracksTable,
      where: 'md5 = ?',
      whereArgs: [md5],
      limit: 1,
    );
    return result.isNotEmpty;
  }

  static Future<void> insertTrack(Track track) async {
    final db = await database;
    try {
      await db.insert(
        AppConstants.tracksTable,
        track.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      // ignore duplicates
    }
  }

  static Future<List<Track>> getAllTracks() async {
    final db = await database;
    final maps = await db.query(AppConstants.tracksTable);
    return maps.map((map) => Track.fromMap(map)).toList();
  }

  static Future<void> updateExlrc(String filePath, int exlrc) async {
    final db = await database;
    await db.update(
      AppConstants.tracksTable,
      {'exlrc': exlrc},
      where: 'file_path = ?',
      whereArgs: [filePath],
    );
  }

  static Future<void> clearTracks() async {
    final db = await database;
    await db.delete(AppConstants.tracksTable);
  }

  static Future<void> insertAlbum(
    String name,
    String artist,
    String year,
    List<String> titles,
  ) async {
    final db = await database;
    final id = await db.insert(AppConstants.albumsTable, {
      'name': name,
      'artist': artist,
      'year': year,
    }, conflictAlgorithm: ConflictAlgorithm.replace);

    await db.delete(
      AppConstants.albumTracksTable,
      where: 'album_id = ?',
      whereArgs: [id],
    );

    for (final title in titles) {
      await db.insert(AppConstants.albumTracksTable, {
        'album_id': id,
        'title': title,
      });
    }
  }

  static Future<List<Album>> getAllAlbums() async {
    final db = await database;
    final albumMaps = await db.query(AppConstants.albumsTable);
    final albums = <Album>[];

    for (final map in albumMaps) {
      final albumId = map['id'] as int;
      final tracks = await db.query(
        AppConstants.albumTracksTable,
        where: 'album_id = ?',
        whereArgs: [albumId],
      );
      final titles = tracks.map((t) => t['title'] as String).toList();
      albums.add(Album.fromMap(map, titles));
    }

    return albums;
  }

  static Future<void> insertArtist(String name, List<String> titles) async {
    final db = await database;
    final id = await db.insert(AppConstants.artistsTable, {
      'name': name,
    }, conflictAlgorithm: ConflictAlgorithm.replace);

    await db.delete(
      AppConstants.artistTracksTable,
      where: 'artist_id = ?',
      whereArgs: [id],
    );

    for (final title in titles) {
      await db.insert(AppConstants.artistTracksTable, {
        'artist_id': id,
        'title': title,
      });
    }
  }

  static Future<List<Artist>> getAllArtists() async {
    final db = await database;
    final artistMaps = await db.query(AppConstants.artistsTable);
    final artists = <Artist>[];

    for (final map in artistMaps) {
      final artistId = map['id'] as int;
      final tracks = await db.query(
        AppConstants.artistTracksTable,
        where: 'artist_id = ?',
        whereArgs: [artistId],
      );
      final titles = tracks.map((t) => t['title'] as String).toList();
      artists.add(Artist.fromMap(map, titles));
    }

    return artists;
  }

  static Future<void> clearCategories() async {
    final db = await database;
    await db.delete(AppConstants.albumTracksTable);
    await db.delete(AppConstants.albumsTable);
    await db.delete(AppConstants.artistTracksTable);
    await db.delete(AppConstants.artistsTable);
  }

  static Future<void> insertScanFolder(ScanFolder folder) async {
    final db = await database;
    try {
      await db.insert(
        AppConstants.scanFoldersTable,
        folder.toMap(),
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    } catch (e) {
      // ignore duplicates
    }
  }

  static Future<List<ScanFolder>> getScanFolders() async {
    final db = await database;
    final maps = await db.query(AppConstants.scanFoldersTable);
    return maps.map((map) => ScanFolder.fromMap(map)).toList();
  }

  static Future<void> removeScanFolder(String path) async {
    final db = await database;
    await db.delete(
      AppConstants.scanFoldersTable,
      where: 'path = ?',
      whereArgs: [path],
    );
  }
}
