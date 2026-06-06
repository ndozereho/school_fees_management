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
      // For Windows desktop, we need to use a specific path
      String dbPath;
      
      if (Platform.isWindows) {
        // On Windows, use the app data directory
        final appDocDir = await getApplicationDocumentsDirectory();
        dbPath = join(appDocDir.path, DatabaseConstants.databaseName);
      } else if (Platform.isAndroid || Platform.isIOS) {
        // On mobile, use the default database path
        dbPath = join(await getDatabasesPath(), DatabaseConstants.databaseName);
      } else {
        // For other platforms (macOS, Linux) use documents directory
        final appDocDir = await getApplicationDocumentsDirectory();
        dbPath = join(appDocDir.path, DatabaseConstants.databaseName);
      }
      
      debugPrint('Database path: $dbPath');
      
      // Open the database
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
    // Create classes table
    await db.execute('''
      CREATE TABLE ${DatabaseConstants.classesTable} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        class_name TEXT NOT NULL,
        section_type TEXT NOT NULL,
        term TEXT NOT NULL,
        year TEXT NOT NULL,
        UNIQUE(class_name, section_type)
      )
    ''');

    // Create students table
    await db.execute('''
      CREATE TABLE ${DatabaseConstants.studentsTable} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        ledger_no TEXT UNIQUE NOT NULL,
        parent_contact TEXT,
        full_name TEXT NOT NULL,
        class_name TEXT NOT NULL,
        section_type TEXT NOT NULL,
        term TEXT NOT NULL,
        year TEXT NOT NULL,
        fees_structure REAL DEFAULT 0,
        arrears REAL DEFAULT 0,
        fees_paid REAL DEFAULT 0,
        expected_fees REAL DEFAULT 0,
        balance REAL DEFAULT 0,
        FOREIGN KEY (class_name, section_type) REFERENCES ${DatabaseConstants.classesTable}(class_name, section_type)
      )
    ''');

    // Create payment_records table
    await db.execute('''
      CREATE TABLE ${DatabaseConstants.paymentRecordsTable} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        student_id INTEGER NOT NULL,
        amount REAL NOT NULL,
        payment_date TEXT NOT NULL,
        payment_method TEXT NOT NULL,
        receipt_number TEXT,
        notes TEXT,
        FOREIGN KEY (student_id) REFERENCES ${DatabaseConstants.studentsTable}(id) ON DELETE CASCADE
      )
    ''');
  }
}
