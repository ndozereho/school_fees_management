import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'database_constants.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();

  factory DatabaseHelper() {
    return _instance;
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    try {
      String dbPath;
      
      if (Platform.isWindows) {
        final appDocDir = await getApplicationDocumentsDirectory();
        dbPath = join(appDocDir.path, DatabaseConstants.databaseName);
      } else if (Platform.isAndroid || Platform.isIOS) {
        dbPath = join(await getDatabasesPath(), DatabaseConstants.databaseName);
      } else {
        final appDocDir = await getApplicationDocumentsDirectory();
        dbPath = join(appDocDir.path, DatabaseConstants.databaseName);
      }
      
      debugPrint('Database path: $dbPath');
      
      return await openDatabase(
        dbPath,
        version: DatabaseConstants.databaseVersion,
        onCreate: _createTables,
      );
    } catch (e) {
      debugPrint('Error initializing database: $e');
      rethrow;
    }
  }

  Future<void> _createTables(Database db, int version) async {
    await db.execute(DatabaseConstants.createClassesTable);
    await db.execute(DatabaseConstants.createStudentsTable);
    await db.execute(DatabaseConstants.createPaymentRecordsTable);
  }
}
