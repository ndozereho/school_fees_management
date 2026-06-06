import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/student.dart';
import '../models/payment_record.dart';
import '../providers/school_data_provider.dart';

class StudentTableWidget extends StatefulWidget {
  final List<Student> students;
  final String className;
  final String sectionType;
  final String term;
  final String year;
  final VoidCallback onDataChanged;

  const StudentTableWidget({
    super.key,
    required this.students,
    required this.className,
    required this.sectionType,
    required this.term,
    required this.year,
    required this.onDataChanged,
  });

  @override
  State<StudentTableWidget> createState() => _StudentTableWidgetState();
}

class _StudentTableWidgetState extends State<StudentTableWidget> {
  final ScrollController _horizontalScrollController = ScrollController();
  final ScrollController _verticalScrollController = ScrollController();

  @override
  void dispose() {
    _horizontalScrollController.dispose();
    _verticalScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.students.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No students in ${widget.sectionType} section',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: widget.onDataChanged,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
            ),
          ],
        ),
      );
    }

    return Scrollbar(
      controller: _verticalScrollController,
      thumbVisibility: true,
      child: SingleChildScrollView(
        controller: _verticalScrollController,
        scrollDirection: Axis.vertical,
        child: Scrollbar(
          controller: _horizontalScrollController,
          thumbVisibility: true,
          child: SingleChildScrollView(
            controller: _horizontalScrollController,
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(Colors.indigo.shade50),
              headingRowHeight: 50,
              dataRowMinHeight: 60,
              dataRowMaxHeight: 80,
              columnSpacing: 16,
              columns: const [
                DataColumn(label: Text('LEDGER No', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                DataColumn(label: Text('PARENT CONTACT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                DataColumn(label: Text("PUPIL'S NAME", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                DataColumn(label: Text('EXPECTED FEES', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                DataColumn(label: Text('FEES STRUCTURE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                DataColumn(label: Text('PAID FEES', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                DataColumn(label: Text('BALANCE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                DataColumn(label: Text('ARREARS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                DataColumn(label: Text('STATUS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                DataColumn(label: Text('ACTIONS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              ],
              rows: widget.students.map((student) {
                return DataRow(
                  cells: [
                    DataCell(Text(student.ledgerNo, style: const TextStyle(fontSize: 11))),
                    DataCell(Text(student.parentContact.isNotEmpty ? student.parentContact : 'N/A', style: const TextStyle(fontSize: 11))),
                    DataCell(Text(student.fullName, style: const TextStyle(fontSize: 11))),
                    DataCell(Text(student.formattedExpectedFees, style: const TextStyle(fontSize: 11))),
                    DataCell(Text(student.formattedFeesStructure, style: const TextStyle(fontSize: 11))),
                    DataCell(Text(student.formattedFeesPaid, style: TextStyle(fontSize: 11, color: student.feesPaid > 0 ? Colors.green : Colors.grey))),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: student.balance > 0 ? Colors.red.shade50 : Colors.green.shade50,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: student.balance > 0 ? Colors.red : Colors.green),
                        ),
                        child: Text(
                          student.formattedBalance,
                          style: TextStyle(
                            fontSize: 11,
                            color: student.balance > 0 ? Colors.red : Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    DataCell(Text(student.formattedArrears, style: TextStyle(fontSize: 11, color: student.arrears > 0 ? Colors.orange : Colors.grey))),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getStatusColor(student).withAlpha(25),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          student.paymentStatus,
                          style: TextStyle(
                            fontSize: 10,
                            color: _getStatusColor(student),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.payment, size: 18),
                            color: Colors.green,
                            onPressed: () => _showPaymentDialog(student),
                            tooltip: 'Add Payment',
                          ),
                          IconButton(
                            icon: const Icon(Icons.history, size: 18),
                            color: Colors.blue,
                            onPressed: () => _showPaymentHistory(student),
                            tooltip: 'Payment History',
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit, size: 18),
                            color: Colors.orange,
                            onPressed: () => _showEditStudentDialog(student),
                            tooltip: 'Edit Student',
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, size: 18),
                            color: Colors.red,
                            onPressed: () => _confirmDelete(student),
                            tooltip: 'Delete Student',
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(Student student) {
    if (student.isFullyPaid) return Colors.green;
    if (student.isPartiallyPaid) return Colors.orange;
    return Colors.red;
  }

  void _showPaymentDialog(Student student) async {
    final provider = Provider.of<SchoolDataProvider>(context, listen: false);
    final amountController = TextEditingController();
    DateTime selectedDate = DateTime.now();
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Add Payment - ${student.fullName}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Current Balance: ${student.formattedBalance}'),
              const SizedBox(height: 16),
              TextField(
                controller: amountController,
                decoration: const InputDecoration(
                  labelText: 'Amount (UGX)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.money),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                    helpText: 'Select Payment Date',
                    cancelText: 'Cancel',
                    confirmText: 'OK',
                  );
                  if (picked != null && picked != selectedDate) {
                    setDialogState(() {
                      selectedDate = picked;
                    });
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, color: Colors.indigo, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          DateFormat('dd-MMM-yyyy').format(selectedDate),
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                      const Icon(Icons.arrow_drop_down, color: Colors.grey),
                    ],
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final amount = double.tryParse(amountController.text);
                if (amount != null && amount > 0) {
                  try {
                    await provider.addPayment(
                      student,
                      amount,
                      selectedDate,
                      widget.className,
                      widget.sectionType,
                      widget.term,
                      widget.year,
                    );
                    if (context.mounted) {
                      Navigator.pop(context);
                      widget.onDataChanged();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Payment added successfully'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error adding payment: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a valid amount'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              },
              child: const Text('Add Payment'),
            ),
          ],
        ),
      ),
    );
  }

  void _showPaymentHistory(Student student) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Payment History - ${student.fullName}'),
        content: Container(
          width: double.maxFinite,
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.8,
            maxHeight: MediaQuery.of(context).size.height * 0.6,
          ),
          child: student.paymentRecords.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.receipt_long, size: 48, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(
                        'No payment records found',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.indigo.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildSummaryCard('Total Paid', student.formattedFeesPaid, Colors.green),
                          _buildSummaryCard('Balance', student.formattedBalance, student.balance > 0 ? Colors.red : Colors.green),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Payment Records',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: student.paymentRecords.length,
                        itemBuilder: (context, index) {
                          final payment = student.paymentRecords[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.green.shade100,
                                child: Icon(Icons.payment, size: 20, color: Colors.green.shade700),
                              ),
                              title: Text('UGX ${NumberFormat('#,###').format(payment.cash)}'),
                              subtitle: Text(DateFormat('dd-MMM-yyyy HH:mm').format(payment.date)),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                                onPressed: () => _deletePayment(student, payment),
                                tooltip: 'Delete Payment',
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(25),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  Future<void> _deletePayment(Student student, PaymentRecord payment) async {
    final provider = Provider.of<SchoolDataProvider>(context, listen: false);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Payment'),
        content: Text('Are you sure you want to delete this payment of UGX ${NumberFormat('#,###').format(payment.cash)}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await provider.deletePayment(student, payment);
                if (context.mounted) {
                  Navigator.pop(context);
                  Navigator.pop(context);
                  widget.onDataChanged();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Payment deleted successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error deleting payment: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showEditStudentDialog(Student student) async {
    final provider = Provider.of<SchoolDataProvider>(context, listen: false);
    final nameController = TextEditingController(text: student.fullName);
    final contactController = TextEditingController(text: student.parentContact);
    final feesController = TextEditingController(text: student.feesStructure.toString());
    final arrearsController = TextEditingController(text: student.arrears.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Student - ${student.ledgerNo}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: "PUPIL'S NAME *",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: contactController,
                decoration: const InputDecoration(
                  labelText: 'Parent Contact',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: feesController,
                decoration: const InputDecoration(
                  labelText: 'Fees Structure (UGX)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.money),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: arrearsController,
                decoration: const InputDecoration(
                  labelText: 'Arrears (UGX)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.money_off),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                final updatedStudent = student.copyWith(
                  fullName: nameController.text,
                  parentContact: contactController.text,
                  feesStructure: double.tryParse(feesController.text) ?? student.feesStructure,
                  arrears: double.tryParse(arrearsController.text) ?? student.arrears,
                );
                
                await provider.updateStudent(updatedStudent);
                
                if (context.mounted) {
                  Navigator.pop(context);
                  widget.onDataChanged();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Student updated successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              }
            },
            child: const Text('Save Changes'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(Student student) {
    final provider = Provider.of<SchoolDataProvider>(context, listen: false);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Student'),
        content: Text('Are you sure you want to delete ${student.fullName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await provider.deleteStudent(student);
                if (context.mounted) {
                  Navigator.pop(context);
                  widget.onDataChanged();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Student deleted successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error deleting student: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}