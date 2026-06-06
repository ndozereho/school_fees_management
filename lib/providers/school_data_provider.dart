import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/student.dart';
import '../models/payment_record.dart';

class SchoolDataProvider extends ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  
  List<Student> _allStudents = [];
  List<Student> _filteredStudents = [];
  Map<String, List<Student>> _studentsByClass = {};
  
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';
  Map<String, dynamic> _overallStats = {};
  StreamSubscription<void>? _dbChangeSubscription;

  // Getters
  List<Student> get allStudents => _allStudents;
  List<Student> get filteredStudents => _filteredStudents;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  Map<String, dynamic> get overallStats => _overallStats;
  
  // Computed properties
  int get totalStudentCount => _allStudents.length;
  int get primaryStudentCount => _allStudents.where((s) => s.className.startsWith('P.')).length;
  int get kindergartenStudentCount => _allStudents.where((s) => !s.className.startsWith('P.')).length;
  int get boardingStudentCount => _allStudents.where((s) => s.sectionType == 'Boarding').length;
  int get dayStudentCount => _allStudents.where((s) => s.sectionType == 'Day').length;

  // Initialize and load data
  Future<void> initialize() async {
    await loadAllData();
    _listenToDatabaseChanges();
  }

  void _listenToDatabaseChanges() {
    _dbChangeSubscription?.cancel();
    _dbChangeSubscription = _dbHelper.databaseChanges.listen((_) {
      loadAllData();
    });
  }

  // Load all data from database
  Future<void> loadAllData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _allStudents = await _dbHelper.getAllStudents();
      _overallStats = await _dbHelper.getOverallStatistics();
      _organizeStudentsByClass();
      _applySearchFilter();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load data: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  void _organizeStudentsByClass() {
    _studentsByClass = {};
    for (var student in _allStudents) {
      String key = '${student.className}_${student.sectionType}';
      _studentsByClass.putIfAbsent(key, () => []).add(student);
    }
  }

  void _applySearchFilter() {
    if (_searchQuery.isEmpty) {
      _filteredStudents = List.from(_allStudents);
    } else {
      _filteredStudents = _allStudents.where((student) =>
        student.fullName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        student.ledgerNo.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        student.parentContact.toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }
  }

  // Search functionality
  void setSearchQuery(String query) {
    _searchQuery = query;
    _applySearchFilter();
    notifyListeners();
  }

  Future<List<Student>> searchStudents(String query) async {
    return await _dbHelper.searchStudents(query);
  }

  // Student operations
  Future<int> addStudent(Student student, String className, String sectionType, 
      {String term = 'ONE', String year = '2026'}) async {
    try {
      int studentId = await _dbHelper.insertStudent(student, className, sectionType, term: term, year: year);
      await loadAllData();
      return studentId;
    } catch (e) {
      _error = 'Failed to add student: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateStudent(Student student) async {
    try {
      await _dbHelper.updateStudent(student);
      await loadAllData();
    } catch (e) {
      _error = 'Failed to update student: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteStudent(Student student) async {
    try {
      if (student.studentId != null) {
        await _dbHelper.deleteStudent(student.studentId!);
      }
      await loadAllData();
    } catch (e) {
      _error = 'Failed to delete student: $e';
      notifyListeners();
      rethrow;
    }
  }

// Add Payment Method - Updated version
Future<void> addPayment(Student student, double amount, DateTime date, String className, String sectionType, String term, String year) async {
  try {
    if (student.studentId == null) {
      throw Exception('Student ID is null');
    }
    
    final paymentRecord = PaymentRecord(
      id: null,
      cash: amount,
      date: date,
      paymentMethod: 'Cash',
      receiptNumber: 'RCP${DateTime.now().millisecondsSinceEpoch}',
      description: 'Payment for $className - Term $term $year',
    );
    
    // Add to local student object
    student.addPayment(paymentRecord);
    
    // Save to database
    await _dbHelper.insertPaymentRecord(student.studentId!, paymentRecord);
    
    // Refresh data
    await loadAllData();
    notifyListeners();
  } catch (e) {
    debugPrint('Error adding payment: $e');
    _error = 'Failed to add payment: $e';
    notifyListeners();
    rethrow;
  }
}
  // Delete Payment Method
  Future<void> deletePayment(Student student, PaymentRecord payment) async {
    try {
      // Remove from local student object
      student.removePaymentById(payment.id ?? 0);
      
      // Delete from database
      await _dbHelper.deletePaymentRecord(payment.id ?? 0);
      
      // Refresh data
      await loadAllData();
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting payment: $e');
      _error = 'Failed to delete payment: $e';
      notifyListeners();
      rethrow;
    }
  }

  // Payment operations (legacy)
  Future<int> addPaymentRecord(int studentId, PaymentRecord payment) async {
    try {
      int paymentId = await _dbHelper.insertPaymentRecord(studentId, payment);
      await loadAllData();
      return paymentId;
    } catch (e) {
      _error = 'Failed to add payment: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deletePaymentRecord(int paymentId) async {
    try {
      await _dbHelper.deletePaymentRecord(paymentId);
      await loadAllData();
    } catch (e) {
      _error = 'Failed to delete payment: $e';
      notifyListeners();
      rethrow;
    }
  }

  // Get students by class and section (synchronous - uses cached data)
  List<Student> getStudentsByClass(String className, String sectionType) {
    String key = '${className}_$sectionType';
    return _studentsByClass[key] ?? [];
  }

  // Get student by ledger number (searches cached data)
  Student? getStudentByLedgerNo(String ledgerNo) {
    for (var student in _allStudents) {
      if (student.ledgerNo == ledgerNo) return student;
    }
    return null;
  }

  // Term and Year management
  Future<void> updateClassTerm(String className, String sectionType, String term, String year) async {
    try {
      await _dbHelper.updateClassSectionTerm(className, sectionType, term, year);
      await loadAllData();
    } catch (e) {
      _error = 'Failed to update term: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<Map<String, String>> getClassTerm(String className, String sectionType) async {
    return await _dbHelper.getClassSectionTerm(className, sectionType);
  }

  // Statistics
  Future<Map<String, dynamic>> getOverallStatistics() async {
    return await _dbHelper.getOverallStatistics();
  }

  // Export
  Future<String> exportToCSV() async {
    return await _dbHelper.exportToCSV();
  }

  // Maintenance
  Future<void> clearAllData() async {
    try {
      await _dbHelper.clearAllData();
      _allStudents = [];
      _filteredStudents = [];
      _studentsByClass = {};
      _overallStats = {};
      notifyListeners();
    } catch (e) {
      _error = 'Failed to clear data: $e';
      notifyListeners();
      rethrow;
    }
  }

  // Authentication
  Future<bool> authenticateUser(String username, String password) async {
    return await _dbHelper.authenticateUser(username, password);
  }

  // Error handling
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Dispose
  @override
  void dispose() {
    _dbChangeSubscription?.cancel();
    _dbHelper.dispose();
    super.dispose();
  }
}