import 'package:flutter/foundation.dart';

class DatabaseConstants {
  static const String databaseName = 'school_fees.db';
  static const int databaseVersion = 1;
  
<<<<<<< Updated upstream
  // Table names
  static const String tableStudents = 'students';
  static const String tablePaymentRecords = 'payment_records';
  static const String tableClassSections = 'classes';
=======
  // Table names - using consistent naming
  static const String classesTable = 'classes';
  static const String studentsTable = 'students';
  static const String paymentRecordsTable = 'payment_records';
>>>>>>> Stashed changes
  
  // Students table columns
  static const String colStudentId = 'id';
  static const String colStudentLedgerNo = 'ledger_no';
  static const String colStudentParentContact = 'parent_contact';
  static const String colStudentFullName = 'full_name';
  static const String colStudentClassName = 'class_name';
  static const String colStudentSectionType = 'section_type';
  static const String colStudentTerm = 'term';
  static const String colStudentYear = 'year';
  static const String colStudentFeesStructure = 'fees_structure';
  static const String colStudentArrears = 'arrears';
  static const String colStudentFeesPaid = 'fees_paid';
  static const String colStudentExpectedFees = 'expected_fees';
  static const String colStudentBalance = 'balance';
  
  // Payment Records table columns
  static const String colPaymentId = 'id';
  static const String colPaymentStudentId = 'student_id';
  static const String colPaymentAmount = 'amount';
  static const String colPaymentDate = 'payment_date';
  static const String colPaymentMethod = 'payment_method';
  static const String colPaymentReceiptNumber = 'receipt_number';
  static const String colPaymentNotes = 'notes';
  
  // Classes table columns
  static const String colClassId = 'id';
  static const String colClassName = 'class_name';
  static const String colClassSectionType = 'section_type';
  static const String colClassTerm = 'term';
  static const String colClassYear = 'year';
<<<<<<< Updated upstream
  
  // SQL Queries
  static const String createStudentsTable = '''
    CREATE TABLE $tableStudents (
      $colStudentId INTEGER PRIMARY KEY AUTOINCREMENT,
      $colStudentLedgerNo TEXT UNIQUE NOT NULL,
      $colStudentParentContact TEXT,
      $colStudentFullName TEXT NOT NULL,
      $colStudentClassName TEXT NOT NULL,
      $colStudentSectionType TEXT NOT NULL,
      $colStudentTerm TEXT NOT NULL,
      $colStudentYear TEXT NOT NULL,
      $colStudentFeesStructure REAL DEFAULT 0,
      $colStudentArrears REAL DEFAULT 0,
      $colStudentFeesPaid REAL DEFAULT 0,
      $colStudentExpectedFees REAL DEFAULT 0,
      $colStudentBalance REAL DEFAULT 0
    )
  ''';
  
  static const String createPaymentRecordsTable = '''
    CREATE TABLE $tablePaymentRecords (
      $colPaymentId INTEGER PRIMARY KEY AUTOINCREMENT,
      $colPaymentStudentId INTEGER NOT NULL,
      $colPaymentAmount REAL NOT NULL,
      $colPaymentDate TEXT NOT NULL,
      $colPaymentMethod TEXT NOT NULL,
      $colPaymentReceiptNumber TEXT,
      $colPaymentNotes TEXT,
      FOREIGN KEY ($colPaymentStudentId) REFERENCES $tableStudents($colStudentId) ON DELETE CASCADE
    )
  ''';
  
  static const String createClassesTable = '''
    CREATE TABLE $tableClassSections (
      $colClassId INTEGER PRIMARY KEY AUTOINCREMENT,
      $colClassName TEXT NOT NULL,
      $colClassSectionType TEXT NOT NULL,
      $colClassTerm TEXT NOT NULL,
      $colClassYear TEXT NOT NULL,
      UNIQUE($colClassName, $colClassSectionType)
    )
  ''';
}
=======
}
>>>>>>> Stashed changes
