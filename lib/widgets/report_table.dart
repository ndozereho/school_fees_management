import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/student.dart';
import '../utils/constants.dart';

class ReportTableWidget extends StatelessWidget {
  final List<Student> students;
  final String className;
  final bool showSchoolBadge;
  final bool showDateTime;

  const ReportTableWidget({
    super.key,
    required this.students,
    required this.className,
    this.showSchoolBadge = true,
    this.showDateTime = true,
  });

  // Helper: Calculate section totals
  Map<String, double> _calculateSectionTotals(List<Student> students) {
    double totalExpected = 0;
    double totalPaid = 0;
    double totalBalance = 0;
    double totalArrears = 0;
    double totalFeesStructure = 0;

    for (var student in students) {
      totalExpected += student.expectedFees;
      totalPaid += student.feesPaid;
      totalBalance += student.balance;
      totalArrears += student.arrears;
      totalFeesStructure += student.feesStructure;
    }

    return {
      'totalExpected': totalExpected,
      'totalPaid': totalPaid,
      'totalBalance': totalBalance,
      'totalArrears': totalArrears,
      'totalFeesStructure': totalFeesStructure,
      'studentCount': students.length.toDouble(),
    };
  }

  // Helper: Format currency
  String _formatCurrency(double amount) {
    final formatter = NumberFormat('#,###');
    return '${formatter.format(amount)} UGX';
  }

  // Helper: Generate financial summary
  Map<String, dynamic> _generateFinancialSummary(List<Student> students) {
    double totalExpected = 0;
    double totalPaid = 0;
    double totalBalance = 0;
    int fullyPaid = 0;
    int partiallyPaid = 0;
    int notPaid = 0;

    for (var student in students) {
      double expected = student.expectedFees;
      double paid = student.feesPaid;
      double balance = student.balance;

      totalExpected += expected;
      totalPaid += paid;
      totalBalance += balance;

      if (balance <= 0) {
        fullyPaid++;
      } else if (paid > 0) {
        partiallyPaid++;
      } else {
        notPaid++;
      }
    }

    return {
      'totalExpected': totalExpected,
      'totalPaid': totalPaid,
      'totalBalance': totalBalance,
      'totalStudents': students.length,
      'fullyPaid': fullyPaid,
      'partiallyPaid': partiallyPaid,
      'notPaid': notPaid,
      'collectionRate': totalExpected > 0 ? (totalPaid / totalExpected) * 100 : 0,
    };
  }

