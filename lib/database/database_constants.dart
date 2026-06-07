
class DatabaseConstants {
  static const String databaseName = 'school_fees.db';
  static const int databaseVersion = 1;
  
  // Table names
  static const String studentsTable = 'students';
  static const String paymentRecordsTable = 'payment_records';
  static const String classesTable = 'classes';
  
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
}