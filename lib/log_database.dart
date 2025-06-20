import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'log_entry.dart';

class LogDatabase {
  static final LogDatabase instance = LogDatabase._init();
  static Database? _database;

  LogDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('log.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        time TEXT NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL
      )
    ''');
  }

  Future<int> insertLog(LogEntry log) async {
    final db = await instance.database;
    return await db.insert('logs', log.toMap());
  }

  Future<List<LogEntry>> getLogs() async {
    final db = await instance.database;
    final result = await db.query('logs', orderBy: 'id DESC');
    return result.map((json) => LogEntry.fromMap(json)).toList();
  }

  Future<void> close() async {
    final db = await instance.database;
    await db.close();
  }
}