  @override
  Widget build(BuildContext context) {
    if (students.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.description, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No data available for report',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    // Sort students: Boarding first, then Day
    List<Student> sortedStudents = List.from(students);
    sortedStudents.sort((a, b) {
      int sectionCompare = a.sectionType.compareTo(b.sectionType);
      if (sectionCompare != 0) return sectionCompare;
      return a.ledgerNo.compareTo(b.ledgerNo);
    });

    final totals = _calculateSectionTotals(sortedStudents);

    return SingleChildScrollView(
      child: Column(
        children: [
          _buildReportHeader(context),
          const SizedBox(height: 20),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(Colors.indigo.shade50),
              headingRowHeight: 50,
              dataRowMinHeight: 50,
              dataRowMaxHeight: 70,
              horizontalMargin: 20,
              columnSpacing: 20,
              columns: const [
                DataColumn(
                  label: SizedBox(
                    width: 100,
                    child: Text('LEDGER No', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                  ),
                ),
                DataColumn(
                  label: SizedBox(
                    width: 150,
                    child: Text('PARENT CONTACT', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                  ),
                ),
                DataColumn(
                  label: SizedBox(
                    width: 100,
                    child: Text('REAM PAID', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                  ),
                ),
                DataColumn(
                  label: SizedBox(
                    width: 200,
                    child: Text('FULL NAME', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                  ),
                ),
                DataColumn(
                  label: SizedBox(
                    width: 150,
                    child: Text('EXPECTED INCOME', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                  ),
                ),
                DataColumn(
                  label: SizedBox(
                    width: 150,
                    child: Text('FEES PAID', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                  ),
                ),
                DataColumn(
                  label: SizedBox(
                    width: 150,
                    child: Text('BALANCE', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                  ),
                ),
              ],
              rows: [
                ..._buildStudentRowsWithSections(sortedStudents),
                DataRow(
                  color: WidgetStateProperty.all(Colors.indigo.shade100),
                  cells: [
                    const DataCell(Text('GRAND TOTAL', style: TextStyle(fontWeight: FontWeight.bold))),
                    const DataCell(Text('')),
                    const DataCell(Text('')),
                    DataCell(Text('Total Students: ${sortedStudents.length}', style: const TextStyle(fontWeight: FontWeight.bold))),
                    DataCell(Text(_formatCurrency(totals['totalExpected']!), style: const TextStyle(fontWeight: FontWeight.bold))),
                    DataCell(Text(_formatCurrency(totals['totalPaid']!), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green))),
                    DataCell(Text(
                      _formatCurrency(totals['totalBalance']!),
                      style: TextStyle(fontWeight: FontWeight.bold, color: totals['totalBalance']! > 0 ? Colors.red : Colors.green),
                    )),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _buildReportFooter(sortedStudents),
        ],
      ),
    );
  }

  Widget _buildReportHeader(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            if (showSchoolBadge) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.indigo, width: 2),
                      color: Colors.indigo.shade50,
                    ),
                    child: const Icon(Icons.school, size: 40, color: Colors.indigo),
                  ),
                  const SizedBox(width: 20),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(AppConstants.schoolName, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.indigo)),
                      Text(AppConstants.schoolMotto, style: TextStyle(fontSize: 14, color: Colors.grey, fontStyle: FontStyle.italic)),
                    ],
                  ),
                ],
              ),
              const Divider(height: 30),
            ],
            if (showDateTime) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Date: ${DateFormat('dd-MMM-yyyy').format(DateTime.now())}', style: const TextStyle(fontWeight: FontWeight.w500)),
                  Text('Time: ${DateFormat('HH:mm:ss').format(DateTime.now())}', style: const TextStyle(fontWeight: FontWeight.w500)),
                ],
              ),
              const SizedBox(height: 10),
            ],
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(color: Colors.indigo, borderRadius: BorderRadius.circular(8)),
              child: Text(
                'CLASS REPORT: $className',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<DataRow> _buildStudentRowsWithSections(List<Student> students) {
    List<DataRow> rows = [];
    String? currentSection;
    int sectionStudentCount = 0;
    double sectionExpectedTotal = 0;
    double sectionPaidTotal = 0;
    double sectionBalanceTotal = 0;

    for (int i = 0; i < students.length; i++) {
      var student = students[i];

      if (currentSection != student.sectionType) {
        if (currentSection != null && sectionStudentCount > 0) {
          rows.add(_buildSectionTotalRow('$currentSection SECTION TOTAL', sectionStudentCount, sectionExpectedTotal, sectionPaidTotal, sectionBalanceTotal));
        }
        rows.add(_buildSectionHeaderRow('${student.sectionType.toUpperCase()} SECTION'));
        currentSection = student.sectionType;
        sectionStudentCount = 0;
        sectionExpectedTotal = 0;
        sectionPaidTotal = 0;
        sectionBalanceTotal = 0;
      }

      rows.add(_buildStudentDataRow(student));
      sectionStudentCount++;
      sectionExpectedTotal += student.expectedFees;
      sectionPaidTotal += student.feesPaid;
      sectionBalanceTotal += student.balance;

      if (i == students.length - 1) {
        rows.add(_buildSectionTotalRow('$currentSection SECTION TOTAL', sectionStudentCount, sectionExpectedTotal, sectionPaidTotal, sectionBalanceTotal));
      }
    }

    return rows;
  }

  DataRow _buildSectionHeaderRow(String title) {
    return DataRow(
      color: WidgetStateProperty.all(Colors.grey.shade200),
      cells: [
        DataCell(Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, fontStyle: FontStyle.italic)),
        )),
        const DataCell(Text('')),
        const DataCell(Text('')),
        const DataCell(Text('')),
        const DataCell(Text('')),
        const DataCell(Text('')),
        const DataCell(Text('')),
      ],
    );
  }

  DataRow _buildSectionTotalRow(String title, int count, double expected, double paid, double balance) {
    return DataRow(
      color: WidgetStateProperty.all(Colors.blue.shade50),
      cells: [
        DataCell(Text(title, style: const TextStyle(fontWeight: FontWeight.bold))),
        const DataCell(Text('')),
        const DataCell(Text('')),
        DataCell(Text('Students: $count', style: const TextStyle(fontWeight: FontWeight.bold))),
        DataCell(Text(_formatCurrency(expected), style: const TextStyle(fontWeight: FontWeight.bold))),
        DataCell(Text(_formatCurrency(paid), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green))),
        DataCell(Text(_formatCurrency(balance), style: TextStyle(fontWeight: FontWeight.bold, color: balance > 0 ? Colors.red : Colors.green))),
      ],
    );
  }

  DataRow _buildStudentDataRow(Student student) {
    return DataRow(
      cells: [
        DataCell(Text(student.ledgerNo)),
        DataCell(Text(student.parentContact)),
        DataCell(Icon(student.reamPaid ? Icons.check_circle : Icons.cancel, color: student.reamPaid ? Colors.green : Colors.red, size: 20)),
        DataCell(Text(student.fullName)),
        DataCell(Text(_formatCurrency(student.expectedFees))),
        DataCell(Text(_formatCurrency(student.feesPaid), style: TextStyle(color: student.feesPaid > 0 ? Colors.green : Colors.grey))),
        DataCell(Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: student.balance > 0 ? Colors.red.shade50 : Colors.green.shade50,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: student.balance > 0 ? Colors.red : Colors.green),
          ),
          child: Text(_formatCurrency(student.balance), style: TextStyle(color: student.balance > 0 ? Colors.red : Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
        )),
      ],
    );
  }

  Widget _buildReportFooter(List<Student> students) {
    final summary = _generateFinancialSummary(students);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('FINANCIAL SUMMARY', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.indigo)),
            const Divider(),
            const SizedBox(height: 10),
            _buildSummaryRow('Total Students:', '${students.length}'),
            const SizedBox(height: 5),
            _buildSummaryRow('Fully Paid:', '${summary['fullyPaid']} students'),
            const SizedBox(height: 5),
            _buildSummaryRow('Partially Paid:', '${summary['partiallyPaid']} students'),
            const SizedBox(height: 5),
            _buildSummaryRow('Not Paid:', '${summary['notPaid']} students'),
            const SizedBox(height: 5),
            _buildSummaryRow('Collection Rate:', '${(summary['collectionRate'] as double).toStringAsFixed(1)}%'),
            const SizedBox(height: 15),
            const Divider(),
            const SizedBox(height: 10),
            _buildSummaryRow('Grand Total Expected:', _formatCurrency(summary['totalExpected'] as double)),
            const SizedBox(height: 5),
            _buildSummaryRow('Grand Total Paid:', _formatCurrency(summary['totalPaid'] as double)),
            const SizedBox(height: 5),
            _buildSummaryRow('Grand Total Balance:', _formatCurrency(summary['totalBalance'] as double),
                valueColor: (summary['totalBalance'] as double) > 0 ? Colors.red : Colors.green),
            const SizedBox(height: 20),
            Center(
              child: Text(
                'Report generated on ${DateFormat('dd-MMM-yyyy HH:mm:ss').format(DateTime.now())}',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontStyle: FontStyle.italic),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: valueColor)),
      ],
    );
  }
}

class ClassReportSelector extends StatelessWidget {
  final List<String> primaryClasses;
  final List<String> kgClasses;
  final void Function(String) onClassSelected;

  const ClassReportSelector({
    super.key,
    required this.primaryClasses,
    required this.kgClasses,
    required this.onClassSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Select Class for Report', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo)),
            const SizedBox(height: 20),
            const Text('PRIMARY SECTION', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: primaryClasses.map((className) => ElevatedButton(
                onPressed: () => onClassSelected(className),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
                child: Text(className),
              )).toList(),
            ),
            const SizedBox(height: 20),
            const Text('KINDERGARTEN SECTION', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: kgClasses.map((className) => ElevatedButton(
                onPressed: () => onClassSelected(className),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                child: Text(className),
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }
}