import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class CacheService {
  static Database? _db;

  static Future<Database> _database() async {
    if (_db != null) return _db!;
    final path = join(await getDatabasesPath(), 'cache.db');
    _db = await openDatabase(path, version: 1,
        onCreate: (db, version) async {
      await db.execute(
          'CREATE TABLE cache(key TEXT PRIMARY KEY, value TEXT)');
    });
    return _db!;
  }

  static Future<void> set(String key, String value) async {
    final db = await _database();
    await db.insert('cache', {'key': key, 'value': value},
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<String?> get(String key) async {
    final db = await _database();
    final res =
        await db.query('cache', where: 'key = ?', whereArgs: [key], limit: 1);
    if (res.isNotEmpty) {
      return res.first['value'] as String?;
    }
    return null;
  }
}
