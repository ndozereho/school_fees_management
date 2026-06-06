import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'database_constants.dart';
import '../models/student.dart';
import '../models/payment_record.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;
  late StreamController<void> _changeController;

  DatabaseHelper._internal() {
    _changeController = StreamController<void>.broadcast();
  }

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
    await db.execute(DatabaseConstants.createClassesTable);
    await db.execute(DatabaseConstants.createStudentsTable);
    await db.execute(DatabaseConstants.createPaymentRecordsTable);
  }

  // Get all students
  Future<List<Student>> getAllStudents() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(DatabaseConstants.tableStudents);
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
        DatabaseConstants.tableStudents,
        where: '${DatabaseConstants.colStudentClassName} = ? AND ${DatabaseConstants.colStudentSectionType} = ? AND ${DatabaseConstants.colStudentTerm} = ? AND ${DatabaseConstants.colStudentYear} = ?',
        whereArgs: [className, sectionType, term, year],
      );
    } else {
      maps = await db.query(
        DatabaseConstants.tableStudents,
        where: '${DatabaseConstants.colStudentClassName} = ? AND ${DatabaseConstants.colStudentSectionType} = ?',
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
    
    // Get total students
    final studentCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM ${DatabaseConstants.tableStudents}')
    ) ?? 0;
    
    // Get total expected fees
    final expectedFees = Sqflite.firstIntValue(
      await db.rawQuery('SELECT SUM(${DatabaseConstants.colStudentExpectedFees}) FROM ${DatabaseConstants.tableStudents}')
    ) ?? 0;
    
    // Get total paid fees
    final paidFees = Sqflite.firstIntValue(
      await db.rawQuery('SELECT SUM(${DatabaseConstants.colStudentFeesPaid}) FROM ${DatabaseConstants.tableStudents}')
    ) ?? 0;
    
    // Get total balance
    final balance = Sqflite.firstIntValue(
      await db.rawQuery('SELECT SUM(${DatabaseConstants.colStudentBalance}) FROM ${DatabaseConstants.tableStudents}')
    ) ?? 0;
    
    return {
      'totalStudents': studentCount,
      'totalExpectedFees': expectedFees.toDouble(),
      'totalFeesPaid': paidFees.toDouble(),
      'totalBalance': balance.toDouble(),
    };
  }

  // Search students
  Future<List<Student>> searchStudents(String query) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseConstants.tableStudents,
      where: '${DatabaseConstants.colStudentFullName} LIKE ? OR ${DatabaseConstants.colStudentLedgerNo} LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
    );
    return List.generate(maps.length, (i) {
      return Student.fromMap(maps[i]);
    });
  }

  // Insert student
  Future<int> insertStudent(Student student, String className, String sectionType, {String term = 'ONE', String year = '2026'}) async {
    final db = await database;
    final id = await db.insert(DatabaseConstants.tableStudents, {
      DatabaseConstants.colStudentLedgerNo: student.ledgerNo,
      DatabaseConstants.colStudentParentContact: student.parentContact,
      DatabaseConstants.colStudentFullName: student.fullName,
      DatabaseConstants.colStudentClassName: className,
      DatabaseConstants.colStudentSectionType: sectionType,
      DatabaseConstants.colStudentTerm: term,
      DatabaseConstants.colStudentYear: year,
      DatabaseConstants.colStudentFeesStructure: student.feesStructure,
      DatabaseConstants.colStudentArrears: student.arrears,
      DatabaseConstants.colStudentFeesPaid: student.feesPaid,
      DatabaseConstants.colStudentExpectedFees: student.expectedFees,
      DatabaseConstants.colStudentBalance: student.balance,
    });
    _changeController.add(null);
    return id;
  }

  // Update student
  Future<void> updateStudent(Student student) async {
    final db = await database;
    await db.update(
      DatabaseConstants.tableStudents,
      student.toMap(),
      where: '${DatabaseConstants.colStudentId} = ?',
      whereArgs: [student.id],
    );
    _changeController.add(null);
  }

  // Delete student
  Future<void> deleteStudent(int studentId) async {
    final db = await database;
    await db.delete(
      DatabaseConstants.tableStudents,
      where: '${DatabaseConstants.colStudentId} = ?',
      whereArgs: [studentId],
    );
    _changeController.add(null);
  }

  // Insert payment record
  Future<int> insertPaymentRecord(int studentId, PaymentRecord payment) async {
    final db = await database;
    final id = await db.insert(DatabaseConstants.tablePaymentRecords, {
      DatabaseConstants.colPaymentStudentId: studentId,
      DatabaseConstants.colPaymentAmount: payment.amount,
      DatabaseConstants.colPaymentDate: payment.paymentDate.toIso8601String(),
      DatabaseConstants.colPaymentMethod: payment.paymentMethod,
      DatabaseConstants.colPaymentReceiptNumber: payment.receiptNumber,
      DatabaseConstants.colPaymentNotes: payment.notes,
    });
    
    // Update student's fees paid and balance
    final student = await getStudentById(studentId);
    if (student != null) {
      final newFeesPaid = student.feesPaid + payment.amount;
      final newBalance = student.expectedFees - newFeesPaid;
      await db.update(
        DatabaseConstants.tableStudents,
        {
          DatabaseConstants.colStudentFeesPaid: newFeesPaid,
          DatabaseConstants.colStudentBalance: newBalance,
        },
        where: '${DatabaseConstants.colStudentId} = ?',
        whereArgs: [studentId],
      );
    }
    
    _changeController.add(null);
    return id;
  }

  // Delete payment record
  Future<void> deletePaymentRecord(int paymentId) async {
    final db = await database;
    await db.delete(
      DatabaseConstants.tablePaymentRecords,
      where: '${DatabaseConstants.colPaymentId} = ?',
      whereArgs: [paymentId],
    );
    _changeController.add(null);
  }

  // Get student by ID
  Future<Student?> getStudentById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseConstants.tableStudents,
      where: '${DatabaseConstants.colStudentId} = ?',
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
    
    // Insert or replace class term info
    await db.insert(
      DatabaseConstants.tableClassSections,
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
      DatabaseConstants.tableClassSections,
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
    final buffer = StringBuffer();
    buffer.writeln('Ledger No,Parent Contact,Full Name,Class,Section,Term,Year,Fees Structure,Arrears,Fees Paid,Expected Fees,Balance');
    
    for (var student in students) {
      buffer.writeln('${student.ledgerNo},${student.parentContact},${student.fullName},${student.className},${student.sectionType},${student.term},${student.year},${student.feesStructure},${student.arrears},${student.feesPaid},${student.expectedFees},${student.balance}');
    }
    
    return buffer.toString();
  }

  // Clear all data
  Future<void> clearAllData() async {
    final db = await database;
    await db.delete(DatabaseConstants.tablePaymentRecords);
    await db.delete(DatabaseConstants.tableStudents);
    await db.delete(DatabaseConstants.tableClassSections);
    _changeController.add(null);
  }

  // Authenticate user (simple implementation)
  Future<bool> authenticateUser(String username, String password) async {
    // For simplicity, using hardcoded credentials
    // You can modify this to check against a users table
    return username == 'admin' && password == 'admin123';
  }

  // Dispose
  void dispose() {
    _changeController.close();
  }
}
