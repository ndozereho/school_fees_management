import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'database_constants.dart';
import '../models/student.dart';
import '../models/payment_record.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;
  final StreamController<void> _changeController = StreamController<void>.broadcast();

  DatabaseHelper._internal();

  factory DatabaseHelper() {
    return _instance;
  }

  Stream<void> get databaseChanges => _changeController.stream;

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
    // Create classes table
    await db.execute('''
      CREATE TABLE ${DatabaseConstants.classesTable} (
        ${DatabaseConstants.colClassId} INTEGER PRIMARY KEY AUTOINCREMENT,
        ${DatabaseConstants.colClassName} TEXT NOT NULL,
        ${DatabaseConstants.colClassSectionType} TEXT NOT NULL,
        ${DatabaseConstants.colClassTerm} TEXT NOT NULL,
        ${DatabaseConstants.colClassYear} TEXT NOT NULL,
        UNIQUE(${DatabaseConstants.colClassName}, ${DatabaseConstants.colClassSectionType})
      )
    ''');

    // Create students table - matches your Student model
    await db.execute('''
      CREATE TABLE ${DatabaseConstants.studentsTable} (
        studentId INTEGER PRIMARY KEY AUTOINCREMENT,
        ledgerNo TEXT UNIQUE NOT NULL,
        parentContact TEXT,
        reamPaid INTEGER DEFAULT 0,
        fullName TEXT NOT NULL,
        feesStructure REAL DEFAULT 0,
        arrears REAL DEFAULT 0,
        className TEXT NOT NULL,
        sectionType TEXT NOT NULL,
        term TEXT NOT NULL,
        year TEXT NOT NULL
      )
    ''');

    // Create payment_records table
    await db.execute('''
      CREATE TABLE ${DatabaseConstants.paymentRecordsTable} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        studentId INTEGER NOT NULL,
        cash REAL NOT NULL,
        date TEXT NOT NULL,
        paymentMethod TEXT NOT NULL,
        receiptNumber TEXT,
        description TEXT,
        FOREIGN KEY (studentId) REFERENCES ${DatabaseConstants.studentsTable}(studentId) ON DELETE CASCADE
      )
    ''');
  }

  // Get all students
  Future<List<Student>> getAllStudents() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(DatabaseConstants.studentsTable);
    return List.generate(maps.length, (i) {
      return Student.fromMap(maps[i]);
    });
  }

  // Get students by class
  Future<List<Student>> getStudentsByClass(String className, String sectionType, {String? term, String? year}) async {
    final db = await database;
    List<Map<String, dynamic>> maps;
    
    if (term != null && year != null) {
      maps = await db.query(
        DatabaseConstants.studentsTable,
        where: 'className = ? AND sectionType = ? AND term = ? AND year = ?',
        whereArgs: [className, sectionType, term, year],
      );
    } else {
      maps = await db.query(
        DatabaseConstants.studentsTable,
        where: 'className = ? AND sectionType = ?',
        whereArgs: [className, sectionType],
      );
    }
    
    return List.generate(maps.length, (i) {
      return Student.fromMap(maps[i]);
    });
  }

  // Get overall statistics
  Future<Map<String, dynamic>> getOverallStatistics() async {
    final db = await database;
    
    final studentCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM ${DatabaseConstants.studentsTable}')
    ) ?? 0;
    
    // Get all students to calculate fees
    final students = await getAllStudents();
    double totalExpectedFees = 0;
    double totalFeesPaid = 0;
    double totalBalance = 0;
    
    for (var student in students) {
      totalExpectedFees += student.expectedFees;
      totalFeesPaid += student.feesPaid;
      totalBalance += student.balance;
    }
    
    return {
      'totalStudents': studentCount,
      'totalExpectedFees': totalExpectedFees,
      'totalFeesPaid': totalFeesPaid,
      'totalBalance': totalBalance,
    };
  }

  // Search students
  Future<List<Student>> searchStudents(String query) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseConstants.studentsTable,
      where: 'fullName LIKE ? OR ledgerNo LIKE ? OR parentContact LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%'],
    );
    return List.generate(maps.length, (i) {
      return Student.fromMap(maps[i]);
    });
  }

  // Insert student
  Future<int> insertStudent(Student student, String className, String sectionType, {String term = 'ONE', String year = '2026'}) async {
    final db = await database;
    final id = await db.insert(DatabaseConstants.studentsTable, {
      'ledgerNo': student.ledgerNo,
      'parentContact': student.parentContact,
      'reamPaid': student.reamPaid ? 1 : 0,
      'fullName': student.fullName,
      'feesStructure': student.feesStructure,
      'arrears': student.arrears,
      'className': className,
      'sectionType': sectionType,
      'term': term,
      'year': year,
    });
    _changeController.add(null);
    return id;
  }

  // Update student
  Future<void> updateStudent(Student student) async {
    final db = await database;
    await db.update(
      DatabaseConstants.studentsTable,
      {
        'parentContact': student.parentContact,
        'reamPaid': student.reamPaid ? 1 : 0,
        'fullName': student.fullName,
        'feesStructure': student.feesStructure,
        'arrears': student.arrears,
      },
      where: 'studentId = ?',
      whereArgs: [student.studentId],
    );
    _changeController.add(null);
  }

  // Delete student
  Future<void> deleteStudent(int studentId) async {
    final db = await database;
    await db.delete(
      DatabaseConstants.studentsTable,
      where: 'studentId = ?',
      whereArgs: [studentId],
    );
    _changeController.add(null);
  }

  // Insert payment record
  Future<int> insertPaymentRecord(int studentId, PaymentRecord payment) async {
    final db = await database;
    final id = await db.insert(DatabaseConstants.paymentRecordsTable, {
      'studentId': studentId,
      'cash': payment.cash,
      'date': payment.date.toIso8601String(),
      'paymentMethod': payment.paymentMethod,
      'receiptNumber': payment.receiptNumber,
      'description': payment.description,
    });
    
    _changeController.add(null);
    return id;
  }

  // Delete payment record
  Future<void> deletePaymentRecord(int paymentId) async {
    final db = await database;
    await db.delete(
      DatabaseConstants.paymentRecordsTable,
      where: 'id = ?',
      whereArgs: [paymentId],
    );
    _changeController.add(null);
  }

  // Get student by ID
  Future<Student?> getStudentById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseConstants.studentsTable,
      where: 'studentId = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Student.fromMap(maps.first);
    }
    return null;
  }

  // Update class section term
  Future<void> updateClassSectionTerm(String className, String sectionType, String term, String year) async {
    final db = await database;
    
    await db.insert(
      DatabaseConstants.classesTable,
      {
        DatabaseConstants.colClassName: className,
        DatabaseConstants.colClassSectionType: sectionType,
        DatabaseConstants.colClassTerm: term,
        DatabaseConstants.colClassYear: year,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    
    _changeController.add(null);
  }

  // Get class section term
  Future<Map<String, String>> getClassSectionTerm(String className, String sectionType) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseConstants.classesTable,
      where: '${DatabaseConstants.colClassName} = ? AND ${DatabaseConstants.colClassSectionType} = ?',
      whereArgs: [className, sectionType],
    );
    
    if (maps.isNotEmpty) {
      return {
        'term': maps.first[DatabaseConstants.colClassTerm] as String,
        'year': maps.first[DatabaseConstants.colClassYear] as String,
      };
    }
    return {'term': 'ONE', 'year': '2026'};
  }

  // Export to CSV
  Future<String> exportToCSV() async {
    final students = await getAllStudents();
    return Student.csvHeader + '\n' + students.map((s) => s.toCSVRow()).join('\n');
  }

  // Clear all data
  Future<void> clearAllData() async {
    final db = await database;
    await db.delete(DatabaseConstants.paymentRecordsTable);
    await db.delete(DatabaseConstants.studentsTable);
    await db.delete(DatabaseConstants.classesTable);
    _changeController.add(null);
  }

  // Authenticate user
  Future<bool> authenticateUser(String username, String password) async {
    return username == 'admin' && password == 'admin123';
  }

  // Dispose
  void dispose() {
    _changeController.close();
  }
}