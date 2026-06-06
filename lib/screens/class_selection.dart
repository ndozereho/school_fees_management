import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/school_data_provider.dart';
import '../models/student.dart'; // ADD THIS IMPORT
import '../utils/constants.dart';
import 'class_screen.dart';

class ClassSelectionScreen extends StatefulWidget {
  final String sectionType;

  const ClassSelectionScreen({
    super.key,
    required this.sectionType,
  });

  @override
  State<ClassSelectionScreen> createState() => _ClassSelectionScreenState();
}

class _ClassSelectionScreenState extends State<ClassSelectionScreen>
    with SingleTickerProviderStateMixin {
  String _selectedTerm = 'ONE';
  String _selectedYear = '2026';
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  // Cache for class data
  Map<String, List<Student>> _classStudents = {};
  bool _isLoadingStats = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
    _loadInitialData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    await _loadCurrentTerm();
    await _loadClassData();
  }

  Future<void> _loadCurrentTerm() async {
    final provider = context.read<SchoolDataProvider>();
    
    String firstClass = widget.sectionType == 'Primary' ? 'P.7' : 'TOP CLASS';
    final termData = await provider.getClassTerm(firstClass, 'Boarding');
    
    if (mounted) {
      setState(() {
        _selectedTerm = termData['term'] ?? 'ONE';
        _selectedYear = termData['year'] ?? '2026';
      });
    }
  }

  Future<void> _loadClassData() async {
    final provider = context.read<SchoolDataProvider>();
    const primaryClasses = AppConstants.primaryClasses;
    const kgClasses = AppConstants.kindergartenClasses;
    final classes = widget.sectionType == 'Primary' ? primaryClasses : kgClasses;

    setState(() => _isLoadingStats = true);

    try {
      Map<String, List<Student>> classStudents = {};
      
      for (String className in classes) {
        List<Student> allStudents = [];
        final boardingStudents = provider.getStudentsByClass(className, 'Boarding');
        final dayStudents = provider.getStudentsByClass(className, 'Day');
        allStudents.addAll(boardingStudents);
        allStudents.addAll(dayStudents);
        classStudents[className] = allStudents;
      }
      
      if (mounted) {
        setState(() {
          _classStudents = classStudents;
          _isLoadingStats = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingStats = false);
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    const primaryClasses = AppConstants.primaryClasses;
    const kgClasses = AppConstants.kindergartenClasses;
    final classes = widget.sectionType == 'Primary' ? primaryClasses : kgClasses;
    final sectionColor = widget.sectionType == 'Primary' ? Colors.blue : Colors.green;
    final sectionIcon = widget.sectionType == 'Primary' ? Icons.school : Icons.child_care;
    final sectionTitle = widget.sectionType == 'Primary' 
        ? 'PRIMARY SECTION' 
        : 'KINDERGARTEN SECTION';

    return Scaffold(
      appBar: AppBar(
        title: Text(sectionTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Data',
            onPressed: () async {
              await context.read<SchoolDataProvider>().loadAllData();
              await _loadClassData();
            },
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'Section Info',
            onPressed: () => _showSectionInfo(),
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            _buildTermYearSelector(sectionColor),
            _buildQuickStatsBar(sectionColor),
            Expanded(
              child: Consumer<SchoolDataProvider>(
                builder: (context, provider, child) {
                  if (provider.isLoading || _isLoadingStats) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Loading classes...'),
                        ],
                      ),
                    );
                  }

                  if (provider.error != null) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, size: 48, color: Colors.red),
                          const SizedBox(height: 16),
                          Text(provider.error!, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => provider.loadAllData(),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () async {
                      await provider.loadAllData();
                      await _loadClassData();
                    },
                    child: GridView.builder(
                      padding: const EdgeInsets.all(20),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: _getCrossAxisCount(context),
                        crossAxisSpacing: 20,
                        mainAxisSpacing: 20,
                        childAspectRatio: 1.1,
                      ),
                      itemCount: classes.length,
                      itemBuilder: (context, index) {
                        final className = classes[index];
                        final students = _classStudents[className] ?? [];
                        return _buildClassCard(
                          className: className,
                          color: sectionColor,
                          icon: sectionIcon,
                          students: students,
                          index: index,
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _getCrossAxisCount(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    if (width > 1200) return 4;
    if (width > 800) return 3;
    if (width > 600) return 2;
    return 1;
  }

  Widget _buildTermYearSelector(Color sectionColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(25),
            offset: const Offset(0, 2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    sectionColor.withAlpha(25),
                    sectionColor.withAlpha(12),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(Icons.calendar_today, color: sectionColor),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Academic Term', style: TextStyle(fontSize: 11, color: Colors.grey)),
                        const SizedBox(height: 4),
                        DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedTerm,
                            isExpanded: true,
                            style: TextStyle(color: sectionColor, fontWeight: FontWeight.bold, fontSize: 16),
                            items: AppConstants.terms.map((String term) {
                              return DropdownMenuItem<String>(
                                value: term,
                                child: Text('Term $term'),
                              );
                            }).toList(),
                            onChanged: (String? newValue) async {
                              if (newValue != null) {
                                setState(() => _selectedTerm = newValue);
                                await _updateAllClassesTerm(newValue, _selectedYear);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    sectionColor.withAlpha(25),
                    sectionColor.withAlpha(12),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(Icons.date_range, color: sectionColor),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Year', style: TextStyle(fontSize: 11, color: Colors.grey)),
                        const SizedBox(height: 4),
                        TextField(
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                          style: TextStyle(color: sectionColor, fontWeight: FontWeight.bold, fontSize: 16),
                          controller: TextEditingController(text: _selectedYear),
                          onChanged: (value) async {
                            setState(() => _selectedYear = value);
                            await _updateAllClassesTerm(_selectedTerm, value);
                          },
                          keyboardType: TextInputType.number,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStatsBar(Color sectionColor) {
    int totalStudents = 0;
    double totalExpected = 0;
    double totalPaid = 0;
    
    for (var students in _classStudents.values) {
      for (var student in students) {
        totalStudents++;
        totalExpected += student.expectedFees;
        totalPaid += student.feesPaid;
      }
    }
    
    double collectionRate = totalExpected > 0 ? (totalPaid / totalExpected) * 100 : 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            sectionColor.withAlpha(230),
            sectionColor,
          ],
        ),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: sectionColor.withAlpha(77),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(icon: Icons.people, value: '$totalStudents', label: 'Students'),
          Container(width: 1, height: 40, color: Colors.white.withAlpha(77)),
          _buildStatItem(icon: Icons.school, value: '${_classStudents.length}', label: 'Classes'),
          Container(width: 1, height: 40, color: Colors.white.withAlpha(77)),
          _buildStatItem(icon: Icons.trending_up, value: '${collectionRate.toStringAsFixed(0)}%', label: 'Collection'),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(color: Colors.white.withAlpha(204), fontSize: 11)),
      ],
    );
  }

  Widget _buildClassCard({
    required String className,
    required Color color,
    required IconData icon,
    required List<Student> students,
    required int index,
  }) {
    int boardingCount = students.where((s) => s.sectionType == 'Boarding').length;
    int dayCount = students.where((s) => s.sectionType == 'Day').length;
    int totalCount = students.length;

    double totalExpected = 0;
    double totalPaid = 0;
    double totalBalance = 0;
    
    for (var student in students) {
      totalExpected += student.expectedFees;
      totalPaid += student.feesPaid;
      totalBalance += student.balance;
    }
    
    double collectionRate = totalExpected > 0 ? (totalPaid / totalExpected) * 100 : 0;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + (index * 100)),
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Opacity(opacity: value, child: child),
        );
      },
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ClassScreen(
                  className: className,
                  section: widget.sectionType,
                ),
              ),
            ).then((_) async {
              if (mounted) {
                final provider = context.read<SchoolDataProvider>();
                await provider.loadAllData();
                await _loadClassData();
              }
            });
          },
          borderRadius: BorderRadius.circular(15),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color.withAlpha(204),
                  color,
                ],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(51),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(icon, color: Colors.white, size: 28),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withAlpha(25), blurRadius: 4),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.people, size: 14, color: color),
                            const SizedBox(width: 4),
                            Text('$totalCount', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(className, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildSectionBadge('B', boardingCount, Colors.blue),
                          const SizedBox(width: 8),
                          _buildSectionBadge('D', dayCount, Colors.orange),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Collection', style: TextStyle(color: Colors.white.withAlpha(204), fontSize: 11)),
                              Text('${collectionRate.toStringAsFixed(0)}%', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Container(
                            height: 6,
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(77),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: collectionRate / 100,
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(colors: _getCollectionColors(collectionRate)),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (totalBalance > 0) ...[
                        const SizedBox(height: 8),
                        Text('Balance: UGX ${_formatAmount(totalBalance)}', style: const TextStyle(color: Colors.white, fontSize: 11)),
                      ],
                    ],
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(51),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('View Details', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
                          SizedBox(width: 4),
                          Icon(Icons.arrow_forward, color: Colors.white, size: 14),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionBadge(String label, int count, Color badgeColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(51),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 6, height: 6, decoration: BoxDecoration(color: badgeColor, shape: BoxShape.circle)),
          const SizedBox(width: 4),
          Text('$label: $count', style: const TextStyle(color: Colors.white, fontSize: 10)),
        ],
      ),
    );
  }

  List<Color> _getCollectionColors(double rate) {
    if (rate >= 80) return [Colors.green.shade400, Colors.green.shade600];
    if (rate >= 50) return [Colors.orange.shade400, Colors.orange.shade600];
    return [Colors.red.shade400, Colors.red.shade600];
  }

  Future<void> _updateAllClassesTerm(String term, String year) async {
    final provider = context.read<SchoolDataProvider>();
    const primaryClasses = AppConstants.primaryClasses;
    const kgClasses = AppConstants.kindergartenClasses;
    final classes = widget.sectionType == 'Primary' ? primaryClasses : kgClasses;

    for (String className in classes) {
      await provider.updateClassTerm(className, 'Boarding', term, year);
      await provider.updateClassTerm(className, 'Day', term, year);
    }
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Updated all classes to Term $term, $year'),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  void _showSectionInfo() {
    const primaryClasses = AppConstants.primaryClasses;
    const kgClasses = AppConstants.kindergartenClasses;
    final classes = widget.sectionType == 'Primary' ? primaryClasses : kgClasses;
    
    int totalStudents = 0;
    double totalExpected = 0;
    double totalPaid = 0;
    
    for (var students in _classStudents.values) {
      for (var student in students) {
        totalStudents++;
        totalExpected += student.expectedFees;
        totalPaid += student.feesPaid;
      }
    }
    
    double collectionRate = totalExpected > 0 ? (totalPaid / totalExpected) * 100 : 0;
    double balance = totalExpected - totalPaid;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              widget.sectionType == 'Primary' ? Icons.school : Icons.child_care,
              color: widget.sectionType == 'Primary' ? Colors.blue : Colors.green,
            ),
            const SizedBox(width: 10),
            Text(widget.sectionType == 'Primary' ? 'Primary Section' : 'Kindergarten Section'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Total Classes', '${classes.length}'),
            _buildInfoRow('Total Students', '$totalStudents'),
            _buildInfoRow('Academic Term', 'Term $_selectedTerm, $_selectedYear'),
            const Divider(),
            _buildInfoRow('Expected Fees', 'UGX ${_formatAmount(totalExpected)}'),
            _buildInfoRow('Fees Paid', 'UGX ${_formatAmount(totalPaid)}'),
            _buildInfoRow('Balance', 'UGX ${_formatAmount(balance)}'),
            _buildInfoRow('Collection Rate', '${collectionRate.toStringAsFixed(1)}%'),
            const Divider(),
            Text('Classes:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: classes.map((className) => Chip(
                label: Text(className, style: const TextStyle(fontSize: 12)),
                backgroundColor: widget.sectionType == 'Primary' ? Colors.blue.shade50 : Colors.green.shade50,
              )).toList(),
            ),
          ],
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

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  String _formatAmount(double amount) {
    final formatter = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    return amount.toStringAsFixed(0).replaceAllMapped(formatter, (Match m) => '${m[1]},');
  }
}