import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'database_constants.dart';
import '../models/student.dart';
import '../models/payment_record.dart';

class DatabaseHelper {
  // Singleton pattern
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;
  
  // Stream controller for database changes
  final _databaseChangeController = StreamController<void>.broadcast();
  Stream<void> get databaseChanges => _databaseChangeController.stream;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    try {
      final documentsDirectory = await getApplicationDocumentsDirectory();
      final path = join(documentsDirectory.path, DatabaseConstants.databaseName);
      
      return await openDatabase(
        path,
        version: DatabaseConstants.databaseVersion,
        onCreate: _onCreate,
        onConfigure: _onConfigure,
      );
    } catch (e) {
      throw Exception('Failed to initialize database: $e');
    }
  }

  Future<void> _onConfigure(Database db) async {
    // Enable foreign keys
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _onCreate(Database db, int version) async {
    // sqflite handles transactions automatically, so DON'T use BEGIN/COMMIT
    try {
      // Create tables
      await db.execute(DatabaseConstants.createUsersTable);
      await db.execute(DatabaseConstants.createClassSectionsTable);
      await db.execute(DatabaseConstants.createStudentsTable);
      await db.execute(DatabaseConstants.createPaymentRecordsTable);
      await db.execute(DatabaseConstants.createAuditLogTable);
      
      // Create indexes
      for (String index in DatabaseConstants.createIndexes) {
        await db.execute(index);
      }
      
      // Insert default admin user
      await db.execute(DatabaseConstants.insertDefaultAdmin);
      await db.execute(DatabaseConstants.insertDefaultUser);
      
      // Insert default class sections
      var batch = db.batch();
      for (var section in DatabaseConstants.defaultClassSections) {
        batch.insert(
          DatabaseConstants.tableClassSections,
          {
            DatabaseConstants.colClassSectionName: section['class_name'],
            DatabaseConstants.colClassSectionType: section['section_type'],
            DatabaseConstants.colClassTerm: 'ONE',
            DatabaseConstants.colClassYear: '2026',
          },
        );
      }
      await batch.commit(noResult: true);
    } catch (e) {
      throw Exception('Failed to create database: $e');
    }
  }

  // Authentication Methods
  Future<bool> authenticateUser(String username, String password) async {
    final db = await database;
    
    final result = await db.query(
      DatabaseConstants.tableUsers,
      where: '${DatabaseConstants.colUsername} = ? AND ${DatabaseConstants.colPassword} = ?',
      whereArgs: [username, password],
    );
    
    return result.isNotEmpty;
  }

  // Student CRUD Operations
  Future<int> insertStudent(Student student, String className, String sectionType, 
      {String term = 'ONE', String year = '2026'}) async {
    final db = await database;
    
    String ledgerNo = await _generateLedgerNumber(className, sectionType, db);
    student.ledgerNo = ledgerNo;

    int studentId = await db.insert(
      DatabaseConstants.tableStudents,
      {
        DatabaseConstants.colLedgerNo: ledgerNo,
        DatabaseConstants.colParentContact: student.parentContact,
        DatabaseConstants.colReamPaid: student.reamPaid ? 1 : 0,
        DatabaseConstants.colFullName: student.fullName,
        DatabaseConstants.colFeesStructure: student.feesStructure,
        DatabaseConstants.colArrears: student.arrears,
        DatabaseConstants.colClassName: className,
        DatabaseConstants.colSectionType: sectionType,
        DatabaseConstants.colTerm: term,
        DatabaseConstants.colYear: year,
        DatabaseConstants.colCreatedAt: DateTime.now().toIso8601String(),
        DatabaseConstants.colUpdatedAt: DateTime.now().toIso8601String(),
      },
    );

    // Insert any payment records using batch
    if (student.paymentRecords.isNotEmpty) {
      var batch = db.batch();
      for (var payment in student.paymentRecords) {
        batch.insert(
          DatabaseConstants.tablePaymentRecords,
          {
            DatabaseConstants.colPaymentStudentId: studentId,
            DatabaseConstants.colPaymentDate: payment.date.toIso8601String(),
            DatabaseConstants.colCashAmount: payment.cash,
            DatabaseConstants.colPaymentMethod: payment.paymentMethod ?? 'Cash',
            DatabaseConstants.colReceiptNumber: payment.receiptNumber ?? '',
            DatabaseConstants.colPaymentDescription: payment.description ?? '',
          },
        );
      }
      await batch.commit(noResult: true);
    }
    
    _databaseChangeController.add(null);
    return studentId;
  }

  Future<void> updateStudent(Student student) async {
    final db = await database;
    
    await db.update(
      DatabaseConstants.tableStudents,
      {
        DatabaseConstants.colParentContact: student.parentContact,
        DatabaseConstants.colReamPaid: student.reamPaid ? 1 : 0,
        DatabaseConstants.colFullName: student.fullName,
        DatabaseConstants.colFeesStructure: student.feesStructure,
        DatabaseConstants.colArrears: student.arrears,
        DatabaseConstants.colUpdatedAt: DateTime.now().toIso8601String(),
      },
      where: '${DatabaseConstants.colLedgerNo} = ?',
      whereArgs: [student.ledgerNo],
    );
    
    _databaseChangeController.add(null);
  }

  Future<void> deleteStudent(int studentId) async {
    final db = await database;
    
    await db.delete(
      DatabaseConstants.tableStudents,
      where: '${DatabaseConstants.colStudentId} = ?',
      whereArgs: [studentId],
    );
    
    _databaseChangeController.add(null);
  }

  Future<List<Student>> getStudentsByClass(String className, String sectionType) async {
    final db = await database;
    
    final maps = await db.query(
      DatabaseConstants.tableStudents,
      where: '${DatabaseConstants.colClassName} = ? AND ${DatabaseConstants.colSectionType} = ?',
      whereArgs: [className, sectionType],
      orderBy: DatabaseConstants.colLedgerNo,
    );
    
    List<Student> students = [];
    for (var map in maps) {
      students.add(await _mapToStudent(map, db));
    }
    
    return students;
  }

  Future<List<Student>> searchStudents(String query) async {
    final db = await database;
    
    final maps = await db.query(
      DatabaseConstants.tableStudents,
      where: '${DatabaseConstants.colFullName} LIKE ? OR ${DatabaseConstants.colLedgerNo} LIKE ? OR ${DatabaseConstants.colParentContact} LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%'],
      orderBy: DatabaseConstants.colFullName,
      limit: 50,
    );
    
    List<Student> students = [];
    for (var map in maps) {
      students.add(await _mapToStudent(map, db));
    }
    
    return students;
  }

  Future<List<Student>> getAllStudents() async {
    final db = await database;
    
    final maps = await db.query(
      DatabaseConstants.tableStudents,
      orderBy: '${DatabaseConstants.colClassName}, ${DatabaseConstants.colSectionType}, ${DatabaseConstants.colLedgerNo}',
    );
    
    List<Student> students = [];
    for (var map in maps) {
      students.add(await _mapToStudent(map, db));
    }
    
    return students;
  }

