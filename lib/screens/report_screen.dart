import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/student.dart';
import '../providers/school_data_provider.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});
  
  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  String selectedClass = 'P.7';
  List<Student> allStudents = [];
  bool isLoading = false;
  double totalExpectedFees = 0;
  double totalFeesPaid = 0;
  double totalBalance = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => loadClassData());
  }

  Future<void> loadClassData() async {
    if (!mounted) return;
    setState(() => isLoading = true);
    try {
      final provider = context.read<SchoolDataProvider>();
      await provider.loadAllData();
      if (!mounted) return;
      List<Student> list = [];
      list.addAll(provider.getStudentsByClass(selectedClass, 'Boarding'));
      list.addAll(provider.getStudentsByClass(selectedClass, 'Day'));
      list.sort((a, b) {
        int c = a.sectionType.compareTo(b.sectionType);
        return c != 0 ? c : a.ledgerNo.compareTo(b.ledgerNo);
      });
      double te = 0, tp = 0, tb = 0;
      for (var s in list) { te += s.expectedFees; tp += s.feesPaid; tb += s.balance; }
      if (mounted) setState(() { allStudents = list; totalExpectedFees = te; totalFeesPaid = tp; totalBalance = tb; isLoading = false; });
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<pw.MemoryImage> _loadSchoolBadge() async {
    try {
      final ByteData bytes = await rootBundle.load('assets/images/school_badge.jpg');
      return pw.MemoryImage(bytes.buffer.asUint8List());
    } catch (e) {
      debugPrint('Error loading school badge: $e');
      return pw.MemoryImage(Uint8List(0));
    }
  }

  Future<void> exportClassReport() async {
    if (allStudents.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No data to export'), backgroundColor: Colors.red)
        );
      }
      return;
    }
    
    if (mounted) {
      showDialog(
        context: context, 
        barrierDismissible: false, 
        builder: (c) => const Center(child: CircularProgressIndicator())
      );
    }
    
    try {
      final pdfData = await generateClassPdf();
      if (mounted && Navigator.of(context).canPop()) Navigator.of(context).pop();
      if (pdfData.isNotEmpty) {
        final fileName = "${selectedClass.replaceAll(' ', '_')}_REPORT_${DateFormat('dd-MMM-yyyy').format(DateTime.now())}.pdf";
        await Printing.sharePdf(bytes: pdfData, filename: fileName);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('✓ $fileName exported successfully!'), backgroundColor: Colors.green)
          );
        }
      }
    } catch (e) {
      if (mounted && Navigator.of(context).canPop()) Navigator.of(context).pop();
      if (mounted) {
        String msg = e.toString();
        if (msg.length > 80) msg = '${msg.substring(0, 80)}...';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export error: $msg'), backgroundColor: Colors.orange)
        );
      }
    }
  }

  Future<Uint8List> generateClassPdf() async {
    try {
      final pdf = pw.Document();
      final now = DateTime.now();
      final badgeImage = await _loadSchoolBadge();
      
      // Get term info
      String termInfo = allStudents.isNotEmpty ? allStudents.first.term : "ONE";
      String yearInfo = allStudents.isNotEmpty ? allStudents.first.year : "2026";
      String title = "$selectedClass - TERM $termInfo $yearInfo";
      
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.all(20),
          build: (pw.Context context) {
            return pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.start,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // School Header with Badge
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [
                    if (badgeImage.bytes.isNotEmpty)
                      pw.Container(
                        width: 60,
                        height: 60,
                        decoration: pw.BoxDecoration(
                          shape: pw.BoxShape.circle,
                          border: pw.Border.all(color: PdfColors.indigo, width: 2),
                        ),
                        child: pw.ClipOval(
                          child: pw.Image(badgeImage, fit: pw.BoxFit.cover),
                        ),
                      ),
                    pw.SizedBox(width: 15),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'GERTRUDE ACADEMY',
                          style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo),
                        ),
                        pw.Text(
                          'Struggle For The Highest',
                          style: pw.TextStyle(fontSize: 10, fontStyle: pw.FontStyle.italic, color: PdfColors.grey700),
                        ),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 10),
                pw.Divider(),
                pw.SizedBox(height: 5),
                
                // Class Title and Date
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      title,
                      style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo),
                    ),
                    pw.Text(
                      DateFormat('dd-MMM-yyyy').format(now),
                      style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey),
                    ),
                  ],
                ),
                pw.SizedBox(height: 15),
                
                // Student Details Table
                _buildStudentTable(allStudents),
                
                pw.SizedBox(height: 15),
                
                // Totals Section
                _buildTotalsSection(),
                
                pw.SizedBox(height: 20),
                
                // Disclaimer with Page Number on the extreme right
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Expanded(
                      child: pw.Container(
                        padding: const pw.EdgeInsets.all(10),
                        decoration: pw.BoxDecoration(
                          color: PdfColors.grey100,
                          borderRadius: pw.BorderRadius.circular(5),
                        ),
                        child: pw.Text(
                          'DISCLAIMER: This is a system generated class report. If you have any form of inquiry, please visit Bursar\'s Office for assistance. Thank You.',
                          style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                    ),
                    pw.SizedBox(width: 10),
                    pw.Container(
                      padding: const pw.EdgeInsets.all(10),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.grey100,
                        borderRadius: pw.BorderRadius.circular(5),
                      ),
                      child: pw.Text(
                        'Page 1 of 1',
                        style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                
                pw.SizedBox(height: 15),
                pw.Divider(),
                pw.SizedBox(height: 10),
                
                // Footer - Timestamp only
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.end,
                  children: [
                    pw.Text(
                      'Generated: ${DateFormat('dd-MMM-yyyy HH:mm:ss').format(now)}',
                      style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      );
      
      return await pdf.save();
    } catch (e, stack) {
      debugPrint('PDF Generation Error: $e');
      debugPrint('Stack: $stack');
      rethrow;
    }
  }

  pw.Widget _buildStudentTable(List<Student> students) {
    final boardingStudents = students.where((s) => s.sectionType == 'Boarding').toList();
    final dayStudents = students.where((s) => s.sectionType == 'Day').toList();
    
    List<pw.Widget> tableContent = [];
    
    // Boarding Section
    if (boardingStudents.isNotEmpty) {
      tableContent.add(
        pw.Container(
          padding: const pw.EdgeInsets.all(8),
          color: PdfColors.blue100,
          child: pw.Text(
            'BOARDING SECTION',
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.blue),
          ),
        ),
      );
      tableContent.add(pw.SizedBox(height: 5));
      tableContent.add(_buildDataTable(boardingStudents));
      tableContent.add(pw.SizedBox(height: 10));
      tableContent.add(_buildSubtotal(boardingStudents, 'Boarding Subtotal'));
      tableContent.add(pw.SizedBox(height: 15));
    }
    
    // Day Section
    if (dayStudents.isNotEmpty) {
      tableContent.add(
        pw.Container(
          padding: const pw.EdgeInsets.all(8),
          color: PdfColors.green100,
          child: pw.Text(
            'DAY SECTION',
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.green),
          ),
        ),
      );
      tableContent.add(pw.SizedBox(height: 5));
      tableContent.add(_buildDataTable(dayStudents));
      tableContent.add(pw.SizedBox(height: 10));
      tableContent.add(_buildSubtotal(dayStudents, 'Day Subtotal'));
      tableContent.add(pw.SizedBox(height: 15));
    }
    
    return pw.Column(children: tableContent);
  }

  pw.Widget _buildDataTable(List<Student> students) {
    // Column order: LEDGER No, CONTACT, PUPIL, EXPECTED FEES, PAID FEES, BALANCE, COMMENT
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(0.8),  // LEDGER No
        1: const pw.FlexColumnWidth(1),    // PARENT CONTACT
        2: const pw.FlexColumnWidth(1.2),  // PUPIL
        3: const pw.FlexColumnWidth(1),    // EXPECTED FEES
        4: const pw.FlexColumnWidth(1),    // PAID FEES
        5: const pw.FlexColumnWidth(1),    // BALANCE
        6: const pw.FlexColumnWidth(1),    // COMMENT
      },
      children: [
        // Header Row
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            _buildHeaderCell('LEDGER No'),
            _buildHeaderCell('PARENT CONTACT'),
            _buildHeaderCell('PUPIL'),
            _buildHeaderCell('EXPECTED FEES'),
            _buildHeaderCell('PAID FEES'),
            _buildHeaderCell('BALANCE'),
            _buildHeaderCell('COMMENT'),
          ],
        ),
        // Data Rows
        ...students.map((student) => pw.TableRow(
          children: [
            _buildDataCell(student.ledgerNo),
            _buildDataCell(student.parentContact.isNotEmpty ? student.parentContact : 'N/A'),
            _buildDataCell(student.fullName),
            _buildDataCell('UGX ${NumberFormat('#,###').format(student.expectedFees)}', textAlign: pw.TextAlign.right),
            _buildDataCell('UGX ${NumberFormat('#,###').format(student.feesPaid)}', 
                textAlign: pw.TextAlign.right, 
                color: student.feesPaid > 0 ? PdfColors.green : null),
            _buildDataCell('UGX ${NumberFormat('#,###').format(student.balance)}', 
                textAlign: pw.TextAlign.right, 
                color: student.balance > 0 ? PdfColors.red : PdfColors.green),
            _buildDataCell(student.balance > 0 ? 'Balance Due' : 'Fully Paid'),
          ],
        )),
      ],
    );
  }

  pw.Widget _buildHeaderCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  pw.Widget _buildDataCell(String text, {pw.TextAlign textAlign = pw.TextAlign.left, PdfColor? color}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(fontSize: 8, color: color ?? PdfColors.black),
        textAlign: textAlign,
      ),
    );
  }

  pw.Widget _buildSubtotal(List<Student> students, String title) {
    double totalExpected = students.fold(0.0, (sum, s) => sum + s.expectedFees);
    double totalPaid = students.fold(0.0, (sum, s) => sum + s.feesPaid);
    double totalBalance = students.fold(0.0, (sum, s) => sum + s.balance);
    
    // Create a table row that aligns with the column structure - all text bold
    // Column order: LEDGER No, CONTACT, PUPIL, EXPECTED, PAID, BALANCE, COMMENT
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(0.8),
        1: const pw.FlexColumnWidth(1),
        2: const pw.FlexColumnWidth(1.2),
        3: const pw.FlexColumnWidth(1),
        4: const pw.FlexColumnWidth(1),
        5: const pw.FlexColumnWidth(1),
        6: const pw.FlexColumnWidth(1),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey100),
          children: [
            _buildSubtotalCell(title, isFirst: true, isBold: true),
            _buildSubtotalCell('', isBold: true),
            _buildSubtotalCell('', isBold: true),
            _buildSubtotalCell('UGX ${NumberFormat('#,###').format(totalExpected)}', 
                textAlign: pw.TextAlign.right, 
                color: PdfColors.black,
                isBold: true),
            _buildSubtotalCell('UGX ${NumberFormat('#,###').format(totalPaid)}', 
                textAlign: pw.TextAlign.right, 
                color: PdfColors.green,
                isBold: true),
            _buildSubtotalCell('UGX ${NumberFormat('#,###').format(totalBalance)}', 
                textAlign: pw.TextAlign.right, 
                color: totalBalance > 0 ? PdfColors.red : PdfColors.green,
                isBold: true),
            _buildSubtotalCell('', isBold: true),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildSubtotalCell(String text, {pw.TextAlign textAlign = pw.TextAlign.left, PdfColor? color, bool isFirst = false, bool isBold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 9, 
          fontWeight: isBold ? pw.FontWeight.bold : (isFirst ? pw.FontWeight.bold : pw.FontWeight.normal),
          color: color ?? PdfColors.black
        ),
        textAlign: textAlign,
      ),
    );
  }

  pw.Widget _buildTotalsSection() {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.indigo100,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColors.indigo, width: 1),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Expanded(
            flex: 1,
            child: pw.Text(
              'GRAND TOTALS',
              style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Expanded(
            flex: 1,
            child: pw.Text(
              'Total Pupils: ${allStudents.length}',
              style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Expanded(
            flex: 1,
            child: pw.Text(
              'Expected: UGX ${NumberFormat('#,###').format(totalExpectedFees)}',
              style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
              textAlign: pw.TextAlign.right,
            ),
          ),
          pw.Expanded(
            flex: 1,
            child: pw.Text(
              'Paid: UGX ${NumberFormat('#,###').format(totalFeesPaid)}',
              style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.green),
              textAlign: pw.TextAlign.right,
            ),
          ),
          pw.Expanded(
            flex: 1,
            child: pw.Text(
              'Balance: UGX ${NumberFormat('#,###').format(totalBalance)}',
              style: pw.TextStyle(
                fontSize: 11, 
                fontWeight: pw.FontWeight.bold, 
                color: totalBalance > 0 ? PdfColors.red : PdfColors.green
              ),
              textAlign: pw.TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const allClasses = ['P.7', 'P.6', 'P.5', 'P.4', 'P.3', 'P.2', 'P.1', 'TOP CLASS', 'MIDDLE CLASS', 'BABY CLASS'];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Class Report'), 
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf), 
            tooltip: 'Export Class Report', 
            onPressed: exportClassReport,
          ),
          IconButton(
            icon: const Icon(Icons.refresh), 
            onPressed: () => loadClassData(),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16), 
            child: DropdownButtonFormField<String>(
              initialValue: selectedClass,
              decoration: const InputDecoration(
                labelText: 'Select Class', 
                border: OutlineInputBorder(), 
                prefixIcon: Icon(Icons.class_)
              ), 
              items: allClasses.map((c) => DropdownMenuItem<String>(value: c, child: Text(c))).toList(), 
              onChanged: (v) async { 
                if (v != null) { 
                  setState(() => selectedClass = v); 
                  await loadClassData(); 
                } 
              }
            ),
          ),
          Expanded(
            child: isLoading 
              ? const Center(child: CircularProgressIndicator()) 
              : allStudents.isEmpty 
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center, 
                      children: [
                        Icon(Icons.people_outline, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16), 
                        Text('No students in $selectedClass', style: TextStyle(fontSize: 16, color: Colors.grey.shade600))
                      ]
                    )
                  ) 
                : buildContent(),
          ),
        ],
      ),
    );
  }

  Widget buildContent() => SingleChildScrollView(
    padding: const EdgeInsets.all(16), 
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start, 
      children: [
        Container(
          padding: const EdgeInsets.all(16), 
          decoration: BoxDecoration(
            color: Colors.indigo, 
            borderRadius: BorderRadius.circular(8)
          ), 
          child: Row(
            children: [
              const Icon(Icons.assessment, color: Colors.white, size: 30),
              const SizedBox(width: 12), 
              Expanded(
                child: Text(
                  'CLASS REPORT: $selectedClass', 
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)
                )
              ), 
              Text(
                DateFormat('dd-MMM-yyyy').format(DateTime.now()), 
                style: const TextStyle(color: Colors.white70, fontSize: 12)
              )
            ]
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: uiCard('Pupils', '${allStudents.length}', Icons.people, Colors.blue)),
            const SizedBox(width: 8), 
            Expanded(child: uiCard('Expected', '${NumberFormat('#,###').format(totalExpectedFees)} UGX', Icons.monetization_on, Colors.orange)),
            const SizedBox(width: 8), 
            Expanded(child: uiCard('Paid', '${NumberFormat('#,###').format(totalFeesPaid)} UGX', Icons.check_circle, Colors.green)),
            const SizedBox(width: 8), 
            Expanded(child: uiCard('Balance', '${NumberFormat('#,###').format(totalBalance)} UGX', Icons.warning, totalBalance > 0 ? Colors.red : Colors.green)),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity, 
          child: ElevatedButton.icon(
            icon: const Icon(Icons.picture_as_pdf), 
            label: const Text('Export Class Report'), 
            onPressed: exportClassReport, 
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo, 
              foregroundColor: Colors.white, 
              padding: const EdgeInsets.symmetric(vertical: 12)
            )
          ),
        ),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal, 
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(Colors.indigo.shade50),
            headingRowHeight: 45, 
            dataRowMinHeight: 45, 
            dataRowMaxHeight: 55, 
            columnSpacing: 16, 
            columns: const [
              DataColumn(label: Text('LEDGER No', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              DataColumn(label: Text('CONTACT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              DataColumn(label: Text('PUPIL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              DataColumn(label: Text('EXPECTED', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              DataColumn(label: Text('PAID', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              DataColumn(label: Text('BALANCE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              DataColumn(label: Text('COMMENT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
            ], 
            rows: [
              if (allStudents.any((s) => s.sectionType == 'Boarding')) 
                DataRow(
                  color: WidgetStateProperty.all(Colors.grey.shade200), 
                  cells: [
                    DataCell(Text('BOARDING', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.blue.shade700))),
                    const DataCell(Text('')),
                    const DataCell(Text('')),
                    const DataCell(Text('')),
                    const DataCell(Text('')),
                    const DataCell(Text('')),
                    const DataCell(Text('')),
                  ]
                ),
              ...allStudents.where((s) => s.sectionType == 'Boarding').map((s) => uiRow(s)),
              if (allStudents.any((s) => s.sectionType == 'Boarding')) 
                uiSubtotal('Boarding', allStudents.where((s) => s.sectionType == 'Boarding').toList()),
              if (allStudents.any((s) => s.sectionType == 'Day')) 
                DataRow(
                  color: WidgetStateProperty.all(Colors.grey.shade200), 
                  cells: [
                    DataCell(Text('DAY', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.green.shade700))),
                    const DataCell(Text('')),
                    const DataCell(Text('')),
                    const DataCell(Text('')),
                    const DataCell(Text('')),
                    const DataCell(Text('')),
                    const DataCell(Text('')),
                  ]
                ),
              ...allStudents.where((s) => s.sectionType == 'Day').map((s) => uiRow(s)),
              if (allStudents.any((s) => s.sectionType == 'Day')) 
                uiSubtotal('Day', allStudents.where((s) => s.sectionType == 'Day').toList()),
              DataRow(
                color: WidgetStateProperty.all(Colors.indigo.shade100), 
                cells: [
                  const DataCell(Text('GRAND TOTAL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  const DataCell(Text('')),
                  DataCell(Text('${allStudents.length}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  DataCell(Text('UGX ${NumberFormat('#,###').format(totalExpectedFees)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  DataCell(Text('UGX ${NumberFormat('#,###').format(totalFeesPaid)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.green))),
                  DataCell(Text('UGX ${NumberFormat('#,###').format(totalBalance)}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: totalBalance > 0 ? Colors.red : Colors.green))),
                  const DataCell(Text('')),
                ]
              ),
            ]
          ),
        ),
      ],
    ),
  );

  DataRow uiRow(Student s) => DataRow(cells: [
    DataCell(Text(s.ledgerNo, style: const TextStyle(fontSize: 11))),
    DataCell(Text(s.parentContact.isNotEmpty ? s.parentContact : 'N/A', style: const TextStyle(fontSize: 11))),
    DataCell(Text(s.fullName, style: const TextStyle(fontSize: 11))),
    DataCell(Text(s.formattedExpectedFees, style: const TextStyle(fontSize: 11))),
    DataCell(Text(s.formattedFeesPaid, style: TextStyle(fontSize: 11, color: s.feesPaid > 0 ? Colors.green : Colors.grey))),
    DataCell(Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), 
      decoration: BoxDecoration(
        color: s.balance > 0 ? Colors.red.shade50 : Colors.green.shade50, 
        borderRadius: BorderRadius.circular(4), 
        border: Border.all(color: s.balance > 0 ? Colors.red : Colors.green)
      ), 
      child: Text(s.formattedBalance, style: TextStyle(fontSize: 11, color: s.balance > 0 ? Colors.red : Colors.green, fontWeight: FontWeight.bold))
    )),
    DataCell(Text(s.balance > 0 ? 'Balance Due' : 'Fully Paid', style: TextStyle(fontSize: 10, color: s.balance > 0 ? Colors.red : Colors.green, fontWeight: FontWeight.bold))),
  ]);

  DataRow uiSubtotal(String label, List<Student> st) {
    double e = 0, p = 0, b = 0;
    for (var s in st) { e += s.expectedFees; p += s.feesPaid; b += s.balance; }
    return DataRow(
      color: WidgetStateProperty.all(Colors.blue.shade50), 
      cells: [
        DataCell(Text('$label Subtotal', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
        const DataCell(Text('')),
        DataCell(Text('${st.length}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
        DataCell(Text('UGX ${NumberFormat('#,###').format(e)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
        DataCell(Text('UGX ${NumberFormat('#,###').format(p)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.green))),
        DataCell(Text('UGX ${NumberFormat('#,###').format(b)}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: b > 0 ? Colors.red : Colors.green))),
        const DataCell(Text('')),
      ]
    );
  }

  Widget uiCard(String title, String value, IconData icon, Color color) => Card(
    elevation: 2, 
    child: Padding(
      padding: const EdgeInsets.all(8), 
      child: Column(
        children: [
          Icon(icon, color: color, size: 20), 
          const SizedBox(height: 4), 
          Text(value, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color), textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis), 
          const SizedBox(height: 2), 
          Text(title, style: const TextStyle(fontSize: 9, color: Colors.grey), textAlign: TextAlign.center)
        ]
      )
    )
  );
}