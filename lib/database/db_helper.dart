import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  static Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDb();
    return _database!;
  }

  Future<Database> _initDb() async {
    String path = join(await getDatabasesPath(), 'voicemail.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute(
          '''
          CREATE TABLE voicemails (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            phoneNumber TEXT,
            message TEXT,
            timestamp INTEGER
          )
          ''',
        );
      },
    );
  }

  Future<void> insertVoicemail(String phoneNumber, String message) async {
    final db = await database;
    await db.insert('voicemails', {
      'phoneNumber': phoneNumber,
      'message': message,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<List<Map<String, dynamic>>> getVoicemails() async {
    final db = await database;
    return await db.query('voicemails', orderBy: 'timestamp DESC');
  }

  Future<void> deleteVoicemail(int id) async {
    final db = await database;
    await db.delete('voicemails', where: 'id = ?', whereArgs: [id]);
  }
}
