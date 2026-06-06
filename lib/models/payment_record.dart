import 'package:intl/intl.dart';

class PaymentRecord {
  int? id;
  double cash;
  DateTime date;
  int? studentId;
  String? studentLedgerNo;
  String? paymentMethod;
  String? receiptNumber;
  String? description;

  PaymentRecord({
    this.id,
    required this.cash,
    required this.date,
    this.studentId,
    this.studentLedgerNo,
    this.paymentMethod = 'Cash',
    this.receiptNumber,
    this.description,
  });

  // Convert to map for database
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'cash': cash,
      'date': date.toIso8601String(),
      'studentId': studentId,
      'paymentMethod': paymentMethod ?? 'Cash',
      'receiptNumber': receiptNumber ?? '',
      'description': description ?? '',
    };
  }

  // Create from map
  factory PaymentRecord.fromMap(Map<String, dynamic> map) {
    return PaymentRecord(
      id: map['id'],
      cash: (map['cash'] ?? 0).toDouble(),
      date: DateTime.parse(map['date']),
      studentId: map['studentId'],
      paymentMethod: map['paymentMethod'] ?? 'Cash',
      receiptNumber: map['receiptNumber'] ?? '',
      description: map['description'] ?? '',
    );
  }

  // Formatted getters
  String get formattedCash => NumberFormat('#,###').format(cash);
  String get formattedDate => DateFormat('dd-MMM-yyyy HH:mm').format(date);
  String get formattedShortDate => DateFormat('dd-MMM-yyyy').format(date);

  // Copy with method
  PaymentRecord copyWith({
    int? id,
    double? cash,
    DateTime? date,
    int? studentId,
    String? studentLedgerNo,
    String? paymentMethod,
    String? receiptNumber,
    String? description,
  }) {
    return PaymentRecord(
      id: id ?? this.id,
      cash: cash ?? this.cash,
      date: date ?? this.date,
      studentId: studentId ?? this.studentId,
      studentLedgerNo: studentLedgerNo ?? this.studentLedgerNo,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      receiptNumber: receiptNumber ?? this.receiptNumber,
      description: description ?? this.description,
    );
  }

  // Override toString for debugging
  @override
  String toString() {
    return 'PaymentRecord(id: $id, cash: $cash, date: $date, studentId: $studentId, paymentMethod: $paymentMethod)';
  }
}