import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:voicemail/features/voicemail/domain/voicemail.dart';

class LocalDatabase {
  static final LocalDatabase instance = LocalDatabase._init();
  static Database? _database;

  // In-memory backing store for web preview / web runtime
  final List<Voicemail> _webStore = [];

  LocalDatabase._init();

  Future<Database> get database async {
    if (kIsWeb) {
      throw UnsupportedError('SQLite is unsupported on web; using in-memory store.');
    }
    if (_database != null) return _database!;
    _database = await _initDB('voicemail_app.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    final db = await openDatabase(
      path,
      version: 3,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );

    // Clean up any demo or mock records so the inbox contains only real user data
    try {
      await db.delete('voicemails', where: "id LIKE 'vm_%' OR caller_number LIKE '+1 (555)%'");
    } catch (_) {}

    return db;
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS voicemails (
        id TEXT PRIMARY KEY,
        caller_number TEXT NOT NULL,
        caller_name TEXT,
        audio_local_path TEXT NOT NULL,
        duration_seconds INTEGER NOT NULL,
        created_at INTEGER NOT NULL,
        is_read INTEGER NOT NULL DEFAULT 0,
        is_starred INTEGER NOT NULL DEFAULT 0,
        transcript_text TEXT,
        detected_language TEXT,
        transcription_status TEXT NOT NULL DEFAULT 'completed',
        call_handling_mode TEXT NOT NULL DEFAULT 'Live Voicemail'
      )
    ''');

    await db.execute('CREATE INDEX IF NOT EXISTS idx_created_at ON voicemails(created_at DESC)');
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      try {
        await db.execute('ALTER TABLE voicemails ADD COLUMN caller_name TEXT');
      } catch (_) {}
      try {
        await db.execute("ALTER TABLE voicemails ADD COLUMN call_handling_mode TEXT NOT NULL DEFAULT 'Live Voicemail'");
      } catch (_) {}
    }
    if (oldVersion < 3) {
      try {
        await db.delete('voicemails', where: "id LIKE 'vm_%' OR caller_number LIKE '+1 (555)%'");
      } catch (_) {}
    }
  }

  Future<int> insertVoicemail(Voicemail vm) async {
    if (kIsWeb) {
      _webStore.removeWhere((v) => v.id == vm.id);
      _webStore.add(vm);
      return 1;
    }
    final db = await database;
    return await db.insert(
      'voicemails',
      vm.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Voicemail>> getAllVoicemails({String? searchQuery}) async {
    if (kIsWeb) {
      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final q = searchQuery.trim().toLowerCase();
        return _webStore.where((v) {
          final nameMatch = v.callerName?.toLowerCase().contains(q) ?? false;
          final numMatch = v.callerNumber.toLowerCase().contains(q);
          final transcriptMatch = v.transcriptText?.toLowerCase().contains(q) ?? false;
          return nameMatch || numMatch || transcriptMatch;
        }).toList();
      }
      return List.unmodifiable(_webStore);
    }

    final db = await database;
    List<Map<String, dynamic>> maps;

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final query = '%${searchQuery.trim()}%';
      maps = await db.rawQuery('''
        SELECT * FROM voicemails 
        WHERE caller_number LIKE ? OR caller_name LIKE ? OR transcript_text LIKE ?
        ORDER BY created_at DESC
      ''', [query, query, query]);
    } else {
      maps = await db.query('voicemails', orderBy: 'created_at DESC');
    }

    return maps.map((e) => Voicemail.fromMap(e)).toList();
  }

  Future<Voicemail?> getVoicemailById(String id) async {
    if (kIsWeb) {
      try {
        return _webStore.firstWhere((v) => v.id == id);
      } catch (_) {
        return null;
      }
    }

    final db = await database;
    final maps = await db.query(
      'voicemails',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return Voicemail.fromMap(maps.first);
    }
    return null;
  }

  Future<void> updateVoicemail(Voicemail vm) async {
    if (kIsWeb) {
      final idx = _webStore.indexWhere((v) => v.id == vm.id);
      if (idx != -1) {
        _webStore[idx] = vm;
      }
      return;
    }

    final db = await database;
    await db.update(
      'voicemails',
      vm.toMap(),
      where: 'id = ?',
      whereArgs: [vm.id],
    );
  }

  Future<void> markAsRead(String id, bool isRead) async {
    if (kIsWeb) {
      final idx = _webStore.indexWhere((v) => v.id == id);
      if (idx != -1) {
        _webStore[idx] = _webStore[idx].copyWith(isRead: isRead);
      }
      return;
    }

    final db = await database;
    await db.update(
      'voicemails',
      {'is_read': isRead ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> markMultipleAsRead(Set<String> ids, bool isRead) async {
    if (ids.isEmpty) return;
    if (kIsWeb) {
      for (var i = 0; i < _webStore.length; i++) {
        if (ids.contains(_webStore[i].id)) {
          _webStore[i] = _webStore[i].copyWith(isRead: isRead);
        }
      }
      return;
    }

    final db = await database;
    final batch = db.batch();
    for (final id in ids) {
      batch.update(
        'voicemails',
        {'is_read': isRead ? 1 : 0},
        where: 'id = ?',
        whereArgs: [id],
      );
    }
    await batch.commit(noResult: true);
  }

  Future<void> toggleStarred(String id, bool isStarred) async {
    if (kIsWeb) {
      final idx = _webStore.indexWhere((v) => v.id == id);
      if (idx != -1) {
        _webStore[idx] = _webStore[idx].copyWith(isStarred: isStarred);
      }
      return;
    }

    final db = await database;
    await db.update(
      'voicemails',
      {'is_starred': isStarred ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> updateTranscript(String id, String text, String lang) async {
    if (kIsWeb) {
      final idx = _webStore.indexWhere((v) => v.id == id);
      if (idx != -1) {
        _webStore[idx] = _webStore[idx].copyWith(
          transcriptText: text,
          detectedLanguage: lang,
          transcriptionStatus: 'completed',
        );
      }
      return;
    }

    final db = await database;
    await db.update(
      'voicemails',
      {
        'transcript_text': text,
        'detected_language': lang,
        'transcription_status': 'completed',
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteVoicemail(String id) async {
    if (kIsWeb) {
      _webStore.removeWhere((v) => v.id == id);
      return;
    }

    final db = await database;
    final maps = await db.query('voicemails', columns: ['audio_local_path'], where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) {
      final path = maps.first['audio_local_path'] as String;
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    }
    await db.delete('voicemails', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteMultiple(Set<String> ids) async {
    for (final id in ids) {
      await deleteVoicemail(id);
    }
  }

  Future<void> deleteAllVoicemails() async {
    if (kIsWeb) {
      _webStore.clear();
      return;
    }

    final db = await database;
    final all = await db.query('voicemails', columns: ['audio_local_path']);
    for (var row in all) {
      final path = row['audio_local_path'] as String;
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    }
    await db.delete('voicemails');
  }

  Future<int> autoPurgeExpired(int retentionDays) async {
    if (retentionDays <= 0) return 0; // 0 means keep forever
    if (kIsWeb) {
      final threshold = DateTime.now().subtract(Duration(days: retentionDays));
      final before = _webStore.length;
      _webStore.removeWhere((v) => v.createdAt.isBefore(threshold) && !v.isStarred);
      return before - _webStore.length;
    }

    final db = await database;
    final threshold = DateTime.now().subtract(Duration(days: retentionDays)).millisecondsSinceEpoch;

    final expiredRows = await db.query(
      'voicemails',
      columns: ['id', 'audio_local_path'],
      where: 'created_at < ? AND is_starred = 0',
      whereArgs: [threshold],
    );

    for (var row in expiredRows) {
      final path = row['audio_local_path'] as String;
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    }

    return await db.delete(
      'voicemails',
      where: 'created_at < ? AND is_starred = 0',
      whereArgs: [threshold],
    );
  }
}
