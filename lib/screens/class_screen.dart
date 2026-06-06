import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/school_data_provider.dart';
import '../models/student.dart';
import '../widgets/student_table.dart';

class ClassScreen extends StatefulWidget {
  final String className;
  final String section;

  const ClassScreen({
    super.key,
    required this.className,
    required this.section,
  });

  @override
  State<ClassScreen> createState() => _ClassScreenState();
}

class _ClassScreenState extends State<ClassScreen> {
  String _term = 'ONE';
  String _year = '2026';
  List<Student> _boardingStudents = [];
  List<Student> _dayStudents = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    
    setState(() => _isLoading = true);
    
    try {
      // Capture provider synchronously before any await
      final provider = context.read<SchoolDataProvider>();
      
      // Load term and year (this is async)
      final termData = await provider.getClassTerm(widget.className, 'Boarding');
      
      // Load students (these are synchronous getters, not Futures)
      final boardingStudents = provider.getStudentsByClass(widget.className, 'Boarding');
      final dayStudents = provider.getStudentsByClass(widget.className, 'Day');
      
      if (!mounted) return;
      
      setState(() {
        _term = termData['term'] ?? 'ONE';
        _year = termData['year'] ?? '2026';
        _boardingStudents = boardingStudents;
        _dayStudents = dayStudents;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  void _updateTerm(String newTerm) {
    if (!mounted) return;
    setState(() => _term = newTerm);
    
    // Capture provider synchronously
    final provider = context.read<SchoolDataProvider>();
    provider.updateClassTerm(
      widget.className,
      'Boarding',
      newTerm,
      _year,
    );
  }

  void _updateYear(String newYear) {
    if (!mounted) return;
    setState(() => _year = newYear);
    
    // Capture provider synchronously
    final provider = context.read<SchoolDataProvider>();
    provider.updateClassTerm(
      widget.className,
      'Boarding',
      _term,
      newYear,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.className} - ${widget.section} Section'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Term and Year Selector
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
  child: DropdownButtonFormField<String>(
    // ignore: deprecated_member_use
    // ignore: deprecated_member_use
    value: _term,
    decoration: const InputDecoration(
      labelText: 'Term',
      border: OutlineInputBorder(),
      prefixIcon: Icon(Icons.calendar_today),
      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    ),
    items: ['ONE', 'TWO', 'THREE'].map((String value) {
      return DropdownMenuItem<String>(
        value: value,
        child: Text('Term $value'),
      );
    }).toList(),
    onChanged: (String? newValue) {
      if (newValue != null) {
        _updateTerm(newValue);
      }
    },
  ),
),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          decoration: const InputDecoration(
                            labelText: 'Year',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.date_range),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          controller: TextEditingController(text: _year),
                          onChanged: (value) {
                            _updateYear(value);
                          },
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Class Section Tabs
                Expanded(
                  child: DefaultTabController(
                    length: 2,
                    child: Column(
                      children: [
                        const TabBar(
                          labelColor: Colors.indigo,
                          unselectedLabelColor: Colors.grey,
                          indicatorColor: Colors.indigo,
                          tabs: [
                            Tab(
                              icon: Icon(Icons.hotel),
                              text: 'BOARDING',
                            ),
                            Tab(
                              icon: Icon(Icons.wb_sunny),
                              text: 'DAY',
                            ),
                          ],
                        ),
                        Expanded(
                          child: TabBarView(
                            children: [
                              // Boarding Section
                              StudentTableWidget(
                                students: _boardingStudents,
                                className: widget.className,
                                sectionType: 'Boarding',
                                term: _term,
                                year: _year,
                                onDataChanged: _loadData,
                              ),
                              // Day Section
                              StudentTableWidget(
                                students: _dayStudents,
                                className: widget.className,
                                sectionType: 'Day',
                                term: _term,
                                year: _year,
                                onDataChanged: _loadData,
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddStudentDialog,
        icon: const Icon(Icons.person_add),
        label: const Text('Add Student'),
        backgroundColor: Colors.indigo,
      ),
    );
  }

  void _showAddStudentDialog() {
    // Capture provider and other state BEFORE showing dialog
    final provider = context.read<SchoolDataProvider>();
    final className = widget.className;
    final term = _term;
    final year = _year;
    
    final nameController = TextEditingController();
    final contactController = TextEditingController();
    final feesController = TextEditingController();
    final arrearsController = TextEditingController();
    String sectionType = 'Boarding';

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (buildContext, setDialogState) => AlertDialog(
          title: const Text('Add New Student'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Section Type:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildSectionOption(
                        title: 'Boarding',
                        icon: Icons.hotel,
                        isSelected: sectionType == 'Boarding',
                        onTap: () {
                          setDialogState(() => sectionType = 'Boarding');
                        },
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildSectionOption(
                        title: 'Day',
                        icon: Icons.wb_sunny,
                        isSelected: sectionType == 'Day',
                        onTap: () {
                          setDialogState(() => sectionType = 'Day');
                        },
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
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
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isNotEmpty) {
                  try {
                    final student = Student(
                      ledgerNo: '',
                      parentContact: contactController.text,
                      fullName: nameController.text,
                      feesStructure: double.tryParse(feesController.text) ?? 0,
                      arrears: double.tryParse(arrearsController.text) ?? 0,
                    );
                    
                    // Use captured provider, not context.read()
                    await provider.addStudent(
                      student,
                      className,
                      sectionType,
                      term: term,
                      year: year,
                    );
                    
                    if (dialogContext.mounted) {
                      Navigator.pop(dialogContext);
                    }
                    
                    _loadData();
                    
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Student added successfully'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error adding student: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionOption({
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required Color color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.12) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? color : Colors.grey),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? color : Colors.grey,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}