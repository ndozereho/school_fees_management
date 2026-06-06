import 'package:intl/intl.dart';
import 'payment_record.dart';

class Student {
  String ledgerNo;
  String parentContact;
  bool reamPaid;
  String fullName;
  List<PaymentRecord> paymentRecords;
  double feesStructure;
  double arrears;
  String className;
  String sectionType;
  String term;
  String year;
  int? studentId; // Database ID

  Student({
    required this.ledgerNo,
    this.parentContact = '',
    this.reamPaid = false,
    required this.fullName,
    List<PaymentRecord>? paymentRecords,
    this.feesStructure = 0,
    this.arrears = 0,
    this.className = '',
    this.sectionType = '',
    this.term = 'ONE',
    this.year = '2026',
    this.studentId,
  }) : paymentRecords = paymentRecords ?? [];

  // Computed properties
  double get expectedFees => feesStructure + arrears;
  
  double get feesPaid => paymentRecords.fold(0, (sum, record) => sum + record.cash);
  
  double get balance => expectedFees - feesPaid;
  
  bool get isFullyPaid => balance <= 0;
  
  bool get isPartiallyPaid => feesPaid > 0 && balance > 0;
  
  bool get hasNotPaid => feesPaid == 0;
  
  double get overpayment => balance < 0 ? balance.abs() : 0;
  
  String get paymentStatus {
    if (isFullyPaid) return 'Fully Paid';
    if (isPartiallyPaid) return 'Partially Paid';
    return 'Not Paid';
  }

  // Formatted getters
  String get formattedExpectedFees => _formatCurrency(expectedFees);
  String get formattedFeesPaid => _formatCurrency(feesPaid);
  String get formattedBalance => _formatCurrency(balance);
  String get formattedFeesStructure => _formatCurrency(feesStructure);
  String get formattedArrears => _formatCurrency(arrears);
  
  // Payment records summary
  String get paymentRecordsSummary {
    if (paymentRecords.isEmpty) return 'No payments';
    return '${paymentRecords.length} payment(s)';
  }
  
  DateTime? get lastPaymentDate {
    if (paymentRecords.isEmpty) return null;
    paymentRecords.sort((a, b) => b.date.compareTo(a.date));
    return paymentRecords.first.date;
  }
  
  String get lastPaymentDateFormatted {
    if (lastPaymentDate == null) return 'N/A';
    return DateFormat('dd-MMM-yyyy').format(lastPaymentDate!);
  }
  
  double get lastPaymentAmount {
    if (paymentRecords.isEmpty) return 0;
    paymentRecords.sort((a, b) => b.date.compareTo(a.date));
    return paymentRecords.first.cash;
  }

  // Methods
  void addPayment(PaymentRecord record) {
    paymentRecords.add(record);
  }

  void removePayment(int index) {
    if (index >= 0 && index < paymentRecords.length) {
      paymentRecords.removeAt(index);
    }
  }
  
  void removePaymentById(int paymentId) {
    paymentRecords.removeWhere((record) => record.id == paymentId);
  }
  
  void clearAllPayments() {
    paymentRecords.clear();
  }
  
  // Get payments by date range
  List<PaymentRecord> getPaymentsByDateRange(DateTime start, DateTime end) {
    return paymentRecords.where((record) => 
      record.date.isAfter(start.subtract(const Duration(days: 1))) && 
      record.date.isBefore(end.add(const Duration(days: 1)))
    ).toList();
  }
  
  // Get total payments for a specific period
  double getPaymentsTotalForPeriod(DateTime start, DateTime end) {
    return getPaymentsByDateRange(start, end)
        .fold(0, (sum, record) => sum + record.cash);
  }

  // Copy with updated fields
  Student copyWith({
    String? ledgerNo,
    String? parentContact,
    bool? reamPaid,
    String? fullName,
    List<PaymentRecord>? paymentRecords,
    double? feesStructure,
    double? arrears,
    String? className,
    String? sectionType,
    String? term,
    String? year,
    int? studentId,
  }) {
    return Student(
      ledgerNo: ledgerNo ?? this.ledgerNo,
      parentContact: parentContact ?? this.parentContact,
      reamPaid: reamPaid ?? this.reamPaid,
      fullName: fullName ?? this.fullName,
      paymentRecords: paymentRecords ?? List.from(this.paymentRecords),
      feesStructure: feesStructure ?? this.feesStructure,
      arrears: arrears ?? this.arrears,
      className: className ?? this.className,
      sectionType: sectionType ?? this.sectionType,
      term: term ?? this.term,
      year: year ?? this.year,
      studentId: studentId ?? this.studentId,
    );
  }

  // Convert to Map for database operations
  Map<String, dynamic> toMap() {
    return {
      'studentId': studentId,
      'ledgerNo': ledgerNo,
      'parentContact': parentContact,
      'reamPaid': reamPaid ? 1 : 0,
      'fullName': fullName,
      'feesStructure': feesStructure,
      'arrears': arrears,
      'className': className,
      'sectionType': sectionType,
      'term': term,
      'year': year,
    };
  }

  // Create from Map (database query result)
  factory Student.fromMap(Map<String, dynamic> map) {
    return Student(
      studentId: map['studentId'],
      ledgerNo: map['ledgerNo'] ?? '',
      parentContact: map['parentContact'] ?? '',
      reamPaid: (map['reamPaid'] ?? 0) == 1,
      fullName: map['fullName'] ?? '',
      feesStructure: (map['feesStructure'] ?? 0).toDouble(),
      arrears: (map['arrears'] ?? 0).toDouble(),
      className: map['className'] ?? '',
      sectionType: map['sectionType'] ?? '',
      term: map['term'] ?? 'ONE',
      year: map['year'] ?? '2026',
    );
  }

  // Convert to CSV row
  String toCSVRow() {
    return '$ledgerNo,$fullName,$parentContact,${reamPaid ? "Yes" : "No"},'
        '$feesStructure,$arrears,$expectedFees,$feesPaid,$balance,'
        '$className,$sectionType,$term,$year';
  }

  // CSV Header
  static String get csvHeader {
    return 'Ledger No,Full Name,Parent Contact,Ream Paid,Fees Structure,'
        'Arrears,Expected Fees,Fees Paid,Balance,Class,Section,Term,Year';
  }

  // Override toString for debugging
  @override
  String toString() {
    return 'Student(ledgerNo: $ledgerNo, name: $fullName, '
        'class: $className, section: $sectionType, '
        'balance: $formattedBalance)';
  }

  // Override equality operator
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Student && other.ledgerNo == ledgerNo;
  }

  @override
  int get hashCode => ledgerNo.hashCode;

  // Private helper method
  String _formatCurrency(double amount) {
    final formatter = NumberFormat('#,###');
    return formatter.format(amount);
  }
}