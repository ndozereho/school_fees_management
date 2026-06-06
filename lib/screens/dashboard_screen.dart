import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../providers/school_data_provider.dart';
import '../widgets/spotlight_search.dart';
import 'class_selection.dart';
import 'report_screen.dart';
import '../utils/constants.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    if (mounted) {
      context.read<SchoolDataProvider>().loadAllData();
    }
  }

  String _getReportFileName() {
    final now = DateTime.now();
    final date = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    final time = "${now.hour.toString().padLeft(2, '0')}-${now.minute.toString().padLeft(2, '0')}-${now.second.toString().padLeft(2, '0')}";
    return "GAPS_COMPREHENSIVE_REPORT_${date}_$time.pdf";
  }

  Future<pw.MemoryImage> _loadSchoolBadge() async {
    try {
      // Read the image file from assets
      final ByteData bytes = await rootBundle.load('assets/images/school_badge.jpg');
      return pw.MemoryImage(bytes.buffer.asUint8List());
    } catch (e) {
      debugPrint('Error loading school badge: $e');
      return pw.MemoryImage(Uint8List(0));
    }
  }

  Future<void> _exportPDF() async {
    if (!mounted) return;
    
    final provider = context.read<SchoolDataProvider>();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Generating Comprehensive PDF Report...'),
        duration: Duration(seconds: 1),
      ),
    );
    
    try {
      final pdf = pw.Document();
      
      // Load school badge image
      final badgeImage = await _loadSchoolBadge();
      
      // Collect all data for the report
      final allData = await _collectReportData(provider);
      
      // Add cover page with badge
      pdf.addPage(_buildCoverPage(allData, badgeImage));
      
      // Add executive summary page
      pdf.addPage(_buildExecutiveSummaryPage(allData));
      
      // Add class details pages (using landscape for better fit)
      pdf.addPage(_buildClassDetailsPage(allData, 'Primary'));
      pdf.addPage(_buildClassDetailsPage(allData, 'Kindergarten'));
      
      // Add financial summary page
      pdf.addPage(_buildFinancialSummaryPage(allData));
      
      // Add charts page
      pdf.addPage(_buildChartsPage(allData));
      
      // Use auto-generated filename
      final fileName = _getReportFileName();
      
      await Printing.sharePdf(
        bytes: await pdf.save(),
        filename: fileName,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✓ $fileName generated successfully!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      debugPrint('PDF Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating PDF: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<ReportData> _collectReportData(SchoolDataProvider provider) async {
    const primaryClasses = AppConstants.primaryClasses;
    const kgClasses = AppConstants.kindergartenClasses;
    
    ReportData data = ReportData();
    
    // Collect data for each class
    for (String className in [...primaryClasses, ...kgClasses]) {
      final boardingStudents = provider.getStudentsByClass(className, 'Boarding');
      final dayStudents = provider.getStudentsByClass(className, 'Day');
      final allClassStudents = [...boardingStudents, ...dayStudents];
      
      ClassReport classReport = ClassReport(
        className: className,
        boardingCount: boardingStudents.length,
        dayCount: dayStudents.length,
        totalStudents: allClassStudents.length,
        totalExpected: allClassStudents.fold(0.0, (sum, s) => sum + s.expectedFees),
        totalPaid: allClassStudents.fold(0.0, (sum, s) => sum + s.feesPaid),
        totalBalance: allClassStudents.fold(0.0, (sum, s) => sum + s.balance),
      );
      
      classReport.collectionRate = classReport.totalExpected > 0 
          ? (classReport.totalPaid / classReport.totalExpected) * 100 
          : 0;
      
      data.classReports.add(classReport);
      
      // Add to section totals
      if (primaryClasses.contains(className)) {
        data.primaryTotalExpected += classReport.totalExpected;
        data.primaryTotalPaid += classReport.totalPaid;
        data.primaryTotalBalance += classReport.totalBalance;
        data.primaryTotalStudents += classReport.totalStudents;
      } else {
        data.kindergartenTotalExpected += classReport.totalExpected;
        data.kindergartenTotalPaid += classReport.totalPaid;
        data.kindergartenTotalBalance += classReport.totalBalance;
        data.kindergartenTotalStudents += classReport.totalStudents;
      }
    }
    
    // Calculate overall totals
    data.grandTotalExpected = data.primaryTotalExpected + data.kindergartenTotalExpected;
    data.grandTotalPaid = data.primaryTotalPaid + data.kindergartenTotalPaid;
    data.grandTotalBalance = data.primaryTotalBalance + data.kindergartenTotalBalance;
    data.grandTotalStudents = data.primaryTotalStudents + data.kindergartenTotalStudents;
    
    data.primaryCollectionRate = data.primaryTotalExpected > 0 
        ? (data.primaryTotalPaid / data.primaryTotalExpected) * 100 
        : 0;
    
    data.kindergartenCollectionRate = data.kindergartenTotalExpected > 0 
        ? (data.kindergartenTotalPaid / data.kindergartenTotalExpected) * 100 
        : 0;
    
    data.grandCollectionRate = data.grandTotalExpected > 0 
        ? (data.grandTotalPaid / data.grandTotalExpected) * 100 
        : 0;
    
    return data;
  }

  pw.Page _buildCoverPage(ReportData data, pw.MemoryImage badgeImage) {
    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (pw.Context context) {
        return pw.Center(
          child: pw.Column(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              // School Badge
              if (badgeImage.bytes.isNotEmpty)
                pw.Container(
                  width: 120,
                  height: 120,
                  decoration: pw.BoxDecoration(
                    shape: pw.BoxShape.circle,
                    border: pw.Border.all(color: PdfColors.indigo, width: 2),
                  ),
                  child: pw.ClipOval(
                    child: pw.Image(badgeImage, fit: pw.BoxFit.cover),
                  ),
                ),
              pw.SizedBox(height: badgeImage.bytes.isNotEmpty ? 20 : 0),
              pw.Text(
                'GERTRUDE ACADEMY',
                style: pw.TextStyle(fontSize: 32, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo),
              ),
              pw.SizedBox(height: 10),
              pw.Text(
                'School Fees Management Report',
                style: const pw.TextStyle(fontSize: 20, color: PdfColors.grey700),
              ),
              pw.SizedBox(height: 40),
              pw.Divider(),
              pw.SizedBox(height: 40),
              pw.Text(
                'Comprehensive Financial Report',
                style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                'Generated: ${DateTime.now().toString().split(' ')[0]}',
                style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey500),
              ),
            ],
          ),
        );
      },
    );
  }

  pw.Page _buildExecutiveSummaryPage(ReportData data) {
    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (pw.Context context) {
        return pw.Padding(
          padding: const pw.EdgeInsets.all(30),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Executive Summary',
                style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo),
              ),
              pw.SizedBox(height: 20),
              pw.Divider(),
              pw.SizedBox(height: 20),
              
              // Grand Totals
              _buildSummaryCard('GRAND TOTAL COLLECTIONS', 
                  'UGX ${_formatNumber(data.grandTotalPaid)}', 
                  '${data.grandCollectionRate.toStringAsFixed(1)}%', 
                  PdfColors.green),
              pw.SizedBox(height: 20),
              
              // Section breakdown
              pw.Row(
                children: [
                  pw.Expanded(
                    child: _buildSectionSummary('Primary Section', 
                        'UGX ${_formatNumber(data.primaryTotalPaid)}',
                        '${data.primaryCollectionRate.toStringAsFixed(1)}%',
                        data.primaryTotalStudents,
                        PdfColors.blue),
                  ),
                  pw.SizedBox(width: 20),
                  pw.Expanded(
                    child: _buildSectionSummary('Kindergarten Section',
                        'UGX ${_formatNumber(data.kindergartenTotalPaid)}',
                        '${data.kindergartenCollectionRate.toStringAsFixed(1)}%',
                        data.kindergartenTotalStudents,
                        PdfColors.orange),
                  ),
                ],
              ),
              pw.SizedBox(height: 30),
              
              // Key Metrics
              pw.Text(
                'Key Metrics',
                style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 15),
              _buildMetricRow('Total Pupils', '${data.grandTotalStudents}'),
              _buildMetricRow('Total Expected Fees', 'UGX ${_formatNumber(data.grandTotalExpected)}'),
              _buildMetricRow('Total Fees Collected', 'UGX ${_formatNumber(data.grandTotalPaid)}'),
              _buildMetricRow('Outstanding Balance', 'UGX ${_formatNumber(data.grandTotalBalance)}'),
              _buildMetricRow('Overall Collection Rate', '${data.grandCollectionRate.toStringAsFixed(1)}%'),
            ],
          ),
        );
      },
    );
  }

  pw.Widget _buildSummaryCard(String title, String amount, String rate, PdfColor color) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: pw.BorderRadius.circular(10),
        border: pw.Border.all(color: color, width: 2),
      ),
      child: pw.Column(
        children: [
          pw.Text(title, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 10),
          pw.Text(amount, style: pw.TextStyle(fontSize: 28, fontWeight: pw.FontWeight.bold, color: color)),
          pw.SizedBox(height: 5),
          pw.Text('Collection Rate: $rate', style: const pw.TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  pw.Widget _buildSectionSummary(String title, String amount, String rate, int students, PdfColor color) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: color: color.withOpacity(0.1),
        borderRadius: pw.BorderRadius.circular(10),
      ),
      child: pw.Column(
        children: [
          pw.Text(title, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.Text('Pupils: $students', style: const pw.TextStyle(fontSize: 12)),
          pw.Text(amount, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: color)),
          pw.Text('Rate: $rate', style: const pw.TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  pw.Widget _buildMetricRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 5),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 12)),
          pw.Text(value, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }

  pw.Page _buildClassDetailsPage(ReportData data, String sectionType) {
    final classes = data.classReports.where((c) => 
      sectionType == 'Primary' 
          ? AppConstants.primaryClasses.contains(c.className)
          : AppConstants.kindergartenClasses.contains(c.className)
    ).toList();
    
    // Use landscape page format for better table fit
    final pageFormat = PdfPageFormat.a4.landscape;
    
    return pw.Page(
      pageFormat: pageFormat,
      build: (pw.Context context) {
        return pw.Padding(
          padding: const pw.EdgeInsets.all(15),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                '$sectionType Section - Class Details',
                style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo),
              ),
              pw.SizedBox(height: 15),
              pw.Divider(),
              pw.SizedBox(height: 15),
              
              pw.TableHelper.fromTextArray(
                headers: ['Class', 'Pupils', 'Board', 'Day', 'Expected (UGX)', 'Paid (UGX)', 'Balance (UGX)', 'Rate %'],
                data: [
                  ...classes.map((classReport) => [
                    classReport.className,
                    classReport.totalStudents.toString(),
                    classReport.boardingCount.toString(),
                    classReport.dayCount.toString(),
                    _formatNumber(classReport.totalExpected),
                    _formatNumber(classReport.totalPaid),
                    _formatNumber(classReport.totalBalance),
                    '${classReport.collectionRate.toStringAsFixed(1)}%',
                  ]),
                  [
                    'TOTAL',
                    classes.fold(0, (sum, c) => sum + c.totalStudents).toString(),
                    classes.fold(0, (sum, c) => sum + c.boardingCount).toString(),
                    classes.fold(0, (sum, c) => sum + c.dayCount).toString(),
                    _formatNumber(classes.fold(0.0, (sum, c) => sum + c.totalExpected)),
                    _formatNumber(classes.fold(0.0, (sum, c) => sum + c.totalPaid)),
                    _formatNumber(classes.fold(0.0, (sum, c) => sum + c.totalBalance)),
                    '${(sectionType == 'Primary' ? data.primaryCollectionRate : data.kindergartenCollectionRate).toStringAsFixed(1)}%',
                  ],
                ],
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold, 
                  fontSize: 9,
                ),
                cellStyle: const pw.TextStyle(fontSize: 8),
                cellAlignment: pw.Alignment.centerLeft,
                headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
              ),
            ],
          ),
        );
      },
    );
  }

  pw.Page _buildFinancialSummaryPage(ReportData data) {
    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (pw.Context context) {
        return pw.Padding(
          padding: const pw.EdgeInsets.all(30),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Financial Summary',
                style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo),
              ),
              pw.SizedBox(height: 20),
              pw.Divider(),
              pw.SizedBox(height: 20),
              
              pw.Text(
                'Collection Breakdown by Section',
                style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 15),
              
              // Primary Section with light blue background
              pw.Container(
                decoration: pw.BoxDecoration(
                  color: PdfColors.blue.withOpacity(0.1),
                  borderRadius: pw.BorderRadius.circular(10),
                ),
                child: _buildComparisonCard('Primary Section', 
                    data.primaryTotalPaid, 
                    data.primaryTotalExpected,
                    data.primaryCollectionRate,
                    PdfColors.blue),
              ),
              pw.SizedBox(height: 15),
              
              // Kindergarten Section with light orange background
              pw.Container(
                decoration: pw.BoxDecoration(
                  color: PdfColors.orange.withOpacity(0.1),
                  borderRadius: pw.BorderRadius.circular(10),
                ),
                child: _buildComparisonCard('Kindergarten Section',
                    data.kindergartenTotalPaid,
                    data.kindergartenTotalExpected,
                    data.kindergartenCollectionRate,
                    PdfColors.orange),
              ),
              pw.SizedBox(height: 20),
              
              pw.Divider(),
              pw.SizedBox(height: 20),
              
              // Grand Total with light green background
              pw.Container(
                decoration: pw.BoxDecoration(
                  color: PdfColors.green.withOpacity(0.15),
                  borderRadius: pw.BorderRadius.circular(10),
                  border: pw.Border.all(color: PdfColors.green, width: 1),
                ),
                child: _buildComparisonCard('GRAND TOTAL',
                    data.grandTotalPaid,
                    data.grandTotalExpected,
                    data.grandCollectionRate,
                    PdfColors.green),
              ),
            ],
          ),
        );
      },
    );
  }

  pw.Widget _buildComparisonCard(String title, double paid, double expected, double rate, PdfColor color) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      child: pw.Column(
        children: [
          pw.Text(title, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: color)),
          pw.SizedBox(height: 10),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
            children: [
              pw.Column(
                children: [
                  pw.Text('Expected', style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey600)),
                  pw.Text('UGX ${_formatNumber(expected)}', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                ],
              ),
              pw.Column(
                children: [
                  pw.Text('Collected', style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey600)),
                  pw.Text('UGX ${_formatNumber(paid)}', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: color)),
                ],
              ),
              pw.Column(
                children: [
                  pw.Text('Rate', style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey600)),
                  pw.Text('${rate.toStringAsFixed(1)}%', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: color)),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 10),
          pw.Container(
            height: 10,
            decoration: pw.BoxDecoration(
              color: PdfColors.grey200,
              borderRadius: pw.BorderRadius.circular(5),
            ),
            child: pw.Row(
              children: [
                pw.Container(
                  width: (rate / 100) * 400,
                  height: 10,
                  decoration: pw.BoxDecoration(
                    color: color,
                    borderRadius: pw.BorderRadius.circular(5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Page _buildChartsPage(ReportData data) {
    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (pw.Context context) {
        return pw.Padding(
          padding: const pw.EdgeInsets.all(30),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Visual Analytics',
                style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo),
              ),
              pw.SizedBox(height: 20),
              pw.Divider(),
              pw.SizedBox(height: 20),
              
              pw.Text(
                'Collection Rates by Class',
                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 15),
              
              // Bar chart simulation using containers
              pw.Column(
                children: data.classReports.map((classReport) {
                  return pw.Column(children: [
                    pw.Row(
                      children: [
                        pw.SizedBox(width: 60, child: pw.Text(classReport.className, style: const pw.TextStyle(fontSize: 10))),
                        pw.Expanded(
                          child: pw.Container(
                            height: 20,
                            decoration: pw.BoxDecoration(
                              color: PdfColors.grey200,
                              borderRadius: pw.BorderRadius.circular(3),
                            ),
                            child: pw.Row(
                              children: [
                                pw.Container(
                                  width: (classReport.collectionRate / 100) * 300,
                                  height: 20,
                                  decoration: pw.BoxDecoration(
                                    color: _getRateColor(classReport.collectionRate),
                                    borderRadius: pw.BorderRadius.circular(3),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        pw.SizedBox(width: 10),
                        pw.SizedBox(width: 40, child: pw.Text('${classReport.collectionRate.toStringAsFixed(0)}%', style: const pw.TextStyle(fontSize: 10))),
                      ],
                    ),
                    pw.SizedBox(height: 8),
                  ]);
                }).toList(),
              ),
              
              pw.SizedBox(height: 30),
              pw.Divider(),
              pw.SizedBox(height: 20),
              
              pw.Text(
                'Pupil Distribution',
                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 15),
              pw.Row(
                children: [
                  pw.Expanded(
                    child: _buildPieChartSegment('Primary', data.primaryTotalStudents, data.grandTotalStudents, PdfColors.blue),
                  ),
                  pw.SizedBox(width: 20),
                  pw.Expanded(
                    child: _buildPieChartSegment('Kindergarten', data.kindergartenTotalStudents, data.grandTotalStudents, PdfColors.orange),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  pw.Widget _buildPieChartSegment(String label, int value, int total, PdfColor color) {
    double percentage = total > 0 ? (value / total) * 100 : 0;
    return pw.Column(
      children: [
        pw.Container(
          width: 100,
          height: 100,
          decoration: pw.BoxDecoration(
            shape: pw.BoxShape.circle,
            color: color.withOpacity(0.2),
            border: pw.Border.all(color: color, width: 3),
          ),
          child: pw.Center(
            child: pw.Text('${percentage.toStringAsFixed(0)}%', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Text(label, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
        pw.Text('$value pupils', style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey600)),
      ],
    );
  }

  PdfColor _getRateColor(double rate) {
    if (rate >= 80) return PdfColors.green;
    if (rate >= 50) return PdfColors.orange;
    return PdfColors.red;
  }

  String _formatNumber(double number) {
    return number.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('School Fees Management'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<SchoolDataProvider>().loadAllData();
            },
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: _exportPDF,
            tooltip: 'Export Comprehensive Report',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/');
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // School Header
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.indigo, width: 2),
                        color: Colors.indigo.shade50,
                      ),
                      child: const Icon(
                        Icons.school,
                        size: 40,
                        color: Colors.indigo,
                      ),
                    ),
                    const SizedBox(width: 20),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'GERTRUDE ACADEMY',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.indigo,
                            ),
                          ),
                          Text(
                            'School Fees Management System',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            const SpotlightSearchWidget(),
            const SizedBox(height: 30),
            
            Consumer<SchoolDataProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                return Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Total Pupils',
                        '${provider.totalStudentCount}',
                        Icons.people,
                        Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildStatCard(
                        'Primary',
                        '${provider.primaryStudentCount}',
                        Icons.school,
                        Colors.green,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildStatCard(
                        'Kindergarten',
                        '${provider.kindergartenStudentCount}',
                        Icons.child_care,
                        Colors.orange,
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 30),
            
            Consumer<SchoolDataProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) return const SizedBox.shrink();
                
                return Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Boarding',
                        '${provider.boardingStudentCount}',
                        Icons.hotel,
                        Colors.indigo,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildStatCard(
                        'Day',
                        '${provider.dayStudentCount}',
                        Icons.wb_sunny,
                        Colors.orange,
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 30),
            
            Center(
              child: ElevatedButton.icon(
                onPressed: _exportPDF,
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text('Generate Comprehensive Report'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                  textStyle: const TextStyle(fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 30),
            
            const Text(
              'SECTIONS',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.indigo,
              ),
            ),
            const SizedBox(height: 15),
            
            _buildSectionCard(
              'PRIMARY SECTION',
              'P.1 - P.7 Classes',
              Icons.school,
              Colors.blue,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ClassSelectionScreen(
                      sectionType: 'Primary',
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 15),
            
            _buildSectionCard(
              'KINDERGARTEN SECTION',
              'Baby, Middle & Top Classes',
              Icons.child_care,
              Colors.green,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ClassSelectionScreen(
                      sectionType: 'Kindergarten',
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 15),
            
            _buildSectionCard(
              'REPORT SECTION',
              'Generate & Print Reports',
              Icons.assessment,
              Colors.orange,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ReportScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard(String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color ,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 30),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}

// Data models for report
class ClassReport {
  final String className;
  final int boardingCount;
  final int dayCount;
  final int totalStudents;
  final double totalExpected;
  final double totalPaid;
  final double totalBalance;
  double collectionRate;
  
  ClassReport({
    required this.className,
    required this.boardingCount,
    required this.dayCount,
    required this.totalStudents,
    required this.totalExpected,
    required this.totalPaid,
    required this.totalBalance,
    this.collectionRate = 0,
  });
}

class ReportData {
  List<ClassReport> classReports = [];
  
  double primaryTotalExpected = 0;
  double primaryTotalPaid = 0;
  double primaryTotalBalance = 0;
  int primaryTotalStudents = 0;
  double primaryCollectionRate = 0;
  
  double kindergartenTotalExpected = 0;
  double kindergartenTotalPaid = 0;
  double kindergartenTotalBalance = 0;
  int kindergartenTotalStudents = 0;
  double kindergartenCollectionRate = 0;
  
  double grandTotalExpected = 0;
  double grandTotalPaid = 0;
  double grandTotalBalance = 0;
  int grandTotalStudents = 0;
  double grandCollectionRate = 0;
}
