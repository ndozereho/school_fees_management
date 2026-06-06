import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
<<<<<<< Updated upstream
=======
import 'dart:async';
>>>>>>> Stashed changes
import 'database_constants.dart';
import '../models/student.dart';
import '../models/payment_record.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;
<<<<<<< Updated upstream
  late StreamController<void> _changeController;

  DatabaseHelper._internal() {
    _changeController = StreamController<void>.broadcast();
  }
=======
  final StreamController<void> _changeController = StreamController<void>.broadcast();

  DatabaseHelper._internal();
>>>>>>> Stashed changes

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
<<<<<<< Updated upstream
    await db.execute(DatabaseConstants.createClassesTable);
    await db.execute(DatabaseConstants.createStudentsTable);
    await db.execute(DatabaseConstants.createPaymentRecordsTable);
=======
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
>>>>>>> Stashed changes
  }

  // Get all students
  Future<List<Student>> getAllStudents() async {
    final db = await database;
<<<<<<< Updated upstream
    final List<Map<String, dynamic>> maps = await db.query(DatabaseConstants.tableStudents);
=======
    final List<Map<String, dynamic>> maps = await db.query(DatabaseConstants.studentsTable);
>>>>>>> Stashed changes
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
<<<<<<< Updated upstream
        DatabaseConstants.tableStudents,
        where: '${DatabaseConstants.colStudentClassName} = ? AND ${DatabaseConstants.colStudentSectionType} = ? AND ${DatabaseConstants.colStudentTerm} = ? AND ${DatabaseConstants.colStudentYear} = ?',
=======
        DatabaseConstants.studentsTable,
        where: 'className = ? AND sectionType = ? AND term = ? AND year = ?',
>>>>>>> Stashed changes
        whereArgs: [className, sectionType, term, year],
      );
    } else {
      maps = await db.query(
<<<<<<< Updated upstream
        DatabaseConstants.tableStudents,
        where: '${DatabaseConstants.colStudentClassName} = ? AND ${DatabaseConstants.colStudentSectionType} = ?',
=======
        DatabaseConstants.studentsTable,
        where: 'className = ? AND sectionType = ?',
>>>>>>> Stashed changes
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
    
<<<<<<< Updated upstream
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
=======
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
>>>>>>> Stashed changes
    };
  }

  // Search students
  Future<List<Student>> searchStudents(String query) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
<<<<<<< Updated upstream
      DatabaseConstants.tableStudents,
      where: '${DatabaseConstants.colStudentFullName} LIKE ? OR ${DatabaseConstants.colStudentLedgerNo} LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
=======
      DatabaseConstants.studentsTable,
      where: 'fullName LIKE ? OR ledgerNo LIKE ? OR parentContact LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%'],
>>>>>>> Stashed changes
    );
    return List.generate(maps.length, (i) {
      return Student.fromMap(maps[i]);
    });
  }
<<<<<<< Updated upstream

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

=======

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

>>>>>>> Stashed changes
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
<<<<<<< Updated upstream
      DatabaseConstants.tableStudents,
      where: '${DatabaseConstants.colStudentId} = ?',
=======
      DatabaseConstants.studentsTable,
      where: 'studentId = ?',
>>>>>>> Stashed changes
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
    
<<<<<<< Updated upstream
    // Insert or replace class term info
    await db.insert(
      DatabaseConstants.tableClassSections,
=======
    await db.insert(
      DatabaseConstants.classesTable,
>>>>>>> Stashed changes
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
<<<<<<< Updated upstream
      DatabaseConstants.tableClassSections,
=======
      DatabaseConstants.classesTable,
>>>>>>> Stashed changes
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
<<<<<<< Updated upstream
    final buffer = StringBuffer();
    buffer.writeln('Ledger No,Parent Contact,Full Name,Class,Section,Term,Year,Fees Structure,Arrears,Fees Paid,Expected Fees,Balance');
    
    for (var student in students) {
      buffer.writeln('${student.ledgerNo},${student.parentContact},${student.fullName},${student.className},${student.sectionType},${student.term},${student.year},${student.feesStructure},${student.arrears},${student.feesPaid},${student.expectedFees},${student.balance}');
    }
    
    return buffer.toString();
=======
    return Student.csvHeader + '\n' + students.map((s) => s.toCSVRow()).join('\n');
>>>>>>> Stashed changes
  }

  // Clear all data
  Future<void> clearAllData() async {
    final db = await database;
<<<<<<< Updated upstream
    await db.delete(DatabaseConstants.tablePaymentRecords);
    await db.delete(DatabaseConstants.tableStudents);
    await db.delete(DatabaseConstants.tableClassSections);
    _changeController.add(null);
  }

  // Authenticate user (simple implementation)
  Future<bool> authenticateUser(String username, String password) async {
    // For simplicity, using hardcoded credentials
    // You can modify this to check against a users table
=======
    await db.delete(DatabaseConstants.paymentRecordsTable);
    await db.delete(DatabaseConstants.studentsTable);
    await db.delete(DatabaseConstants.classesTable);
    _changeController.add(null);
  }

  // Authenticate user
  Future<bool> authenticateUser(String username, String password) async {
>>>>>>> Stashed changes
    return username == 'admin' && password == 'admin123';
  }

  // Dispose
  void dispose() {
    _changeController.close();
  }
}
