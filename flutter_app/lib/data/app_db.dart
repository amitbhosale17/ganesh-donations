import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class AppDb {
  static Database? _db;

  static Future<Database> get db async {
    if (_db != null) return _db!;

    final path = join(await getDatabasesPath(), 'ganesh_donations.db');
    
    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE local_donations (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            donor_name TEXT,
            donor_phone TEXT,
            amount REAL NOT NULL,
            method TEXT NOT NULL,
            status TEXT NOT NULL,
            temp_receipt_no TEXT,
            server_receipt_no TEXT,
            notes TEXT,
            created_at TEXT NOT NULL,
            synced INTEGER DEFAULT 0
          )
        ''');
      },
    );

    return _db!;
  }

  static Future<int> insertLocalDonation(Map<String, dynamic> donation) async {
    final database = await db;
    return await database.insert('local_donations', donation);
  }

  static Future<List<Map<String, dynamic>>> getUnsyncedDonations() async {
    final database = await db;
    return await database.query(
      'local_donations',
      where: 'synced = ?',
      whereArgs: [0],
      orderBy: 'created_at DESC',
    );
  }

  static Future<int> markAsSynced(int id, String serverReceiptNo) async {
    final database = await db;
    return await database.update(
      'local_donations',
      {
        'synced': 1,
        'server_receipt_no': serverReceiptNo,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<List<Map<String, dynamic>>> getRecentDonations({int limit = 50}) async {
    final database = await db;
    return await database.query(
      'local_donations',
      orderBy: 'created_at DESC',
      limit: limit,
    );
  }
}
