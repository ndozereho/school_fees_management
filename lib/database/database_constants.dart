class DatabaseConstants {
  // Database Information
  static const String databaseName = 'school_fees.db';
  static const int databaseVersion = 1;

  // Students Table
  static const String tableStudents = 'students';
  static const String colStudentId = 'id';
  static const String colLedgerNo = 'ledger_no';
  static const String colParentContact = 'parent_contact';
  static const String colReamPaid = 'ream_paid';
  static const String colFullName = 'full_name';
  static const String colFeesStructure = 'fees_structure';
  static const String colArrears = 'arrears';
  static const String colClassName = 'class_name';
  static const String colSectionType = 'section_type';
  static const String colTerm = 'term';
  static const String colYear = 'year';
  static const String colCreatedAt = 'created_at';
  static const String colUpdatedAt = 'updated_at';

  // Payment Records Table
  static const String tablePaymentRecords = 'payment_records';
  static const String colPaymentId = 'id';
  static const String colPaymentStudentId = 'student_id';
  static const String colPaymentDate = 'payment_date';
  static const String colCashAmount = 'cash_amount';
  static const String colPaymentMethod = 'payment_method';
  static const String colReceiptNumber = 'receipt_number';
  static const String colPaymentDescription = 'description';
  static const String colPaymentCreatedAt = 'created_at';

  // Class Sections Table
  static const String tableClassSections = 'class_sections';
  static const String colClassSectionId = 'id';
  static const String colClassSectionName = 'class_name';
  static const String colClassSectionType = 'section_type';
  static const String colClassTerm = 'term';
  static const String colClassYear = 'year';
  static const String colClassCreatedAt = 'created_at';

  // Users Table (for authentication)
  static const String tableUsers = 'users';
  static const String colUserId = 'id';
  static const String colUsername = 'username';
  static const String colPassword = 'password';
  static const String colUserRole = 'role';
  static const String colUserCreatedAt = 'created_at';

  // Audit Log Table
  static const String tableAuditLog = 'audit_log';
  static const String colAuditId = 'id';
  static const String colAuditAction = 'action';
  static const String colAuditDescription = 'description';
  static const String colAuditUserId = 'user_id';
  static const String colAuditTimestamp = 'timestamp';

  // Create Tables SQL
  static const String createStudentsTable = '''
    CREATE TABLE IF NOT EXISTS $tableStudents (
      $colStudentId INTEGER PRIMARY KEY AUTOINCREMENT,
      $colLedgerNo TEXT NOT NULL UNIQUE,
      $colParentContact TEXT DEFAULT '',
      $colReamPaid INTEGER DEFAULT 0,
      $colFullName TEXT NOT NULL,
      $colFeesStructure REAL DEFAULT 0.0,
      $colArrears REAL DEFAULT 0.0,
      $colClassName TEXT NOT NULL,
      $colSectionType TEXT NOT NULL,
      $colTerm TEXT DEFAULT 'ONE',
      $colYear TEXT DEFAULT '2026',
      $colCreatedAt TEXT DEFAULT (datetime('now')),
      $colUpdatedAt TEXT DEFAULT (datetime('now'))
    )
  ''';

  static const String createPaymentRecordsTable = '''
    CREATE TABLE IF NOT EXISTS $tablePaymentRecords (
      $colPaymentId INTEGER PRIMARY KEY AUTOINCREMENT,
      $colPaymentStudentId INTEGER NOT NULL,
      $colPaymentDate TEXT NOT NULL,
      $colCashAmount REAL NOT NULL,
      $colPaymentMethod TEXT DEFAULT 'Cash',
      $colReceiptNumber TEXT,
      $colPaymentDescription TEXT,
      $colPaymentCreatedAt TEXT DEFAULT (datetime('now')),
      FOREIGN KEY ($colPaymentStudentId) REFERENCES $tableStudents ($colStudentId)
        ON DELETE CASCADE
        ON UPDATE CASCADE
    )
  ''';

  static const String createClassSectionsTable = '''
    CREATE TABLE IF NOT EXISTS $tableClassSections (
      $colClassSectionId INTEGER PRIMARY KEY AUTOINCREMENT,
      $colClassSectionName TEXT NOT NULL,
      $colClassSectionType TEXT NOT NULL,
      $colClassTerm TEXT DEFAULT 'ONE',
      $colClassYear TEXT DEFAULT '2026',
      $colClassCreatedAt TEXT DEFAULT (datetime('now')),
      UNIQUE($colClassSectionName, $colClassSectionType)
    )
  ''';

  static const String createUsersTable = '''
    CREATE TABLE IF NOT EXISTS $tableUsers (
      $colUserId INTEGER PRIMARY KEY AUTOINCREMENT,
      $colUsername TEXT NOT NULL UNIQUE,
      $colPassword TEXT NOT NULL,
      $colUserRole TEXT DEFAULT 'user',
      $colUserCreatedAt TEXT DEFAULT (datetime('now'))
    )
  ''';

  static const String createAuditLogTable = '''
    CREATE TABLE IF NOT EXISTS $tableAuditLog (
      $colAuditId INTEGER PRIMARY KEY AUTOINCREMENT,
      $colAuditAction TEXT NOT NULL,
      $colAuditDescription TEXT,
      $colAuditUserId INTEGER,
      $colAuditTimestamp TEXT DEFAULT (datetime('now')),
      FOREIGN KEY ($colAuditUserId) REFERENCES $tableUsers ($colUserId)
        ON DELETE SET NULL
    )
  ''';

  // Create Indexes
  static const List<String> createIndexes = [
    'CREATE INDEX IF NOT EXISTS idx_students_class ON $tableStudents($colClassName, $colSectionType)',
    'CREATE INDEX IF NOT EXISTS idx_students_ledger ON $tableStudents($colLedgerNo)',
    'CREATE INDEX IF NOT EXISTS idx_students_name ON $tableStudents($colFullName)',
    'CREATE INDEX IF NOT EXISTS idx_payments_student ON $tablePaymentRecords($colPaymentStudentId)',
    'CREATE INDEX IF NOT EXISTS idx_payments_date ON $tablePaymentRecords($colPaymentDate)',
    'CREATE INDEX IF NOT EXISTS idx_audit_timestamp ON $tableAuditLog($colAuditTimestamp)',
    'CREATE INDEX IF NOT EXISTS idx_audit_action ON $tableAuditLog($colAuditAction)',
  ];

  // Default Data
  static const String insertDefaultAdmin = '''
    INSERT OR IGNORE INTO $tableUsers ($colUsername, $colPassword, $colUserRole) 
    VALUES ('admin', 'admin123', 'admin')
  ''';

  static const String insertDefaultUser = '''
    INSERT OR IGNORE INTO $tableUsers ($colUsername, $colPassword, $colUserRole) 
    VALUES ('user', 'user123', 'user')
  ''';

  // Default Class Sections
  static const List<Map<String, String>> defaultClassSections = [
    // Primary Classes - Boarding
    {'class_name': 'P.7', 'section_type': 'Boarding'},
    {'class_name': 'P.6', 'section_type': 'Boarding'},
    {'class_name': 'P.5', 'section_type': 'Boarding'},
    {'class_name': 'P.4', 'section_type': 'Boarding'},
    {'class_name': 'P.3', 'section_type': 'Boarding'},
    {'class_name': 'P.2', 'section_type': 'Boarding'},
    {'class_name': 'P.1', 'section_type': 'Boarding'},
    // Primary Classes - Day
    {'class_name': 'P.7', 'section_type': 'Day'},
    {'class_name': 'P.6', 'section_type': 'Day'},
    {'class_name': 'P.5', 'section_type': 'Day'},
    {'class_name': 'P.4', 'section_type': 'Day'},
    {'class_name': 'P.3', 'section_type': 'Day'},
    {'class_name': 'P.2', 'section_type': 'Day'},
    {'class_name': 'P.1', 'section_type': 'Day'},
    // Kindergarten Classes - Boarding
    {'class_name': 'TOP CLASS', 'section_type': 'Boarding'},
    {'class_name': 'MIDDLE CLASS', 'section_type': 'Boarding'},
    {'class_name': 'BABY CLASS', 'section_type': 'Boarding'},
    // Kindergarten Classes - Day
    {'class_name': 'TOP CLASS', 'section_type': 'Day'},
    {'class_name': 'MIDDLE CLASS', 'section_type': 'Day'},
    {'class_name': 'BABY CLASS', 'section_type': 'Day'},
  ];

  // Query Templates
  static const String selectAllStudents = '''
    SELECT * FROM $tableStudents 
    ORDER BY $colClassName, $colSectionType, $colLedgerNo
  ''';

  static const String selectStudentsByClass = '''
    SELECT * FROM $tableStudents 
    WHERE $colClassName = ? AND $colSectionType = ?
    ORDER BY $colLedgerNo
  ''';

  static const String searchStudents = '''
    SELECT * FROM $tableStudents 
    WHERE $colFullName LIKE ? OR $colLedgerNo LIKE ? OR $colParentContact LIKE ?
    ORDER BY $colFullName
    LIMIT 50
  ''';

  static const String selectPaymentsByStudent = '''
    SELECT * FROM $tablePaymentRecords 
    WHERE $colPaymentStudentId = ?
    ORDER BY $colPaymentDate DESC
  ''';

  static const String classFinancialSummary = '''
    SELECT 
      COUNT(*) as student_count,
      SUM($colFeesStructure) as total_fees_structure,
      SUM($colArrears) as total_arrears,
      SUM($colFeesStructure + $colArrears) as total_expected,
      COUNT(CASE WHEN $colReamPaid = 1 THEN 1 END) as paid_count
    FROM $tableStudents
    WHERE $colClassName = ? AND $colSectionType = ?
  ''';

  static const String overallStatistics = '''
    SELECT 
      COUNT(DISTINCT s.$colStudentId) as total_students,
      COUNT(DISTINCT s.$colClassName || s.$colSectionType) as total_classes,
      SUM(s.$colFeesStructure + s.$colArrears) as total_expected,
      COALESCE(SUM(p.total_paid), 0) as total_paid
    FROM $tableStudents s
    LEFT JOIN (
      SELECT $colPaymentStudentId, SUM($colCashAmount) as total_paid
      FROM $tablePaymentRecords
      GROUP BY $colPaymentStudentId
    ) p ON s.$colStudentId = p.$colPaymentStudentId
  ''';

  static const String getStudentWithPayments = '''
    SELECT 
      s.*,
      COALESCE(SUM(pr.$colCashAmount), 0) as total_paid
    FROM $tableStudents s
    LEFT JOIN $tablePaymentRecords pr ON s.$colStudentId = pr.$colPaymentStudentId
    WHERE s.$colStudentId = ?
    GROUP BY s.$colStudentId
  ''';

  static const String getClassCollectionRate = '''
    SELECT 
      $colClassName,
      $colSectionType,
      COUNT(*) as student_count,
      SUM($colFeesStructure + $colArrears) as total_expected,
      COALESCE(SUM((
        SELECT COALESCE(SUM($colCashAmount), 0)
        FROM $tablePaymentRecords
        WHERE $colPaymentStudentId = s.$colStudentId
      )), 0) as total_paid
    FROM $tableStudents s
    WHERE $colClassName = ? AND $colSectionType = ?
    GROUP BY $colClassName, $colSectionType
  ''';

  // Validation Constants
  static const int maxLedgerNoLength = 10;
  static const int maxFullNameLength = 100;
  static const int maxParentContactLength = 50;
  static const double maxFeesAmount = 99999999.99;
  static const double minFeesAmount = 0.0;
  
  // Term Constants
  static const List<String> validTerms = ['ONE', 'TWO', 'THREE'];
  static const List<String> validSectionTypes = ['Boarding', 'Day'];
  
  // Date Format for Database
  static const String dateTimeFormat = 'yyyy-MM-dd HH:mm:ss';
  static const String dateFormat = 'yyyy-MM-dd';
}