import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

class UserRecord {
  final int? id;
  String email;
  String password;

  UserRecord({this.id, required this.email, required this.password});

  Map<String, dynamic> toMap() {
    return {'id': id, 'email': email, 'password': password};
  }

  factory UserRecord.fromMap(Map<String, dynamic> map) {
    return UserRecord(
      id: map['id'] as int?,
      email: map['email'] as String,
      password: map['password'] as String,
    );
  }

  UserRecord copyWith({int? id, String? email, String? password}) {
    return UserRecord(
      id: id ?? this.id,
      email: email ?? this.email,
      password: password ?? this.password,
    );
  }
}

class DatabaseHelper {
  static const _databaseName = 'influenza.db';
  static const _databaseVersion = 1;
  static const table = 'user_records';

  static Database? _database;

  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, _databaseName);
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $table (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        email TEXT NOT NULL,
        password TEXT NOT NULL
      )
    ''');
  }

  Future<List<UserRecord>> getAllRecords() async {
    final db = await database;
    final maps = await db.query(table, orderBy: 'id DESC');
    return maps.map((m) => UserRecord.fromMap(m)).toList();
  }

  Future<int> insertRecord(UserRecord record) async {
    final db = await database;
    return await db.insert(table, record.toMap());
  }

  Future<int> updateRecord(UserRecord record) async {
    final db = await database;
    return await db.update(
      table,
      record.toMap(),
      where: 'id = ?',
      whereArgs: [record.id],
    );
  }

  Future<int> deleteRecord(int id) async {
    final db = await database;
    return await db.delete(table, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteAllRecords() async {
    final db = await database;
    return await db.delete(table);
  }

  Future<int> getRecordCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) FROM $table');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<void> importFromJson(List<Map<String, dynamic>> jsonList) async {
    final db = await database;
    final batch = db.batch();
    for (final item in jsonList) {
      final email = (item['email'] ?? item['Email'] ?? item['EMAIL'] ?? '').toString().trim();
      final password = (item['password'] ?? item['Password'] ?? item['PASSWORD'] ?? '').toString().trim();
      if (email.isNotEmpty && password.isNotEmpty) {
        batch.insert(table, {'email': email, 'password': password});
      }
    }
    await batch.commit(noResult: true);
  }

  Future<List<Map<String, dynamic>>> exportToJson() async {
    final records = await getAllRecords();
    return records.map((r) => {'email': r.email, 'password': r.password}).toList();
  }
}