// Payment Records Operations - Simplified version
Future<int> insertPaymentRecord(int studentId, PaymentRecord payment) async {
  final db = await database;
  
  final paymentId = await db.insert(
    DatabaseConstants.tablePaymentRecords,
    {
      DatabaseConstants.colPaymentStudentId: studentId,
      DatabaseConstants.colPaymentDate: payment.date.toIso8601String(),
      DatabaseConstants.colCashAmount: payment.cash,
      DatabaseConstants.colPaymentMethod: payment.paymentMethod ?? 'Cash',
      DatabaseConstants.colReceiptNumber: payment.receiptNumber ?? '',
      DatabaseConstants.colPaymentDescription: payment.description ?? '',
    },
  );
  
  _databaseChangeController.add(null);
  return paymentId;
}


  Future<void> deletePaymentRecord(int paymentId) async {
    final db = await database;
    
    await db.delete(
      DatabaseConstants.tablePaymentRecords,
      where: '${DatabaseConstants.colPaymentId} = ?',
      whereArgs: [paymentId],
    );
    
    _databaseChangeController.add(null);
  }

  Future<List<PaymentRecord>> getPaymentRecords(int studentId) async {
    final db = await database;
    
    final maps = await db.query(
      DatabaseConstants.tablePaymentRecords,
      where: '${DatabaseConstants.colPaymentStudentId} = ?',
      whereArgs: [studentId],
      orderBy: '${DatabaseConstants.colPaymentDate} DESC',
    );
    
    return maps.map((map) => PaymentRecord(
      id: map[DatabaseConstants.colPaymentId] as int?,
      date: DateTime.parse(map[DatabaseConstants.colPaymentDate] as String),
      cash: (map[DatabaseConstants.colCashAmount] as num).toDouble(),
      paymentMethod: map[DatabaseConstants.colPaymentMethod] as String?,
      receiptNumber: map[DatabaseConstants.colReceiptNumber] as String?,
      description: map[DatabaseConstants.colPaymentDescription] as String?,
    )).toList();
  }

  // Class Section Operations
  Future<void> updateClassSectionTerm(String className, String sectionType, 
      String term, String year) async {
    final db = await database;
    
    var batch = db.batch();
    
    batch.update(
      DatabaseConstants.tableClassSections,
      {
        DatabaseConstants.colClassTerm: term,
        DatabaseConstants.colClassYear: year,
      },
      where: '${DatabaseConstants.colClassSectionName} = ? AND ${DatabaseConstants.colClassSectionType} = ?',
      whereArgs: [className, sectionType],
    );
    
    batch.update(
      DatabaseConstants.tableStudents,
      {
        DatabaseConstants.colTerm: term,
        DatabaseConstants.colYear: year,
      },
      where: '${DatabaseConstants.colClassName} = ? AND ${DatabaseConstants.colSectionType} = ?',
      whereArgs: [className, sectionType],
    );
    
    await batch.commit(noResult: true);
    _databaseChangeController.add(null);
  }

  Future<Map<String, String>> getClassSectionTerm(String className, String sectionType) async {
    final db = await database;
    
    final maps = await db.query(
      DatabaseConstants.tableClassSections,
      where: '${DatabaseConstants.colClassSectionName} = ? AND ${DatabaseConstants.colClassSectionType} = ?',
      whereArgs: [className, sectionType],
    );
    
    if (maps.isEmpty) {
      return {'term': 'ONE', 'year': '2026'};
    }
    
    return {
      'term': (maps.first[DatabaseConstants.colClassTerm] as String?) ?? 'ONE',
      'year': (maps.first[DatabaseConstants.colClassYear] as String?) ?? '2026',
    };
  }

  // Statistics
  Future<Map<String, dynamic>> getOverallStatistics() async {
    final students = await getAllStudents();
    double totalExpected = students.fold(0, (sum, s) => sum + s.expectedFees);
    double totalPaid = students.fold(0, (sum, s) => sum + s.feesPaid);
    
    return {
      'totalStudents': students.length,
      'totalClasses': 20,
      'totalExpected': totalExpected,
      'totalPaid': totalPaid,
      'totalBalance': totalExpected - totalPaid,
      'collectionRate': totalExpected > 0 ? (totalPaid / totalExpected) * 100 : 0.0,
    };
  }

  // Export
  Future<String> exportToCSV() async {
    final students = await getAllStudents();
    
    StringBuffer csv = StringBuffer();
    csv.writeln('Ledger No,Full Name,Parent Contact,Ream Paid,Fees Structure,Arrears,'
        'Expected Fees,Fees Paid,Balance,Class,Section,Term,Year');
    
    for (var student in students) {
      csv.writeln(
        '${student.ledgerNo},'
        '"${student.fullName}",'
        '"${student.parentContact}",'
        '${student.reamPaid ? "Yes" : "No"},'
        '${student.feesStructure},'
        '${student.arrears},'
        '${student.expectedFees},'
        '${student.feesPaid},'
        '${student.balance},'
        '${student.className},'
        '${student.sectionType},'
        '${student.term},'
        '${student.year}'
      );
    }
    
    return csv.toString();
  }

  // Clean up
  Future<void> clearAllData() async {
    final db = await database;
    await db.delete(DatabaseConstants.tablePaymentRecords);
    await db.delete(DatabaseConstants.tableStudents);
    _databaseChangeController.add(null);
  }

  // Helper Methods
  Future<String> _generateLedgerNumber(String className, String sectionType, Database db) async {
    String prefix;
    if (className.startsWith('P.')) {
      String classNum = className.substring(2);
      prefix = sectionType == 'Boarding' ? '${classNum}B ' : '${classNum}D ';
    } else {
      String classCode;
      switch (className) {
        case 'TOP CLASS':
          classCode = 'T';
          break;
        case 'MIDDLE CLASS':
          classCode = 'M';
          break;
        case 'BABY CLASS':
          classCode = 'B';
          break;
        default:
          classCode = 'X';
      }
      prefix = sectionType == 'Boarding' ? '${classCode}B ' : '${classCode}D ';
    }

    var result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM ${DatabaseConstants.tableStudents} '
      'WHERE ${DatabaseConstants.colClassName} = ? AND ${DatabaseConstants.colSectionType} = ?',
      [className, sectionType],
    );

    int count = Sqflite.firstIntValue(result) ?? 0;
    return '$prefix${(count + 1).toString().padLeft(2, '0')}';
  }

  Future<Student> _mapToStudent(Map<String, dynamic> map, Database db) async {
    int studentId = map[DatabaseConstants.colStudentId] as int;
    List<PaymentRecord> payments = await getPaymentRecords(studentId);

    return Student(
      ledgerNo: (map[DatabaseConstants.colLedgerNo] as String?) ?? '',
      parentContact: (map[DatabaseConstants.colParentContact] as String?) ?? '',
      reamPaid: (map[DatabaseConstants.colReamPaid] as int?) == 1,
      fullName: (map[DatabaseConstants.colFullName] as String?) ?? '',
      paymentRecords: payments,
      feesStructure: (map[DatabaseConstants.colFeesStructure] as num?)?.toDouble() ?? 0.0,
      arrears: (map[DatabaseConstants.colArrears] as num?)?.toDouble() ?? 0.0,
      className: (map[DatabaseConstants.colClassName] as String?) ?? '',
      sectionType: (map[DatabaseConstants.colSectionType] as String?) ?? '',
      term: (map[DatabaseConstants.colTerm] as String?) ?? 'ONE',
      year: (map[DatabaseConstants.colYear] as String?) ?? '2026',
      studentId: studentId,
    );
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
    await _databaseChangeController.close();
    _database = null;
  }

  void dispose() {
    _databaseChangeController.close();
    _database = null;
  }
}