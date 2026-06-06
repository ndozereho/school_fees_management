import 'student.dart';

class ClassSection {
  String className;
  String sectionType; // 'Boarding' or 'Day'
  String term;
  String year;
  List<Student> students;
  int? id; // Database ID

  ClassSection({
    required this.className,
    required this.sectionType,
    this.term = 'ONE',
    this.year = '2026',
    List<Student>? students,
    this.id,
  }) : students = students ?? [];

  // Computed properties
  double get totalExpectedFees => 
      students.fold(0, (sum, student) => sum + student.expectedFees);
  
  double get totalFeesPaid => 
      students.fold(0, (sum, student) => sum + student.feesPaid);
  
  double get totalBalance => 
      students.fold(0, (sum, student) => sum + student.balance);
  
  double get totalArrears => 
      students.fold(0, (sum, student) => sum + student.arrears);
  
  double get totalFeesStructure => 
      students.fold(0, (sum, student) => sum + student.feesStructure);
  
  int get totalStudents => students.length;
  
  int get fullyPaidCount => 
      students.where((s) => s.balance <= 0).length;
  
  int get partiallyPaidCount => 
      students.where((s) => s.feesPaid > 0 && s.balance > 0).length;
  
  int get notPaidCount => 
      students.where((s) => s.feesPaid == 0).length;
  
  double get collectionRate {
    if (totalExpectedFees == 0) return 0;
    return (totalFeesPaid / totalExpectedFees) * 100;
  }

  // Generate ledger number prefix
  String get ledgerPrefix {
    if (className.startsWith('P.')) {
      String classNum = className.substring(2);
      return sectionType == 'Boarding' ? '${classNum}B' : '${classNum}D';
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
      return sectionType == 'Boarding' ? '${classCode}B' : '${classCode}D';
    }
  }

  // Auto-generate ledger numbers for all students
  void autoGenerateLedgerNumbers() {
    for (int i = 0; i < students.length; i++) {
      students[i].ledgerNo = '$ledgerPrefix ${(i + 1).toString().padLeft(2, '0')}';
    }
  }

  // Generate next ledger number
  String generateNextLedgerNumber() {
    return '$ledgerPrefix ${(students.length + 1).toString().padLeft(2, '0')}';
  }

  // Get student by ledger number
  Student? getStudentByLedgerNo(String ledgerNo) {
    try {
      return students.firstWhere((s) => s.ledgerNo == ledgerNo);
    } catch (e) {
      return null;
    }
  }

  // Get student by name
  List<Student> searchStudentsByName(String name) {
    return students
        .where((s) => s.fullName.toLowerCase().contains(name.toLowerCase()))
        .toList();
  }

  // Sort students by ledger number
  void sortByLedgerNumber() {
    students.sort((a, b) => a.ledgerNo.compareTo(b.ledgerNo));
  }

  // Sort students by name
  void sortByName() {
    students.sort((a, b) => a.fullName.compareTo(b.fullName));
  }

  // Sort students by balance
  void sortByBalance({bool descending = true}) {
    students.sort((a, b) => descending 
        ? b.balance.compareTo(a.balance) 
        : a.balance.compareTo(b.balance));
  }

  // Get students with arrears
  List<Student> get studentsWithArrears => 
      students.where((s) => s.arrears > 0).toList();

  // Get students with outstanding balance
  List<Student> get studentsWithBalance => 
      students.where((s) => s.balance > 0).toList();

  // Get summary statistics
  Map<String, dynamic> getSummary() {
    return {
      'className': className,
      'sectionType': sectionType,
      'term': term,
      'year': year,
      'totalStudents': totalStudents,
      'totalExpectedFees': totalExpectedFees,
      'totalFeesPaid': totalFeesPaid,
      'totalBalance': totalBalance,
      'totalArrears': totalArrears,
      'totalFeesStructure': totalFeesStructure,
      'fullyPaidCount': fullyPaidCount,
      'partiallyPaidCount': partiallyPaidCount,
      'notPaidCount': notPaidCount,
      'collectionRate': collectionRate,
    };
  }

  // Convert to map for database
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'className': className,
      'sectionType': sectionType,
      'term': term,
      'year': year,
    };
  }

  // Create from map
  factory ClassSection.fromMap(Map<String, dynamic> map) {
    return ClassSection(
      id: map['id'],
      className: map['className'],
      sectionType: map['sectionType'],
      term: map['term'] ?? 'ONE',
      year: map['year'] ?? '2026',
    );
  }
}

// Data manager for organizing all classes
class SchoolClassesManager {
  Map<String, ClassSection> primaryClasses = {};
  Map<String, ClassSection> kindergartenClasses = {};
  Map<String, ClassSection> allClasses = {};

  // Initialize all classes
  void initializeClasses() {
    List<String> primaryClassList = ['P.7', 'P.6', 'P.5', 'P.4', 'P.3', 'P.2', 'P.1'];
    List<String> kgClassList = ['TOP CLASS', 'MIDDLE CLASS', 'BABY CLASS'];
    List<String> sectionTypes = ['Boarding', 'Day'];

    // Initialize Primary Classes
    for (String className in primaryClassList) {
      for (String sectionType in sectionTypes) {
        String key = '${className}_$sectionType';
        var classSection = ClassSection(
          className: className,
          sectionType: sectionType,
        );
        primaryClasses[key] = classSection;
        allClasses[key] = classSection;
      }
    }

    // Initialize Kindergarten Classes
    for (String className in kgClassList) {
      for (String sectionType in sectionTypes) {
        String key = '${className}_$sectionType';
        var classSection = ClassSection(
          className: className,
          sectionType: sectionType,
        );
        kindergartenClasses[key] = classSection;
        allClasses[key] = classSection;
      }
    }
  }

  // Get class section
  ClassSection? getClassSection(String className, String sectionType) {
    String key = '${className}_$sectionType';
    return allClasses[key];
  }

  // Get all class names
  List<String> getAllClassNames() {
    return [
      ...['P.7', 'P.6', 'P.5', 'P.4', 'P.3', 'P.2', 'P.1'],
      ...['TOP CLASS', 'MIDDLE CLASS', 'BABY CLASS']
    ];
  }

  // Get total statistics
  Map<String, dynamic> getTotalStatistics() {
    int totalStudents = 0;
    double totalExpected = 0;
    double totalPaid = 0;
    double totalBalance = 0;

    for (var section in allClasses.values) {
      totalStudents += section.totalStudents;
      totalExpected += section.totalExpectedFees;
      totalPaid += section.totalFeesPaid;
      totalBalance += section.totalBalance;
    }

    return {
      'totalStudents': totalStudents,
      'totalExpected': totalExpected,
      'totalPaid': totalPaid,
      'totalBalance': totalBalance,
      'totalClasses': allClasses.length,
      'collectionRate': totalExpected > 0 ? (totalPaid / totalExpected) * 100 : 0,
    };
  }
}