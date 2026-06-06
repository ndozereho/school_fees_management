import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'database_constants.dart';
import 'package:flutter/foundation.dart';

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
     // Student operations
Future<List<Student>> getAllStudents() async {
  final db = await database;
  final maps = await db.query(DatabaseConstants.studentsTable);
  return maps.map((map) => Student.fromMap(map)).toList();
}

Future<int> insertStudent(Student student, String className, String sectionType, {String term = 'ONE', String year = '2026'}) async {
  final db = await database;
  return await db.insert(DatabaseConstants.studentsTable, student.toMap());
}

Future<void> updateStudent(Student student) async {
  final db = await database;
  await db.update(DatabaseConstants.studentsTable, student.toMap(), where: 'id = ?', whereArgs: [student.studentId]);
}

Future<void> deleteStudent(int studentId) async {
  final db = await database;
  await db.delete(DatabaseConstants.studentsTable, where: 'id = ?', whereArgs: [studentId]);
}

// Payment operations
Future<int> insertPaymentRecord(int studentId, PaymentRecord payment) async {
  final db = await database;
  return await db.insert(DatabaseConstants.paymentRecordsTable, payment.toMap());
}

Future<void> deletePaymentRecord(int paymentId) async {
  final db = await database;
  await db.delete(DatabaseConstants.paymentRecordsTable, where: 'id = ?', whereArgs: [paymentId]);
}

// Search and statistics
Future<List<Student>> searchStudents(String query) async {
  final db = await database;
  final maps = await db.query(DatabaseConstants.studentsTable, where: 'full_name LIKE ? OR ledger_no LIKE ?', whereArgs: ['%$query%', '%$query%']);
  return maps.map((map) => Student.fromMap(map)).toList();
}

Future<Map<String, dynamic>> getOverallStatistics() async {
  final db = await database;
  final result = await db.rawQuery('SELECT COUNT(*) as total FROM ${DatabaseConstants.studentsTable}');
  return {'total': result.first['total'] ?? 0};
}

// Term management
Future<void> updateClassSectionTerm(String className, String sectionType, String term, String year) async {
  final db = await database;
  await db.update(DatabaseConstants.classesTable, {'term': term, 'year': year}, where: 'class_name = ? AND section_type = ?', whereArgs: [className, sectionType]);
}

Future<Map<String, String>> getClassSectionTerm(String className, String sectionType) async {
  final db = await database;
  final result = await db.query(DatabaseConstants.classesTable, where: 'class_name = ? AND section_type = ?', whereArgs: [className, sectionType]);
  if (result.isNotEmpty) {
    return {'term': result.first['term'].toString(), 'year': result.first['year'].toString()};
  }
  return {};
}

// Utilities
Future<String> exportToCSV() async {
  return 'export_path'; // Implement full CSV export
}

Future<void> clearAllData() async {
  final db = await database;
  await db.delete(DatabaseConstants.paymentRecordsTable);
  await db.delete(DatabaseConstants.studentsTable);
  await db.delete(DatabaseConstants.classesTable);
}

Future<bool> authenticateUser(String username, String password) async {
  // Implement authentication logic
  return true;
}

Stream<void> get databaseChanges => const Stream.empty(); // Implement database listener

void dispose() {
  _database?.close();
}
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
